

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
  [[ "$result" = *"no \$DOCKER_PREFIX neither --name passed"* ]]
}

@test "DOCKER_PREFIX=ab wp_docker_build" {
  result=$(DOCKER_PREFIX=ab wp_docker_build)
  [ "$result" = "docker build -t ab ." ]
}

@test "wp_docker_build -n ab" {
  result=$(wp_docker_build -n ab)
  [ "$result" = "docker build -t ab ." ]
}

@test "wp_docker_build -n ab -c" {
  result=$(wp_docker_build -n ab -c 2>&1; echo)
  [[ "$result" = *"--cache specified but no \$DOCKER_REGISTRY neither --registry passed"* ]]
}

@test "wp_docker_build -n ab -c -r localhost" {
  result=$(wp_docker_build -n ab -c -r localhost)
  [ "$result" = "docker pull localhost/ab:develop-latest
docker build -t ab --cache-from localhost/ab:develop-latest ." ]
}

@test "wp_docker_build -n ab -t development" {
  result=$(wp_docker_build -n ab -t development)
  [ "$result" = "docker build -t ab --target development ." ]
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
  echo $result
  [ "$result" = "docker run --rm -v /src:/dst -v $(pwd):/app -t ab" ]
}

@test "export D=test; wp_docker_run -n ab -e D=\$D" {
  result=$(export D=test; wp_docker_run -n ab -e D=$D)
  echo $result
  [ "$result" = "docker run --rm -e D=test -t ab" ]
}

