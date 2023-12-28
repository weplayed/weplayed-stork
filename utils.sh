wp_install_docker() {
  set -e
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

wp_github_trigger_workflow() {
  local temp=$(getopt -o 'o:r:w:i:n:b:t' --long 'owner:,repo:,workflow:,input:,name:,ref:,tail' -- "$@")

  eval set -- "$temp"
  unset temp

  local name=
  local owner="${GH_TRIGGER_OWNER}"
  local repo="${GH_TRIGGER_REPO}"
  local workflow="${GH_TRIGGER_WORKFLOW}"


  declare -A input
  local token="${GH_TRIGGER_TOKEN}"
  local ref="${GH_TRIGGER_REF}"
  local tail="${GH_TRIGGER_TAIL}"

  while true; do
    case "$1" in
      '-t'|'--tail')
        tail=1
        shift
        continue
      ;;

      '-b'|'--ref')
        ref="${2}"
        shift 2
        continue
      ;;

      '-n'|'--name')
        name="${2}"
        shift 2
        continue
      ;;

      '-o'|'--owner')
        owner="${2}"
        shift 2
        continue
      ;;

      '-r'|'--repo')
        repo="${2}"
        shift 2
        continue
      ;;

      '-w'|'--workflow')
        workflow="${2}"
        shift 2
        continue
      ;;

      '-i'|'--input')
        readarray -d '=' -t p -s 2 < <(printf %s "${2}")
        input["${p[0]}"]="${p[1]}"

        shift 2

        continue
      ;;

      '--')
        shift
        break
      ;;

      *)
        wp_message ERROR "Unknown arg ${1}"
        return 1
      ;;
    esac
  done

  if [ -z "${owner}" ]
  then
    wp_message ERROR "-o/--owner/\$GH_TRIGGER_OWNER not set"
    return 1
  fi

  if [ -z "${repo}" ]
  then
    wp_message ERROR "-r/--repo/\$GH_TRIGGER_REPO not set"
    return 1
  fi

  if [ -z "${workflow}" ]
  then
    wp_message ERROR "-w/--workflow/\$GH_TRIGGER_WORKFLOW not set"
    return 1
  fi

  if [ -z "${token}" ]
  then
    wp_message ERROR "\$GH_TRIGGER_TOKEN not set"
    return 1
  fi

  if [ -z "${ref}" ]
  then
    wp_message ERROR "-b/--ref/\$GH_TRIGGER_REF not set"
    return 1
  fi

  inp=$(for i in "${!input[@]}"; do echo "$i"; echo "${input[$i]}"; done | jq -c -n -R 'reduce inputs as $i ({}; . + { ($i): (input) })')
  req='{"ref":"'${ref}'","inputs":'${inp}'}'

  path="https://api.github.com/repos/${owner}/${repo}"

  ret=$(wp_execute "echo '${req}' | curl -sLq \
    -X POST \
    -H 'Accept: application/vnd.github+json' \
    -H 'Authorization: Bearer ${token}' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    '${path}/actions/workflows/${workflow}/dispatches' \
    -d @-")

  code=$?
  if [ ${code} -ne 0 ]
  then
    wp_message ERROR "Curl returned bad status"
    return 1
  fi

  if [ -z "${tail}" ]
  then
    return $code
  fi

  created=$(date --iso-8601=seconds)

  timeout=30
  sleep=2
  start=$(date +%s)
  workflow_id=null

  now=${start}
  while [ "${workflow_id}" == "null" ] && (( ${now} - ${start} < ${timeout} ))
  do
    now=$(date +%s)
    ret=$(wp_execute "curl -sLq
      --get
      -H 'Accept: application/vnd.github+json'
      -H 'Authorization: Bearer ${token}'
      -H 'X-GitHub-Api-Version: 2022-11-28'
      --data-urlencode 'event=workflow_dispatch'
      --data-urlencode 'created=>${created}'
      ${path}/actions/runs")

    if [ $? -ne 0 ]
    then
      wp_message ERROR "Curl returned bad status"
      return 1
    fi

    if [ -n "${name}" ]
    then
      workflow_id=$(wp_execute "echo '${ret}' | jq 'last(.workflow_runs[] | select(.display_title == \"${name}\") | .id)'")
    else
      workflow_id=$(wp_execute "echo '${ret}' | jq 'last(.workflow_runs[]) | .id'")
    fi

    if [ "${workflow_id}" == "null" ]
    then
      wp_message INFO "Did not get workflow ID yet, sleep for ${sleep} seconds"
      sleep ${sleep}
    fi
  done

  if [ "${workflow_id}" == "null" ]
  then
    wp_message ERROR "Can't get workflow ID for ${timeout} seconds"
    return 1
  fi

  wp_message INFO "workflow_id=${workflow_id}"
  wp_message INFO "Track workflow run at: https://github.com/${owner}/${repo}/actions/runs/${workflow_id}"

  timeout=1800
  status="in_progress"
  conclusion=
  start=$(date +%s)
  now=${start}
  sleep=5

  while [ "${status}" != "completed" ] || (( ${now} - ${start} > ${timeout} ))
  do
    ret=$(wp_execute "curl -sL
      -H 'Accept: application/vnd.github+json'
      -H 'Authorization: Bearer ${token}'
      -H 'X-GitHub-Api-Version: 2022-11-28'
      ${path}/actions/runs/${workflow_id}")

    if [ -z "${DEBUG}" ]
    then
      _st=$(echo "$ret" | jq '.status,.conclusion' | sed -e 's|"||g')
      readarray -t st < <(printf %s "${_st}")
      status=${st[0]}
      conclusion=${st[1]}
    fi

    msg="status=${status} conclusion=${conclusion}"

    if [ "${status}" != "completed" ]
    then
      msg="${msg} wait=${sleep}"
      wp_message INFO "${msg}"
      sleep ${sleep}
    else
      wp_message INFO "${msg}"
    fi
  done

  wp_message INFO "Check workflow run at: https://github.com/${owner}/${repo}/actions/runs/${workflow_id}"

  if (( ${now} - ${start} > ${timeout} ))
  then
    wp_message ERROR "Task did not finish for ${timeout} seconds, giving up"
    return 1
  fi

  if [ "${conclusion}" == "failure" ] || [ "${conclusion}" == "timed_out" ] || [ "${conclusion}" == "cancelled" ]
  then
    return 1
  fi

  return 0
}
