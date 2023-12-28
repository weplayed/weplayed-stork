wp_pack_image() {
  local temp=$(getopt -o 'i:p:' --long 'image:,path:' -- "$@")

  eval set -- "$temp"
  unset temp

  local image=
  local path=

  while true; do
    case "$1" in
      '-i'|'--image')
        image="${2}"
        shift 2
        continue
      ;;

      '-p'|'--path')
        path="${2}"
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

  if [ -z "${image}" ] || [ -z "${path}" ]
  then
    wp_message ERROR "-i or -p or both are not provided"
    return 1
  fi

  wp_execute "${DOCKER} save "${image}" | gzip -2 > "${path}""
}

wp_unpack_image() {
  local temp=$(getopt -o 'p:' --long 'path:' -- "$@")

  eval set -- "$temp"
  unset temp

  local path=

  while true; do
    case "$1" in
      '-p'|'--path')
        path="${2}"
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

  if [ -z "${path}" ]
  then
    wp_message ERROR "-p is not provided"
    return 1
  fi

  wp_execute "zcat "${path}" | ${DOCKER} load"
}

wp_store_cache() {
  local temp=$(getopt -o 'p:' --long 'path:' -- "$@")

  eval set -- "$temp"
  unset temp

  local path="${HOME}/docker"

  while true; do
    case "$1" in
      '-p'|'--path')
        path="${2}"
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

  wp_execute mkdir -p "${path}"
  wp_execute rm -rf "${path}/*"

  for image in ${@}; do
    wp_pack_image -i "${image}" -p "${path}/$(echo $image | sed -e 's|/|@|g').tar.gz";
  done

  wp_message INFO "Cache content:"
  wp_execute ls -1 "${path}"
}

