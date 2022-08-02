wp_ecs_deploy() {
  temp=$(getopt -o 'fb:c:s:' --long 'force,branch:,cluster:,service:' -- "$@")

  eval set -- "$temp"
  unset temp

  cluster="testcluster"
  service=
  force=
  branch=develop

  while true; do
    case "$1" in
      '-f'|'--force')
        force=yes
        shift
        continue
      ;;

      '-b'|'--branch')
        branch=${2}
        shift 2
        continue
      ;;

      '-s'|'--service')
        service=${2}
        shift 2
        continue
      ;;

      '-c'|'--cluster')
        cluster=${2}
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

  if [ -z "${service}" ]
  then
    wp_message ERROR "no --service passed"
    return 1
  fi

  if [ -n "${TRAVIS_PULL_REQUEST}" ] && [ "${TRAVIS_PULL_REQUEST}" != false ] && [ -z "${force}" ]
  then
	  wp_message WARNING "deploy skipped because of PR"
	  return 0
  fi

  if [ -n "${branch}" ] && [ "${TRAVIS_BRANCH}" != "${branch}" ]
  then
    wp_message INFO "skip because of branch condition"
    return 0
  elif [[ "${TRAVIS_TAG}" != *"docker-build"* ]] && [[ " ${BRANCHES} " != *" ${branch} "* ]] && [ -z "${force}" ]
  then
    wp_message WARNING "deploy skipped because of branch conditions"
    return 0
  fi

  wp_message INFO "deploy ${service} to ${cluster}"

  aws ecs update-service \
    --service "${service}" \
    --cluster "${cluster}" \
    --force-new-deployment \
    --region ${AWS_DEFAULT_REGION}

}

wp_s3_deploy() {
  if [ "${TRAVIS_EVENT_TYPE}" = "pull_request" ]
  then
    wp_message INFO "skip pull request"
    return 0
  fi

  temp=$(getopt -o 'pt:b:l:s:d:' --long 'public,tag:,branch:,live:,staging:,demo:' -- "$@")

  eval set -- "$temp"
  unset temp

  tag="${TRAVIS_TAG}"
  branch="${TRAVIS_BRANCH}"

  public=
  live=
  staging=
  demo=

  while true; do
    case "$1" in
      '-t'|'--tag')
        tag="${2}"
        shift 2
        continue
      ;;

      '-b'|'--branch')
        branch="${2}"
        shift 2
        continue
      ;;

      '-p'|'--public')
        public="--acl public-read"
        shift
        continue
      ;;

      '-l'|'--live')
        live="${2}"
        shift 2
        continue
      ;;

      '-s'|'--staging')
        staging="${2}"
        shift 2
        continue
      ;;

      '-d'|'--demo')
        demo="${2}"
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

  if [ -z "${branch}" ] && [ -z "${tag}" ]
  then
    # always use develop if target branch not in the list
    wp_message ERROR "no '\$TRAVIS_BRANCH', '\$TRAVIS_TAG', '--branch' neither '--tag' passed"
    return 1
  fi

  src="${1}"

  if [ -z "${src}" ]
  then
    wp_message ERROR "source path not provided"
    return 1
  fi

  dest=

  if [ -n "${live}" ] && [ -n "${tag}" ]
  then
    if [[ "${tag}" =~ ^v[0-9]+(\.[0-9]+)*$ ]]
    then
      dest="${live}"
    else
      wp_message INFO "skipped because of tag conditions"
      return 0
    fi
  elif [ "${branch}" = "develop" ] && [ -n "${staging}" ]
  then
    dest="${staging}"
  elif [ -n "${demo}" ]
  then
    if [[ "${branch}" = feature/* ]] || [[ "${branch}" = hotfix/* ]] || [[ "${branch}" = bugifx/* ]]
    then
      dest="${demo}"
    fi
  fi

  if [ -n "${dest}" ]
  then

    if [[ "${dest}" = *:tag:* ]]
    then
      if [ -z "${tag}" ]
      then
        wp_message ERROR ":tag: substitution requested but no --tag neither \$TRAVIS_TAG specified"
        return 1
      fi

      dest=${dest//:tag:/$tag}
    fi

    if [[ "${dest}" = *":tagmajor:"* ]]
    then
      if [ -z "${tag}" ]
      then
        wp_message ERROR ":tagmajor: substitution requested but no --tag neither \$TRAVIS_TAG specified"
        return 1
      fi

      tagmajor=$(echo ${tag} | sed -e 's|^\([^.]\{1,\}\).*$|\1|')
      dest=${dest//:tagmajor:/$tagmajor}
    fi

    if [[ "${dest}" = *:branch:* ]]
    then
      if [ -z "${branch}" ]
      then
        wp_message ERROR ":branch: substitution requested but no --branch neither \$TRAVIS_BRANCH specified"
        return 1
      fi

      dest=${dest//:branch:/$branch}
    fi

    for srcdst in $@; do
      IFS=',' read -r -a a <<< "${srcdst},dummy"
      unset 'a[${#a[@]}-1]'

      if [ "${#a[@]}" = "1" ]
      then
        a[1]="${a[0]}"
      fi

      if [ -n "${a[1]}" ]
      then
        a[1]="/${a[1]}"
      fi

      command="aws"

      if [ -n "${AWS_DEFAULT_REGION}" ]
      then
        command="${command} --region ${AWS_DEFAULT_REGION}"
      fi

      command="${command} s3 cp ${public} --recursive ${a[0]:-.} ${dest}${a[1]}"

      eval $command
    done
  else
    wp_message INFO "skipped because of branch conditions"
  fi
}
