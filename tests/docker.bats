

setup() {
  docker() {
    echo "docker" $@
  }

  unset TRAVIS_TAG
  unset TRAVIS_BRANCH
  source load.sh
}

@test "wp_docker_build" {
  result=$(wp_docker_build 2>&1; echo)
  [[ "$result" = *"no --image passed"* ]]
}

@test "wp_docker_build --image ab" {
  result=$(wp_docker_build --image ab)
  [ "$result" = "docker build -t ab ." ]
}

@test "wp_docker_build -i ab -d test/Dockerfile" {
  result=$(wp_docker_build -i ab -d test/Dockerfile)
  [ "$result" = "docker build -t ab -f test/Dockerfile ." ]
}

@test "wp_docker_build -n ab" {
  result=$(wp_docker_build -i ab -- --build-arg test=test)
  [ "$result" = "docker build -t ab --build-arg test=test ." ]
}

@test "wp_docker_build -i ab -c test -x .." {
  result=$(wp_docker_build -i ab -c test -x .. 2>&1; echo)
  [[ "$result" = *"docker build -t ab --cache-from test .."* ]]
}

# wp_docker_run

@test "wp_docker_run" {
  result=$(wp_docker_run 2>&1; echo)
  [[ "$result" = *"no \$DOCKER_PREFIX neither --name passed"* ]]
}

@test "wp_docker_run -n ab" {
  result=$(wp_docker_run -n ab)
  [ "$result" = "docker run --rm -t ab" ]
}

@test "DOCKER_PREFIX=ab wp_docker_run" {
  result=$(DOCKER_PREFIX=ab wp_docker_run)
  [ "$result" = "docker run --rm -t ab" ]
}

@test "wp_docker_run -n ab -v /app" {
  result=$(wp_docker_run -n ab -v /app)
  [ "$result" = "docker run --rm -v $(pwd):/app -t ab" ]
}

@test "VOLUME_MOUNT=/app wp_docker_run -n ab" {
  result=$(VOLUME_MOUNT=/app wp_docker_run -n ab)
  [ "$result" = "docker run --rm -v $(pwd):/app -t ab" ]
}

@test "wp_docker_run -n ab -v /app -m /src:/dst" {
  result=$(wp_docker_run -n ab -v /app -m /src:/dst)
  [ "$result" = "docker run --rm -v /src:/dst -v $(pwd):/app -t ab" ]
}

@test "export D=test; wp_docker_run -n ab -e D=\$D" {
  result=$(export D=test; wp_docker_run -n ab -e D=$D)
  [ "$result" = "docker run --rm -e D=test -t ab" ]
}

