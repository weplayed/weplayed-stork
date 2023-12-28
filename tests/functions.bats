bats_load_library "bats-support"
bats_load_library "bats-assert"

setup() {
  unset STORK_TAG
  unset STORK_BRANCH

  TRAVIS=true . load.sh
}

# wp_message

@test "wp_message INFO test" {
  run wp_message INFO test
  assert_output --regexp "INFO:.*?test"
}

@test "wp_message WARNING test" {
  run wp_message WARNING test
  assert_output --regexp "WARNING:.*?test"
}

@test "wp_message ERROR test" {
  run wp_message ERROR test
  assert_output --regexp "ERROR:.*?test"
}

# # wp_execute

@test "wp_execute echo test" {
  run wp_execute echo test
  assert_output "test"
}

@test "DEBUG=1 wp_execute echo test" {
  DEBUG=1
  run wp_execute echo test
  assert_output "echo test"
}

# wp_is_tag_build

@test "wp_is_tag_build" {
  run wp_is_tag_build
  assert_output ""
}

@test "wp_is_tag_build -t tag" {
  run wp_is_tag_build -t tag
  assert_output ""
}

@test "wp_is_tag_build -t v1" {
  run wp_is_tag_build -t v1
  assert_output "v1"
}

@test "wp_is_tag_build -t v1.01" {
  run wp_is_tag_build -t v1.01
  assert_output "v1.01"
}

@test "wp_is_tag_build -t v1.91.12" {
  run wp_is_tag_build -t v1.91.12
  assert_output "v1.91.12"
}

@test "wp_is_tag_build -t v1.91.12-bats" {
  run wp_is_tag_build -t v1.91.12-bats
  assert_output "v1.91.12-bats"
}

@test "STORK_TAG=v1.91.12-bats wp_is_tag_build" {
  STORK_TAG=v1.91.12-bats
  run wp_is_tag_build
  assert_output "v1.91.12-bats"
}

#wp_is_staging_build

@test "wp_is_staging_build" {
  STORK_BRANCH=develop
  run wp_is_staging_build
  assert_output "develop"
}

@test "wp_is_staging_build -t v1" {
  run wp_is_staging_build -t v1
  assert_output ""
}

@test "STORK_TAG=v1 wp_is_staging_build" {
  STORK_TAG=v1
  run wp_is_staging_build
  assert_output ""
}

@test "STORK_TAG=v1 wp_is_staging_build --branch develop" {
  STORK_TAG=v1
  run wp_is_staging_build  --branch develop
  assert_output ""
}

@test "wp_is_staging_build --branch master" {
  run wp_is_staging_build  --branch master
  assert_output ""
}

@test "wp_is_staging_build --branch develop" {
  run wp_is_staging_build -b develop
  assert_output "develop"
}

# wp_is_demo_build

@test "wp_is_demo_build" {
  run wp_is_demo_build
  assert_output ""
}

@test "wp_is_demo_build -t v1" {
  run wp_is_demo_build -t v1
  assert_output ""
}

@test "STORK_TAG=v1 wp_is_demo_build" {
  STORK_TAG=v1
  run wp_is_demo_build
  assert_output ""
}

@test "wp_is_demo_build -b develop" {
  run wp_is_demo_build -b develop
  assert_output ""
}

@test "wp_is_demo_build -b master" {
  run wp_is_demo_build -b master
  assert_output ""
}

@test "wp_is_demo_build -b feature" {
  run wp_is_demo_build -b feature
  assert_output ""
}

@test "wp_is_demo_build -b feature/test" {
  run wp_is_demo_build -b feature/test
  assert_output "feature/test"
}

@test "wp_is_demo_build -t v1 -b feature/test" {
  run wp_is_demo_build -t v1 -b feature/test
  assert_output ""
}

@test "STORK_BRANCH=bugfix/test wp_is_demo_build" {
  STORK_BRANCH=bugfix/test
  run wp_is_demo_build
  assert_output "bugfix/test"
}

@test "STORK_BRANCH=bugfix/test wp_is_demo_build -b hotfix/test" {
  STORK_BRANCH=bugfix/test
  run wp_is_demo_build -b hotfix/test
  assert_output "hotfix/test"
}

@test "wp_is_demo_build -b support/test" {
  run wp_is_demo_build -b support/test
  assert_output "support/test"
}

# wp_set_weplayed_env

@test "wp_set_weplayed_env -b ''" {
  run wp_set_weplayed_env -b ''
  assert_failure
}

@test "wp_set_weplayed_env" {
  run wp_set_weplayed_env
  assert_failure
}

@test "wp_set_weplayed_env -s staging" {
  STORK_BRANCH=develop
  result=$(wp_set_weplayed_env -s staging; echo $WEPLAYED_ENV)
  assert [ "$result" == "staging" ]
}

@test "STORK_TAG=test STORK_BRANCH=develop wp_set_weplayed_env -l production -s staging -d demo" {
  STORK_TAG=test
  STORK_BRANCH=develop
  result=$(wp_set_weplayed_env -l production -s staging -d demo; echo $WEPLAYED_ENV)
  assert [ "$result" == "" ]
}

@test "STORK_TAG=v12.5 STORK_BRANCH=master wp_set_weplayed_env -l production -s staging -d demo" {
  STORK_TAG=v12.5
  STORK_BRANCH=master
  result=$(wp_set_weplayed_env -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "production" ]
}

@test "wp_set_weplayed_env -t v12.5 -b master -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -t v12.5 -b master -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "production" ]
}

@test "wp_set_weplayed_env -t v12.5 -b develop -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -t v12.5 -b develop -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "production" ]
}

@test "wp_set_weplayed_env -b develop -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b develop -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "staging" ]
}

@test "wp_set_weplayed_env -b feature -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b feature -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "" ]
}

@test "wp_set_weplayed_env -b feature/test -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b feature/test -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "demo" ]
}

@test "wp_set_weplayed_env -b hotfix/test -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b hotfix/test -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  assert [ "$result" == "demo" ]
}

