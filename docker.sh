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
  local temp=$(getopt -o 'r:p:e:' --long 'region:,profile:,registry:' -- "$@")

  eval set -- "$temp"
  unset temp

  local region="${AWS_DEFAULT_REGION:-us-east-1}"
  local registry=
  local profile=

  while true; do
    case "$1" in
      '-r'|'--region')
        region="${2}"
        shift 2
        continue
      ;;

      '-p'|'--profile')
        profile="${2}"
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

  cmd=${AWS}

  if [ -n "${profile}" ]
  then
    cmd="${cmd} --profile ${profile}"
  fi

  cmd="${cmd} ecr get-login --no-include-email --region ${region} ${@}"

  ret=$(wp_execute ${cmd})

  if [ -n "${DEBUG}" ]
  then
    echo $ret
  else
    eval $ret
  fi

  return $?
}

wp_docker_build() {
  local temp=$(getopt -o 'c:i:d:x:' --long 'cache:,image:,dockerfile:,context:' -- "$@")

  eval set -- "$temp"
  unset temp

  local image=
  local cache=
  local context=.
  local dockerfile=

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

      '-d'|'--dockerfile')
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
    wp_message ERROR "no --image passed"
    return 1
  fi

  local cmd="${DOCKER} build -t ${image}"

  if [ -n "${cache}" ]
  then
    if ! wp_execute ${DOCKER} image inspect ${image} >/dev/null 2>&1
    then
      wp_message INFO "attempt to pull image ${image}"
      if ! wp_execute ${DOCKER} pull ${image}
      then
        wp_message WARN "pulling cache image ended with error, skipping cache"
        cache=
      fi
    fi

    if [ -n "${cache}" ]
    then
      wp_message INFO "build ${image} using ${cache}"
      cmd="${cmd} --cache-from ${cache}"
    fi

  else
    wp_message INFO "build ${name}"
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

  local image=
  local name=${DOCKER_PREFIX}
  local registry=${DOCKER_REGISTRY}

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
    wp_message ERROR "no \$DOCKER_REGISTRY neither --registry passed"
    return 1
  fi

  if [ -z "${name}" ]
  then
    wp_message ERROR "no \$DOCKER_PREFIX neither --name passed"
    return 1
  fi

  if [ -z "${image}" ]
  then
    # always use develop if target branch not in the list
    wp_message ERROR "no --image passed"
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
  local name=${DOCKER_PREFIX}
  local volume=${VOLUME_MOUNT}

  local mount=
  local vars=

  local temp=$(getopt -o 'n:m:e:v:' --long 'name:mount:env:volume:' -- "$@")

  eval set -- "$temp"
  unset temp

  while true; do
    case "$1" in
      '-n'|'--name')
        name="${2}"
        shift 2
        continue
      ;;

      '-m'|'--mount')
        mount="${mount} -v ${2}"
        shift 2
        continue
      ;;

      '-e'|'--env')
        vars="${vars} -e ${2}"
        shift 2
        continue
      ;;

      '-v'|'--volume')
        volume="${2}"
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

  if [ -n "${volume}" ]
  then
    mount="${mount} -v $(pwd):${volume}"
  fi

  wp_execute ${DOCKER} run --rm ${mount} ${vars} -t ${name} $@

  return $?
}
