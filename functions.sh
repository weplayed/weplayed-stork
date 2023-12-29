wp_message() {
  if [ "$1" = "INFO" ]
  then
    echo -en "\\e[32m$1:\\e[0m" >&2
  elif [ "$1" = "WARNING" ]
  then
    echo -en "\\e[1;33m$1:\\e[0m" >&2
  elif [ "$1" = "ERROR" ]
  then
    echo -en "\\e[1;31m$1:\\e[0m" >&2
  fi
  echo " ${@:2}" >&2
}

wp_execute() {
  if [ -n "${DEBUG}" ]
  then
    echo $@
  else
    eval $@
  fi
}

wp_is_tag_build() {
  local tag="${STORK_TAG}"

  local temp=$(getopt -o 't:' --long 'tag:' -- "$@")

  eval set -- "$temp"
  unset temp

  while true; do
    case "$1" in
      '-t'|'--tag')
        tag=${2}
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

  if [ -n "${tag}" ] && [[ "${tag}" =~ ^v[0-9]+(\.[0-9]+)*(-.+)?$ ]]
  then
    echo "${tag}"
  fi
}

wp_is_staging_build() {
  local branch="${STORK_BRANCH}"
  local tag="${STORK_TAG}"

  local temp=$(getopt -o 'b:t:' --long 'branch:,tag:' -- "$@")

  eval set -- "$temp"
  unset temp

  while true; do
    case "$1" in
      '-b'|'--branch')
        branch=${2}
        shift 2
        continue
      ;;

      '-t'|'--tag')
        tag=${2}
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

  if [ -z "${tag}" ] && [ "${branch}" = "develop" ]
  then
    echo "${branch}"
  fi

}

wp_is_demo_build() {
  local branch="${STORK_BRANCH}"
  local tag="${STORK_TAG}"

  local temp=$(getopt -o 'b:t:' --long 'branch:,tag:' -- "$@")

  eval set -- "$temp"
  unset temp

  while true; do
    case "$1" in
      '-b'|'--branch')
        branch=${2}
        shift 2
        continue
      ;;

      '-t'|'--tag')
        tag=${2}
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

  if [ -z "${tag}" ] && [[ "${branch}" = feature/* || "${branch}" = hotfix/* || "${branch}" = bugfix/* || "${branch}" = support/* ]]
  then
    echo "${branch}"
  fi
}

wp_set_weplayed_env() {
  local branch="${STORK_BRANCH}"
  local tag="${STORK_TAG}"
  local demo=
  local live=
  local staging=

  local temp=$(getopt -o 'b:t:d:l:s:' --long 'branch:,tag:,demo:,live:,staging:' -- "$@")

  eval set -- "$temp"
  unset temp

  while true; do
    case "$1" in
      '-b'|'--branch')
        branch=${2}
        shift 2
        continue
      ;;

      '-t'|'--tag')
        tag=${2}
        shift 2
        continue
      ;;

      '-d'|'--demo')
        demo=${2}
        shift 2
        continue
      ;;

      '-l'|'--live')
        live=${2}
        shift 2
        continue
      ;;

      '-s'|'--staging')
        staging=${2}
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
    wp_message ERROR "no '\$STORK_BRANCH', '\$STORK_TAG', '--branch' neither '--tag' passed"
    return 1
  fi

  local env=

  if [ -n "$(wp_is_tag_build -t "${tag}")" ]
  then
    env="${live}"
  elif [ -n "$(wp_is_staging_build -t "${tag}" -b "${branch}")" ]
  then
    env="${staging}"
  elif [ -n "$(wp_is_demo_build -t "${tag}" -b "${branch}")" ]
  then
    env="${demo}"
  fi

  export WEPLAYED_ENV="${env}"

  wp_message INFO "WEPLAYED_ENV=${WEPLAYED_ENV}"
}


wp_run_command_for() {
  if [ "${STORK_EVENT_TYPE}" = "pull_request" ]
  then
    wp_message INFO "skip pull request"
    return 0
  fi

  local temp=$(getopt -o 't:b:lsd' --long 'tag:,branch:,live,staging,demo' -- "$@")

  eval set -- "$temp"
  unset temp

  local tag="${STORK_TAG}"
  local branch="${STORK_BRANCH}"

  local live=
  local staging=
  local demo=

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

      '-l'|'--live')
        live=1
        shift
        continue
      ;;

      '-s'|'--staging')
        staging=1
        shift
        continue
      ;;

      '-d'|'--demo')
        demo=1
        shift
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
    wp_message ERROR "no -b/\$STORK_BRANCH neither -t/\$STORK_TAG passed"
    return 1
  fi

  local lsd="${live}${staging}${demo}"

  if [ "${#lsd}" != 1 ]
  then
    wp_message ERROR "only one -l/-s/-d must be specified"
    return 1
  fi

  if [ "${#@}" == "0" ]
  then
    wp_message ERROR "no command specified"
    return 1
  fi

  dest="${@}"

  if [[ "${@}" = *:tag:* ]] && [ -z "${tag}" ]
  then
    wp_message ERROR ":tag: substitution requested but no --tag neither \$STORK_TAG specified"
    return 1
  fi

  if [[ "${dest}" = *":tagmajor:"* ]] && [ -z "${tag}" ]
  then
    wp_message ERROR ":tagmajor: substitution requested but no --tag neither \$STORK_TAG specified"
    return 1
  fi

  if [[ "${dest}" = *:branch:* ]]
  then
    if [ -z "${branch}" ]
    then
      wp_message ERROR ":branch: substitution requested but no --branch neither \$STORK_BRANCH specified"
      return 1
    fi
  fi

  if [ -n "$(wp_is_tag_build -t "${tag}")" ] && [ -n "${live}" ]
  then
    dest=${dest//:tag:/$tag}
    local tagmajor=$(echo ${tag} | sed -e 's|^\([^.]\{1,\}\).*$|\1|')
    dest=${dest//:tagmajor:/$tagmajor}
    exec ${dest}
  elif [ -n "$(wp_is_staging_build -t "${tag}" -b "${branch}")" ] && [ -n "${staging}" ]
  then
    dest=${dest//:branch:/$branch}
    exec ${dest}
  elif [ -n "$(wp_is_demo_build -t "${tag} -b ${branch}")" ] && [ -n "${demo}" ]
  then
    exec ${dest}
  else
    wp_message INFO "skipped because of tag/branch conditions"
  fi
}