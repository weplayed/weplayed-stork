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
  result=$(TRAVIS_EVENT_TYPE=pull_request wp_s3_deploy 2>&1)
  [[ "$result" = *skip* ]]
}

@test "wp_s3_deploy -t '' -b ''" {
  result=$(wp_s3_deploy -t '' -b '' >/dev/null 2>&1; echo $?)
  [ "$result" = "1" ]
}

@test "TRAVIS_BRANCH= TRAVIS_TAG= wp_s3_deploy" {
  result=$(TRAVIS_BRANCH= TRAVIS_TAG= wp_s3_deploy >/dev/null 2>&1; echo $?)
  [ "$result" = "1" ]
}

@test "wp_s3_deploy" {
  result=$(wp_s3_deploy >/dev/null 2>&1; echo $?)
  [ "$result" = "1" ]
}

@test "wp_s3_deploy -b master -l s3://live -s s3://staging -d s3://demo dist," {
  result=$(wp_s3_deploy -b master -l s3://live -s s3://staging -d s3://demo dist, 2>&1)
  [[ "$result" = *skipped* ]]
}

@test "wp_s3_deploy -b develop -l s3://live -d s3://demo dist," {
  result=$(wp_s3_deploy -b develop -l s3://live -d s3://demo dist, 2>&1)
  [[ "$result" = *skipped* ]]
}

@test "wp_s3_deploy -b develop -l s3://live -s s3://staging -d s3://demo dist," {
  result=$(wp_s3_deploy -b develop -l s3://live -s s3://staging -d s3://demo dist, 2>&1)
  [ "$result" = "aws --region us-east-1 s3 cp --recursive dist s3://staging" ]
}

@test "wp_s3_deploy -t v1.10 -l s3://live/:tag: dist," {
  result=$(wp_s3_deploy -t v1.10 -l s3://live/:tag: dist, 2>&1)
  [ "$result" = "aws --region us-east-1 s3 cp --recursive dist s3://live/v1.10" ]
}

@test "wp_s3_deploy -t v1.10 -l s3://live/:tagmajor: dist," {
  result=$(wp_s3_deploy -t v1.10 -l s3://live/:tagmajor: dist, 2>&1)
  [ "$result" = "aws --region us-east-1 s3 cp --recursive dist s3://live/v1" ]
}

@test "wp_s3_deploy -b feature/test -d s3://demo/:branch: dist" {
  result=$(wp_s3_deploy -b feature/test -d s3://demo/:branch: dist 2>&1)
  [ "$result" = "aws --region us-east-1 s3 cp --recursive dist s3://demo/feature/test/dist" ]
}

@test "export DATAPATH=sub/path; wp_s3_deploy -b feature/test -d s3://demo/:branch:/\${DATAPATH} ,dist" {
  result=$(export DATAPATH=sub/path; wp_s3_deploy -b feature/test -d s3://demo/:branch:/${DATAPATH} ,dist 2>&1)
  [ "$result" = "aws --region us-east-1 s3 cp --recursive . s3://demo/feature/test/sub/path/dist" ]
}

# wp_ecs_deploy

@test "wp_ecs_deploy" {
  result=$(wp_ecs_deploy; echo $?)
  [ "$result" = "1" ]
}

@test "wp_ecs_deploy -s ab" {
  result=$(wp_ecs_deploy -s ab)
  [ "$result" = "aws ecs update-service --service ab --cluster testcluster --force-new-deployment --region us-east-1" ]
}

@test "wp_ecs_deploy -s ab -c live" {
  result=$(wp_ecs_deploy -s ab -c live)
  [ "$result" = "aws ecs update-service --service ab --cluster live --force-new-deployment --region us-east-1" ]
}

@test "TRAVIS_BRANCH=develop wp_ecs_deploy -s ab -c live -b master" {
  result=$(TRAVIS_BRANCH=develop wp_ecs_deploy -s ab -c live -b master 2>&1)
  [[ "$result" = *skip* ]]
}

@test "TRAVIS_BRANCH=develop wp_ecs_deploy -s ab -c live -b develop" {
  result=$(TRAVIS_BRANCH=develop wp_ecs_deploy -s ab -c live -b develop)
  [ "$result" = "aws ecs update-service --service ab --cluster live --force-new-deployment --region us-east-1" ]
}

