bats_load_library "bats-support"
bats_load_library "bats-assert"

setup() {
  aws() {
    echo "aws" $@
  }

  unset STORK_TAG
  unset STORK_BRANCH

  TRAVIS=true . load.sh
}

# wp_s3_deploy

@test "STORK_EVENT_TYPE=pull_request wp_s3_deploy" {
  STORK_EVENT_TYPE=pull_request
  run wp_s3_deploy
  assert_success
  assert_output --partial "skip"
}

@test "wp_s3_deploy -t '' -b ''" {
  run wp_s3_deploy -t '' -b ''
  assert_failure
}

@test "STORK_BRANCH= STORK_TAG= wp_s3_deploy" {
  export STORK_BRANCH= STORK_TAG=
  run wp_s3_deploy
  unset STORK_BRANCH STORK_TAG
  assert_failure
}

@test "wp_s3_deploy" {
  run wp_s3_deploy
  assert_failure
}

@test "wp_s3_deploy -b master -l s3://live -s s3://staging -d s3://demo dist," {
  run wp_s3_deploy -b master -l s3://live -s s3://staging -d s3://demo dist, 2>&1
  assert_success
  assert_output --partial "skipped"
}

@test "wp_s3_deploy -b develop -l s3://live -d s3://demo dist," {
  run wp_s3_deploy -b develop -l s3://live -d s3://demo dist, 2>&1
  assert_success
  assert_output --partial "skipped"
}

@test "wp_s3_deploy -b develop -l s3://live -s s3://staging -d s3://demo dist," {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -b develop -l s3://live -s s3://staging -d s3://demo dist, 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  assert_success
  assert_output "aws --region us-east-1 s3 cp --recursive dist s3://staging"
}

@test "wp_s3_deploy -t v1.10 -l s3://live/:tag: dist," {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -t v1.10 -l s3://live/:tag: dist, 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  assert_success
  assert_output "aws --region us-east-1 s3 cp --recursive dist s3://live/v1.10"
}

@test "wp_s3_deploy -t v1.10 -l s3://live/:tagmajor: dist," {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -t v1.10 -l s3://live/:tagmajor: dist, 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  assert_success
  assert_output "aws --region us-east-1 s3 cp --recursive dist s3://live/v1"
}

@test "wp_s3_deploy -b feature/test -d s3://demo/:branch: dist" {
  pushd $BATS_RUN_TMPDIR >/dev/null 2>&1
    mkdir dist
    run wp_s3_deploy -b feature/test -d s3://demo/:branch: dist 2>&1
    rm -rf dist
  popd >/dev/null 2>&1
  assert_success
  assert_output "aws --region us-east-1 s3 cp --recursive dist s3://demo/feature/test/dist"
}

@test "wp_s3_deploy sibgle file" {
  run wp_s3_deploy -b feature/test -d s3://demo/:branch: dist.tgz,dist 2>&1
  assert_success
  assert_output "aws --region us-east-1 s3 cp dist.tgz s3://demo/feature/test/dist"
}

# wp_ecs_deploy

@test "wp_ecs_deploy" {
  run wp_ecs_deploy
  assert_failure
}

@test "wp_ecs_deploy -s ab" {
  STORK_BRANCH=develop
  run wp_ecs_deploy -s ab
  assert_success
  echo ${output}
  assert_output --partial "aws ecs update-service --service ab --cluster testcluster --force-new-deployment --region us-east-1"
}

@test "wp_ecs_deploy -s ab -c live" {
  STORK_BRANCH=develop
  run wp_ecs_deploy -s ab -c live
  assert_success
  assert_output --partial "aws ecs update-service --service ab --cluster live --force-new-deployment --region us-east-1"
}

@test "STORK_BRANCH=develop wp_ecs_deploy -s ab -c live -b master" {
  export STORK_BRANCH=develop
  run wp_ecs_deploy -s ab -c live -b master 2>&1
  unset STORK_BRANCH
  assert_success
  assert_output --partial "skip"
}

@test "STORK_BRANCH=develop wp_ecs_deploy -s ab -c live -b develop" {
  export STORK_BRANCH=develop
  run wp_ecs_deploy -s ab -c live -b develop
  unset STORK_BRANCH
  assert_output --partial "aws ecs update-service --service ab --cluster live --force-new-deployment --region us-east-1"
}

