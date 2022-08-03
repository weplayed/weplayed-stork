wp_message() {
  if [ "$1" = "INFO" ]
  then
    echo -en "\\e[32m$1:\\e[0m" 1>&2
  elif [ "$1" = "WARNING" ]
  then
    echo -en "\\e[1;33m$1:\\e[0m" 1>&2
  elif [ "$1" = "ERROR" ]
  then
    echo -en "\\e[1;31m$1:\\e[0m" 1>&2
  fi
  echo " ${@:2}" 1>&2
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
  local tag="${TRAVIS_TAG}"

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
  local branch="${TRAVIS_BRANCH}"
  local tag="${TRAVIS_TAG}"

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
  local branch="${TRAVIS_BRANCH}"
  local tag="${TRAVIS_TAG}"

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
  local branch="${TRAVIS_BRANCH}"
  local tag="${TRAVIS_TAG}"
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
    wp_message ERROR "no '\$TRAVIS_BRANCH', '\$TRAVIS_TAG', '--branch' neither '--tag' passed"
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
