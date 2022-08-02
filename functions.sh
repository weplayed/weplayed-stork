wp_message() {
  if [ "$1" = "INFO" ]
  then
    echo -en "\\e[32m$1:\\e[0m"
  elif [ "$1" = "WARNING" ]
  then
    echo -en "\\e[1;33m$1:\\e[0m"
  elif [ "$1" = "ERROR" ]
  then
    echo -en "\\e[1;31m$1:\\e[0m"
  fi
  echo " ${@:2}"
}


wp_set_weplayed_env() {
  branch="${TRAVIS_BRANCH}"
  tag="${TRAVIS_TAG}"
  demo=
  live=
  staging=

  temp=$(getopt -o 'b:t:d:l:s:' --long 'branch:,tag:,demo:,live:,staging:' -- "$@")

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

  env=

  if [ -n "${live}" ] && [ -n "${tag}" ]
  then
    if [[ "${tag}" =~ ^v[0-9]+(\.[0-9]+)*$ ]]
    then
      env="${live}"
    fi
  elif [ "${branch}" = "develop" ] && [ -n "${staging}" ]
  then
    env="${staging}"
  elif [ -n "${demo}" ]
  then
    if [[ "${branch}" = feature/* ]] || [[ "${branch}" = hotfix/* ]] || [[ "${branch}" = bugifx/* ]]
    then
      env="${demo}"
    fi
  fi

  export WEPLAYED_ENV="${env}"

  wp_message INFO "WEPLAYED_ENV=${WEPLAYED_ENV}"
}
