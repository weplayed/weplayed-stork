wp_ecs_deploy() {
  temp=$(getopt -o 'fc:s:' --long 'force,cluster:,service:' -- "$@")

  eval set -- "$temp"
  unset temp

  cluster="testcluster"
  service=
  force=

  while true; do
    case "$1" in
      '-f'|'--force')
        force=yes
        shift
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

  if [[ "${TRAVIS_TAG}" != *"docker-build"* ]] && [[ " ${BRANCHES} " != *" ${branch} "* ]] && [ -z "${force}" ]
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