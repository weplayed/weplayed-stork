bats_load_library "bats-support"
bats_load_library "bats-assert"

create_package_json() {
  local name="weplayed-test"
  local version="1.1.12"

  if [ "$#" -eq 2 ]; then
    name="${1}"
    version="${2}"
  fi

  echo "{\"name\": \"${name}\", \"version\": \"${version}\"}" > package.json
}

setup() {
  aws() {
    echo "aws" $@
  }

  TRAVIS=true . load.sh
}

teardown() {
  rm -f package.json
}

# wp_npm_prepare

@test "wp_npm_prepare no package.json" {
  run wp_npm_prepare
  assert_failure
  assert_output --partial "does not exist"
}

@test "wp_npm_prepare no name in package.json" {
  create_package_json "" "1.2.2"
  run wp_npm_prepare -t v1.2.2
  assert_failure
  assert_output --partial "does not contain name property"
}

@test "wp_npm_prepare no version in package.json" {
  create_package_json "test" ""
  run wp_npm_prepare -t v1.2.2
  assert_failure
  assert_output --partial "does not contain version property"
}


@test "wp_npm_prepare tag is different" {
  create_package_json
  STORK_TAG=v1.1.1
  run wp_npm_prepare
  assert_failure
  assert_output --partial "please fix package.json version"
}

@test "wp_npm_prepare success publish" {
  create_package_json
  STORK_TAG=v1.1.12
  # no run!
  wp_npm_prepare
  assert_success
  assert [ "$NPM_PACKAGE_NAME" == "weplayed-test" ]
  assert [ "$NPM_PACKAGE_VERSION" == "1.1.12" ]
}

# wp_npm_deploy

@test "wp_npm_deploy test variable NPM_PACKAGE_NAME" {
  NPM_PACKAGE_VERSION=1.1.12
  run wp_npm_deploy
  assert_failure
  assert_output --partial "did you run wp_npm_prepare"
}

@test "wp_npm_deploy test variable NPM_PACKAGE_VERSION" {
  NPM_PACKAGE_NAME=weplayed-test
  run wp_npm_deploy
  assert_failure
  assert_output --partial "did you run wp_npm_prepare"
}

@test "wp_npm_deploy no target" {
  NPM_PACKAGE_VERSION=1.1.12
  NPM_PACKAGE_NAME=weplayed-test
  run wp_npm_deploy
  assert_failure
  assert_output --partial "-t nor --target provided"
}

@test "wp_npm_deploy no file default folder" {
  NPM_PACKAGE_VERSION=1.1.12
  NPM_PACKAGE_NAME=weplayed-test
  run wp_npm_deploy -t s3://test
  assert_failure
  assert_output --partial " weplayed-test-1.1.12.tgz does not exist"
}

@test "wp_npm_deploy no file explicit folder" {
  NPM_PACKAGE_VERSION=1.1.12
  NPM_PACKAGE_NAME=weplayed-test
  run wp_npm_deploy -t s3://test -f build
  assert_failure
  assert_output --partial "build/weplayed-test-1.1.12.tgz does not exist"
}

@test "wp_npm_deploy skip no tag" {
  NPM_PACKAGE_VERSION=1.1.12
  NPM_PACKAGE_NAME=weplayed-test
  STORK_BRANCH=develop
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir -p build
    echo > build/weplayed-test-1.1.12.tgz
    run wp_npm_deploy -t s3://test -f build
  popd >/dev/null 2>&1
  assert_success
  assert_output --partial "skipped"
}

@test "wp_npm_deploy success" {
  STORK_TAG=v1.1.12
  NPM_PACKAGE_VERSION=1.1.12
  NPM_PACKAGE_NAME=weplayed-test
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir -p build
    touch build/weplayed-test-1.1.12.tgz
    run wp_npm_deploy -t s3://test -f build
  popd >/dev/null 2>&1
  assert_success
  assert_output --partial "aws --region us-east-1 s3 cp --acl public-read build/weplayed-test-1.1.12.tgz s3://test/weplayed-test/weplayed-test-1.1.12.tgz"
}