wp_restore_cache() {
  local temp=$(getopt -o 'p:' --long 'path:' -- "$@")

  eval set -- "$temp"
  unset temp

  local path="${HOME}/docker"

  while true; do
    case "$1" in
      '-p'|'--path')
        path="${2}"
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

  if [ -z "${DEBUG}" ] && [  ! -d "$path" ]; then
    wp_message INFO "Cache path does not exist or not a directory, skipping"
    return 0
  fi

  wp_message INFO "Cache content:"
  wp_execute ls -1 "${path}"

  wp_execute "export -f wp_unpack_image wp_message wp_execute; export DOCKER; ls "${path}/*.tar.gz" | xargs -I {file} -n 1 -- /bin/bash -c 'wp_unpack_image -p {file}'"
}

wp_docker_login() {
  local temp=$(getopt -o 'r:' --long 'registry:' -- "$@")

  eval set -- "$temp"
  unset temp

  local registry=${STORK_DOCKER_REGISTRY}

  while true; do
    case "$1" in
      '-r'|'--registry')
        registry="${2}"
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
    wp_message ERROR "no -r/\$STORK_DOCKER_REGISTRY provided"
    return 1
  fi

  wp_execute "${DOCKER} login --username AWS --password-stdin $registry"

  return $?
}

wp_docker_build() {
  local temp=$(getopt -o 'c:i:f:x:' --long 'cache:,image:,dockerfile:,context:' -- "$@")

  eval set -- "$temp"
  unset temp

  local image="${STORK_DOCKER_IMAGE}"
  local cache="${STORK_DOCKER_CACHE}"
  local context="${STORK_DOCKER_CONTEXT}"
  local dockerfile="${STORK_DOCKER_FILE}"

  while true; do
    case "$1" in
      '-c'|'--cache')
        cache="${2}"
        shift 2
        continue
      ;;

      '-i'|'--image')
        image="${2}"
        shift 2
        continue
      ;;

      '-f'|'--dockerfile')
        dockerfile="${2}"
        shift 2
        continue
      ;;

      '-x'|'--context')
        context="${2}"
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

  if [ -z "${image}" ]
  then
    wp_message ERROR "no -i/\$STORK_DOCKER_IMAGE passed"
    return 1
  fi

  if [ -z "${dockerfile}" ]
  then
    wp_message ERROR "no -f/\$STORK_DOCKER_FILE passed"
    return 1
  fi

  if [ -z "${context}" ]
  then
    wp_message ERROR "no -x/\$STORK_DOCKER_CONTEXT passed"
    return 1
  fi

  local cmd="${DOCKER} build -t ${image}"

  if [ -n "${cache}" ]
  then
    cmd="${cmd} --cache-from ${cache}"
  fi

  if [ -n "${dockerfile}" ]
  then
    cmd="${cmd} -f "${dockerfile}""
  fi

  cmd="${cmd} ${@} "${context}""

  if wp_execute ${cmd}
  then
    wp_message INFO "build done"
  else
    wp_message ERROR "build failed"
  fi

  return $?
}

wp_docker_push() {
  local temp=$(getopt -o 'i:n:r:' --long 'image:,name:,registry' -- "$@")

  eval set -- "$temp"
  unset temp

  local image=${STORK_DOCKER_IMAGE}
  local name=${STORK_DOCKER_PREFIX}
  local registry=${STORK_DOCKER_REGISTRY}

  while true; do
    case "$1" in
      '-i'|'--image')
        image=${2}
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
    wp_message ERROR "no -r/\$STORK_DOCKER_REGISTRY passed"
    return 1
  fi

  if [ -z "${name}" ]
  then
    wp_message ERROR "no -n/\$STORK_DOCKER_PREFIX passed"
    return 1
  fi

  if [ -z "${image}" ]
  then
    # always use develop if target branch not in the list
    wp_message ERROR "no -i/\$STORK_DOCKER_IMAGE passed"
    return 1
  fi

  echo $@

  if [ "${#@}" -eq 0 ]
  then
    wp_message INFO "No tags provided, skip push"
    return 0
  fi

  for tag in ${@}
  do
    remote=${registry}/${name}:${tag}
    wp_message INFO "tagging ${image} with ${remote}"
    wp_execute ${DOCKER} tag ${image} ${remote}
    wp_execute ${DOCKER} push ${remote}
  done

  wp_message INFO "push done"

  return $?
}

wp_docker_run() {
  local temp=$(getopt -o 'i:c:' --long 'image:,command:' -- "$@")

  eval set -- "$temp"
  unset temp

  local image=${STORK_DOCKER_IMAGE}
  local command=

  while true; do
    case "$1" in
      '-i'|'--image')
        image="${2}"
        shift 2
        continue
      ;;

      '-c'|'--command')
        command="${2}"
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

  if [ -z "${image}" ]
  then
    wp_message ERROR "no -i/\$STORK_DOCKER_IMAGE passed"
    return 1
  fi

  wp_execute ${DOCKER} run --rm ${@} ${image} ${command}

  return $?
}

wp_generate_docker_tags() {
  if [ "${STORK_PULL_REQUEST}" != "false" ]
  then
	  wp_message WARNING "push skipped because of PR"
	  return 0
  fi

  local temp=$(getopt -o 'lst:b:' --long 'live,staging,tag:,branch:' -- "$@")

  eval set -- "$temp"
  unset temp

  local tag="${STORK_TAG}"
  local branch="${STORK_BRANCH}"

  local live=
  local staging=

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

  _live=$(wp_is_tag_build -t "${STORK_TAG}")
  _staging=$(wp_is_staging_build -t "${STORK_TAG}" -b "${STORK_BRANCH}")

  tags=

  if [ -n "${staging}" ] && [ -n "${_staging}" ]
  then
    tags="${tags} develop-latest latest"
  elif [ -n "${live}" ] && [ -n "${_live}" ]
  then
    tags="${tags} master-latest ${_live}"
  fi

  if [ -n "${tags}" ]
  then
    tags="sha-${STORK_COMMIT}${tags}"
  fi

  echo -n ${tags}
}
