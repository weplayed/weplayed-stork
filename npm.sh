wp_npm_test() {
  if [ -z "$NPM_PACKAGE_NAME" ] || [ -z "$NPM_PACKAGE_VERSION" ]; then
    wp_message ERROR "\$NPM_PACKAGE_NAME or \$NPM_PACKAGE_VERSION does present, did you run wp_npm_prepare?"
    return 1
  fi
}

wp_npm_prepare() {
  local file="package.json"

  if [ ! -f "$file" ]; then
    wp_message ERROR "$file does not exist in current folder"
    return 1
  fi

  local temp=$(getopt -o 't:' --long 'tag:' -- "$@")

  eval set -- "$temp"
  unset temp

  local tag="${TRAVIS_TAG}"

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

  if [ -z "$tag" ]; then
    wp_message ERROR "No -t nor --tag provided, or \$TRAVIS_TAG is not set"
    return 1
  fi

  local test=$(echo '{"test":"passed"}' | jq .test)

  if [ $? -ne 0 ] || [ "x${test}" != xpassed ]; then
    jq_source='https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64'
    jq='/usr/bin/jq'
    curl -qL -o "$jq" "$jq_source"
    chmod 755 "$jq"
  fi

  NPM_PACKAGE_NAME=$(cat $file | $jq -r .name)

  if [ -z "x$NPM_PACKAGE_NAME" ]; then
    wp_message ERROR "$file does not contain name property or set to empty string"
    return 1
  fi

  NPM_PACKAGE_VERSION=$(cat $file | $jq -r .version)

  if [ -z "x$NPM_PACKAGE_VERSION" ]; then
    wp_message ERROR "$file does not contain version property or set to empty string"
    return 1
  fi

  if [ "$tag" != "v${NPM_PACKAGE_VERSION}" ]; then
    wp_message ERROR "${tag} != v${NPM_PACKAGE_VERSION}, please fix package.json version field"
    return 1
  fi

  export NPM_PACKAGE_NAME
  export NPM_PACKAGE_VERSION
}

wp_npm_deploy() {
  wp_npm_test
  [ $? -ne 0 ] && return $?


  local temp=$(getopt -o 'f:t:' --long 'folder:,target:' -- "$@")

  eval set -- "$temp"
  unset temp

  local folder=out
  local target=

  while true; do
    case "$1" in
      '-f'|'--folder')
        folder=${2}
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

  if [ -z "$target" ]; then
    wp_message ERROR "No -t nor --target provided"
    return 1
  fi

  local fname="${NPM_PACKAGE_NAME}-${NPM_PACKAGE_VERSION}.tgz"
  wp_s3_deploy -p -l "$target" "${folder}/${fname},${NPM_PACKAGE_NAME}/${fname}"
}
