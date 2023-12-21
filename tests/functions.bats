#!/usr/bin/env bats


setup() {
  unset TRAVIS_TAG
  unset TRAVIS_BRANCH
  source load.sh
}

# wp_message

@test "wp_message INFO test" {
  result=$(wp_message INFO test 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
  [ "${result}" = "INFO: test" ]
}

@test "wp_message WARNING test" {
  result=$(wp_message WARNING test 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
  [ "${result}" = "WARNING: test" ]
}

@test "wp_message ERROR test" {
  result=$(wp_message ERROR test 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
  [ "${result}" = "ERROR: test" ]
}

# wp_execute

@test "wp_execute echo test" {
  result=$(wp_execute echo test)
  [ "$result" = "test" ]
}

@test "DEBUG=1 wp_execute echo test" {
  result=$(DEBUG=1 wp_execute echo test)
  [ "$result" = "echo test" ]
}

# wp_is_tag_build

@test "wp_is_tag_build" {
  result=$(wp_is_tag_build)
  [ -z "$result" ]
}

@test "wp_is_tag_build -t tag" {
  result=$(wp_is_tag_build -t tag)
  [ -z "$result" ]
}

@test "wp_is_tag_build -t v1" {
  result=$(wp_is_tag_build -t v1)
  [ "$result" = "v1" ]
}

@test "wp_is_tag_build -t v1.01" {
  result=$(wp_is_tag_build -t v1.01)
  [ "$result" = "v1.01" ]
}

@test "wp_is_tag_build -t v1.91.12" {
  result=$(wp_is_tag_build -t v1.91.12)
  [ "$result" = "v1.91.12" ]
}

@test "wp_is_tag_build -t v1.91.12-bats" {
  result=$(wp_is_tag_build -t v1.91.12-bats)
  [ "$result" = "v1.91.12-bats" ]
}

@test "TRAVIS_TAG=v1.91.12-bats wp_is_tag_build" {
  result=$(TRAVIS_TAG=v1.91.12-bats wp_is_tag_build)
  [ "$result" = "v1.91.12-bats" ]
}

#wp_is_staging_build

@test "wp_is_staging_build" {
  TRAVIS_BRANCH=develop
  result=$(wp_is_staging_build)
  [ "$result" = "develop" ]
}

@test "wp_is_staging_build -t v1" {
  result=$(wp_is_staging_build -t v1)
  [ -z "$result" ]
}

@test "TRAVIS_TAG=v1 wp_is_staging_build" {
  result=$(TRAVIS_TAG=v1 wp_is_staging_build)
  [ -z "$result" ]
}

@test "TRAVIS_TAG=v1 wp_is_staging_build --branch develop" {
  result=$(TRAVIS_TAG=v1 wp_is_staging_build  --branch develop)
  [ -z "$result" ]
}

@test "wp_is_staging_build --branch master" {
  result=$(wp_is_staging_build  --branch master)
  [ -z "$result" ]
}

@test "wp_is_staging_build --branch develop" {
  result=$(wp_is_staging_build -b develop)
  [ "$result" = "develop" ]
}

# wp_is_demo_build

@test "wp_is_demo_build" {
  result=$(wp_is_demo_build)
  [ -z "$result" ]
}

@test "wp_is_demo_build -t v1" {
  result=$(wp_is_demo_build -t v1)
  [ -z "$result" ]
}

@test "TRAVIS_TAG=v1 wp_is_demo_build" {
  result=$(TRAVIS_TAG=v1 wp_is_demo_build)
  [ -z "$result" ]
}

@test "wp_is_demo_build -b develop" {
  result=$(wp_is_demo_build -b develop)
  [ -z "$result" ]
}

@test "wp_is_demo_build -b master" {
  result=$(wp_is_demo_build -b master)
  [ -z "$result" ]
}

@test "wp_is_demo_build -b feature" {
  result=$(wp_is_demo_build -b feature)
  [ -z "$result" ]
}

@test "wp_is_demo_build -b feature/test" {
  result=$(wp_is_demo_build -b feature/test)
  [ "$result" = "feature/test" ]
}

@test "wp_is_demo_build -t v1 -b feature/test" {
  result=$(wp_is_demo_build -t v1 -b feature/test)
  [ -z "$result" ]
}

@test "TRAVIS_BRANCH=bugfix/test wp_is_demo_build" {
  result=$(TRAVIS_BRANCH=bugfix/test wp_is_demo_build)
  [ "$result" = "bugfix/test" ]
}

@test "TRAVIS_BRANCH=bugfix/test wp_is_demo_build -b hotfix/test" {
  result=$(TRAVIS_BRANCH=bugfix/test wp_is_demo_build -b hotfix/test)
  [ "$result" = "hotfix/test" ]
}

@test "wp_is_demo_build -b support/test" {
  result=$(wp_is_demo_build -b support/test)
  [ "$result" = "support/test" ]
}

# wp_set_weplayed_env

@test "wp_set_weplayed_env -b ''" {
  result=$(wp_set_weplayed_env -b ''; echo $?)
  [ "$result" = "1" ]
}

@test "wp_set_weplayed_env" {
  result=$(wp_set_weplayed_env; echo "${WEPLAYED_ENV}")
  [ -z "${result}" ]
}

@test "wp_set_weplayed_env -s staging" {
  TRAVIS_BRANCH=develop
  result=$(wp_set_weplayed_env -s staging; echo "${WEPLAYED_ENV}")
  [ "${result}" = "staging" ]
}

@test "TRAVIS_TAG=test TRAVIS_BRANCH=develop wp_set_weplayed_env -l production -s staging -d demo" {
  result=$(TRAVIS_TAG=test TRAVIS_BRANCH=develop wp_set_weplayed_env -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ -z "$result" ]
}

@test "TRAVIS_TAG=v12.5 TRAVIS_BRANCH=master wp_set_weplayed_env -l production -s staging -d demo" {
  result=$(TRAVIS_TAG=v12.5 TRAVIS_BRANCH=master wp_set_weplayed_env -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ "$result" = "production" ]
}

@test "wp_set_weplayed_env -t v12.5 -b master -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -t v12.5 -b master -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ "$result" = "production" ]
}

@test "wp_set_weplayed_env -t v12.5 -b develop -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -t v12.5 -b develop -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ "$result" = "production" ]
}

@test "wp_set_weplayed_env -b develop -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b develop -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ "$result" = "staging" ]
}

@test "wp_set_weplayed_env -b feature -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b feature -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ -z "$result" ]
}

@test "wp_set_weplayed_env -b feature/test -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b feature/test -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ "$result" = "demo" ]
}

@test "wp_set_weplayed_env -b hotfix/test -l production -s staging -d demo" {
  result=$(wp_set_weplayed_env -b hotfix/test -l production -s staging -d demo; echo "${WEPLAYED_ENV}")
  [ "$result" = "demo" ]
}

