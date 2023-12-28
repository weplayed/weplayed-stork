bats_load_library "bats-support"
bats_load_library "bats-assert"

# wp_docker_build
setup() {
  docker() {
    echo "docker" $@
  }

  TRAVIS=true . load.sh
}

# wp_docker_run

@test "wp_docker_run" {
  run wp_docker_run
  assert_failure
  assert_output --partial "no -i/\$STORK_DOCKER_IMAGE passed"
}

@test "wp_docker_run -i ab" {
  run wp_docker_run -i ab
  assert_success
  assert_output --partial "docker run --rm ab"
}

@test "STORK_DOCKER_IMAGE=ab wp_docker_run" {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_run
  assert_success
  assert_output --partial "docker run --rm ab"
}

@test "wp_docker_run -i ab -- -v pwd:/app" {
  _pwd=$(pwd)
  run wp_docker_run -i ab -- -v "$_pwd:/app"
  assert_success
  assert_output --partial "docker run --rm -v "$_pwd:/app" ab"
}

@test "wp_docker_run -i ab -- -v pwd/app -v /src:/dst" {
  _pwd=$(pwd)
  run wp_docker_run -i ab -- -v "$_pwd:/app" -v /src:/dst
  assert_success
  assert_output --partial "docker run --rm -v "$_pwd:/app" -v /src:/dst ab"
}

@test "export D=test; wp_docker_run -i ab -e D=\$D" {
  D=test
  run wp_docker_run -i ab -- -e D=$D
  assert_success
  assert_output --partial "docker run --rm -e D=test ab"
}

