wp_docker_login() {
  if [ -n "${AWS_PROFILE}" ]
  then
    eval $(${AWS} --profile ${AWS_PROFILE} ecr get-login --no-include-email --region ${AWS_DEFAULT_REGION})
  else
    eval $(${AWS} ecr get-login --no-include-email --region ${AWS_DEFAULT_REGION})
  fi
}

wp_docker_build() {
  name=${DOCKER_PREFIX}
  registry=${DOCKER_REGISTRY}
  branch=${TRAVIS_BRANCH}

  temp=$(getopt -o 'cb:r:n:t:' --long 'cache,branch:,registry:,name:,target:' -- "$@")

  eval set -- "$temp"
  unset temp

  target=
  cache=

  while true; do
    case "$1" in
      '-c'|'--cache')
        cache=yes
        shift
        continue
      ;;

      '-b'|'--branch')
        branch=${2}
        shift 2
        continue
      ;;

      '-r'|'--registry')
        registry=${2}
        shift 2
        continue
      ;;

      '-n'|'--name')
        name=${2}
        shift 2
        continue
      ;;

      '-t'|'--target')
        target=${2}
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

  if [ -z "${name}" ]
  then
    wp_message ERROR "no \$DOCKER_PREFIX neither --name passed"
    return 1
  fi

  if [ -n "${cache}" ] && [ -z "${registry}" ]
  then
    wp_message ERROR "--cache specified but no \$DOCKER_REGISTRY neither --registry passed"
    return 1
  fi

  if [ -z "${branch}" ]
  then
    # always use develop if target branch not in the list
    wp_message ERROR "no \$TRAVIS_BRANCH neither --branch passed"
    return 1
  fi

  cmd="${DOCKER} build -t ${name}"

  if [ -n "${cache}" ]
  then
    cache="${registry}/${name}:develop-latest"
    wp_message INFO "attempt to fetch image ${cache}"
    ${DOCKER} pull "${cache}"

    if [ "$?" -eq 0 ]
    then
      wp_message INFO "build ${name} using ${cache}"
      cmd="${cmd} --cache-from ${cache}"
    else
      wp_message INFO "build ${name} NOT using cache"
    fi

  else
    wp_message INFO "build ${name}"
  fi

  if [ -n "${target}" ]
  then
    cmd="${cmd} --target ${target}"
  fi

  cmd="${cmd} ."
  ${cmd}

  if [ $? -eq 0 ]
  then
    wp_message INFO "build done"
  else
    wp_message ERROR "build failed"
  fi

  return $?
}

wp_docker_push() {
  name=${DOCKER_PREFIX}
  registry=${DOCKER_REGISTRY}
  branch=${TRAVIS_BRANCH}

  temp=$(getopt -o 'fb:r:n:' --long 'force,branch:,registry:,name:' -- "$@")

  eval set -- "$temp"
  unset temp

  force=
  target=
  cache=

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

      '-r'|'--registry')
        registry=${2}
        shift 2
        continue
      ;;

      '-n'|'--name')
        name=${2}
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

  if [ -z "${registry}" ]
  then
    wp_message ERROR "no \$DOCKER_REGISTRY neither --registry passed"
    return 1
  fi

  if [ -z "${name}" ]
  then
    wp_message ERROR "no \$DOCKER_PREFIX neither --name passed"
    return 1
  fi

  if [ -z "${branch}" ]
  then
    # always use develop if target branch not in the list
    wp_message ERROR "no \$TRAVIS_BRANCH neither --branch passed"
    return 1
  fi

  if [ -n "${TRAVIS_PULL_REQUEST}" ] && [ "${TRAVIS_PULL_REQUEST}" != false ] && [ -z "${force}" ]
  then
	  wp_message WARNING "push skipped because of PR"
	  return 0
  fi

  if [[ "${TRAVIS_TAG}" != *"docker-build"* ]] && [[ " ${BRANCHES} " != *" ${branch} "* ]] && [ -z "${force}" ]
  then
    wp_message WARNING "push skipped because of branch conditions"
    return 0
  fi

  tags="latest travis-${TRAVIS_BUILD_NUMBER}"

  if [[ " ${BRANCHES} " = *" ${branch} "*  ]]
  then
	  tags="${tags} ${branch}-${TRAVIS_COMMIT} ${branch}-latest"
  fi

  wp_message INFO "tags to push: (${tags})"

  for tag in ${tags}
  do
    wp_message INFO "tagging ${tag}"
    remote=${registry}/${name}:${tag}
    ${DOCKER} tag ${name}:latest ${remote}
    ${DOCKER} push ${remote}
  done

  wp_message INFO "push done"

  return $?
}

wp_docker_run() {
  name=${DOCKER_PREFIX}
  branch=${TRAVIS_BRANCH}

  temp=$(getopt -o 'n:' --long 'name:' -- "$@")

  eval set -- "$temp"
  unset temp

  force=
  target=
  cache=

  while true; do
    case "$1" in
      '-n'|'--name')
        name=${2}
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

  if [ -z "${name}" ]
  then
    wp_message ERROR "no \$DOCKER_PREFIX neither --name passed"
    return 1
  fi

  ${DOCKER} run "${name}" $@

  return $?
}
