#!/usr/bin/env bats

setup() {
  aws() {
    echo "aws" $@
  }

  unset TRAVIS_TAG
  unset TRAVIS_BRANCH
  source load.sh
}

# wp_s3_deploy

@test "TRAVIS_EVENT_TYPE=pull_request wp_s3_deploy" {
  export TRAVIS_EVENT_TYPE=pull_request
  run wp_s3_deploy 2>&1
  unset TRAVIS_EVENT_TYPE
  [ "${status}" -eq 0 ]
  [[ "${output}" = *skip* ]]
}

@test "wp_s3_deploy -t '' -b ''" {
  run wp_s3_deploy -t '' -b ''
  [ "${status}" -eq 1 ]
}

@test "TRAVIS_BRANCH= TRAVIS_TAG= wp_s3_deploy" {
  export TRAVIS_BRANCH= TRAVIS_TAG=
  run wp_s3_deploy
  unset TRAVIS_BRANCH TRAVIS_TAG
  [ "${status}" -eq 1 ]
}

@test "wp_s3_deploy" {
  run wp_s3_deploy
  [ "${status}" -eq 1 ]
}

@test "wp_s3_deploy -b master -l s3://live -s s3://staging -d s3://demo dist," {
  run wp_s3_deploy -b master -l s3://live -s s3://staging -d s3://demo dist, 2>&1
  [ "${status}" -eq 0 ]
  [[ "${output}" = *skipped* ]]
}

@test "wp_s3_deploy -b develop -l s3://live -d s3://demo dist," {
  run wp_s3_deploy -b develop -l s3://live -d s3://demo dist, 2>&1
  [ "${status}" -eq 0 ]
  [[ "${output}" = *skipped* ]]
}

@test "wp_s3_deploy -b develop -l s3://live -s s3://staging -d s3://demo dist," {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -b develop -l s3://live -s s3://staging -d s3://demo dist, 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  [ "${status}" -eq 0 ]
  [ "${output}" = "aws --region us-east-1 s3 cp --recursive dist s3://staging" ]
}

@test "wp_s3_deploy -t v1.10 -l s3://live/:tag: dist," {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -t v1.10 -l s3://live/:tag: dist, 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  [ "${status}" -eq 0 ]
  [ "${output}" = "aws --region us-east-1 s3 cp --recursive dist s3://live/v1.10" ]
}

@test "wp_s3_deploy -t v1.10 -l s3://live/:tagmajor: dist," {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -t v1.10 -l s3://live/:tagmajor: dist, 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  [ "${status}" -eq 0 ]
  [ "${output}" = "aws --region us-east-1 s3 cp --recursive dist s3://live/v1" ]
}

@test "wp_s3_deploy -b feature/test -d s3://demo/:branch: dist" {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -b feature/test -d s3://demo/:branch: dist 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  [ "${status}" -eq 0 ]
  [ "${output}" = "aws --region us-east-1 s3 cp --recursive dist s3://demo/feature/test/dist" ]
}

@test "wp_s3_deploy sibgle file" {
  run wp_s3_deploy -b feature/test -d s3://demo/:branch: dist.tgz,dist 2>&1
  [ "${status}" -eq 0 ]
  [ "${output}" = "aws --region us-east-1 s3 cp dist.tgz s3://demo/feature/test/dist" ]
}

# wp_ecs_deploy

@test "wp_ecs_deploy" {
  run wp_ecs_deploy
  [ "${status}" -eq 1 ]
}

@test "wp_ecs_deploy -s ab" {
  TRAVIS_BRANCH=develop
  run wp_ecs_deploy -s ab
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"aws ecs update-service --service ab --cluster testcluster --force-new-deployment --region us-east-1"* ]]
}

@test "wp_ecs_deploy -s ab -c live" {
  TRAVIS_BRANCH=develop
  run wp_ecs_deploy -s ab -c live
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"aws ecs update-service --service ab --cluster live --force-new-deployment --region us-east-1"* ]]
}

@test "TRAVIS_BRANCH=develop wp_ecs_deploy -s ab -c live -b master" {
  export TRAVIS_BRANCH=develop
  run wp_ecs_deploy -s ab -c live -b master 2>&1
  unset TRAVIS_BRANCH
  [ "${status}" -eq 0 ]
  [[ "${output}" = *skip* ]]
}

@test "TRAVIS_BRANCH=develop wp_ecs_deploy -s ab -c live -b develop" {
  export TRAVIS_BRANCH=develop
  run wp_ecs_deploy -s ab -c live -b develop
  unset TRAVIS_BRANCH
  [[ "${output}" = *"aws ecs update-service --service ab --cluster live --force-new-deployment --region us-east-1"* ]]
}

