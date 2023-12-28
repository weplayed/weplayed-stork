#!/usr/bin/env bats

bats_load_library "bats-support"
bats_load_library "bats-assert"

# wp_docker_build
setup() {
  docker() {
    echo "docker" $@
  }

  TRAVIS=true . load.sh
}

@test '[]' {
  run wp_docker_build
  assert_failure
  assert_output --partial 'no -i/$STORK_DOCKER_IMAGE passed'
}

@test '-i' {
  run wp_docker_build -i ab
  assert_success
  assert_output --partial 'docker build -t ab -f Dockerfile .'
}

@test '--image' {
  run wp_docker_build --image ab
  assert_success
  assert_output --partial 'docker build -t ab -f Dockerfile .'
}

@test '\$STORK_DOCKER_IMAGE' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build
  assert_success
  assert_output --partial 'docker build -t ab -f Dockerfile .'
}

@test '-x' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build -x test
  assert_success
  assert_output --partial 'docker build -t ab -f Dockerfile test'
}

@test '--context' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build --context test
  assert_success
  assert_output --partial 'docker build -t ab -f Dockerfile test'
}

@test '\$STORK_DOCKER_CONTEXT' {
  STORK_DOCKER_IMAGE=ab
  STORK_DOCKER_CONTEXT=test
  run wp_docker_build
  assert_success
  assert_output --partial 'docker build -t ab -f Dockerfile test'
}

@test '-x \"\"' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build -x ''
  assert_failure
  assert_output --partial 'no -x/$STORK_DOCKER_CONTEXT passed'
}

@test '-f' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build -f test/Dockerfile
  assert_success
  assert_output --partial 'docker build -t ab -f test/Dockerfile .'
}

@test '--dockerfile' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build --dockerfile test/Dockerfile
  assert_success
  assert_output --partial 'docker build -t ab -f test/Dockerfile .'
}

@test '\$STORK_DOCKER_FILE' {
  STORK_DOCKER_IMAGE=ab
  STORK_DOCKER_FILE=test/Dockerfile
  run wp_docker_build
  assert_success
  assert_output --partial 'docker build -t ab -f test/Dockerfile .'
}

@test '-f \"\"' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build -f ''
  assert_failure
  assert_output --partial 'no -f/$STORK_DOCKER_FILE passed'
}

@test '-c ab:latest' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build -c ab:latest
  assert_success
  assert_output --partial 'docker build -t ab --cache-from ab:latest -f Dockerfile .'
}

@test '--cache ab:latest' {
  STORK_DOCKER_IMAGE=ab
  run wp_docker_build --cache ab:latest
  assert_success
  assert_output --partial 'docker build -t ab --cache-from ab:latest -f Dockerfile .'
}

@test '\$STORK_DOCKER_CACHE=ab:latest' {
  STORK_DOCKER_IMAGE=ab
  STORK_DOCKER_CACHE=ab:latest
  run wp_docker_build
  assert_success
  assert_output --partial 'docker build -t ab --cache-from ab:latest -f Dockerfile .'
}
