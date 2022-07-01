wp_compse_test() {
  if [ -z "${COMPOSE}" ]
  then
    wp_message ERROR "no docker-compose binary found"
    return 1
  fi

  if [ !-f "docker-compose.yaml" ] && [ !-f "docker-compose.yml" ]
  then
    wp_message ERROR "no docker-compose.yaml or docker-compose.yml file present"
    return 1
  fi
}

wp_compose_up() {
  wp_compse_test
  [ $? -ne 0 ] && return $?

  ${COMPOSE} up -d $@

  return $?
}

wp_compose_down() {
  wp_compse_test
  [ $? -ne 0 ] && return $?

  ${COMPOSE} down -v

  return $?
}

wp_compose_run() {
  wp_compse_test
  [ $? -ne 0 ] && return $?

  ${COMPOSE} run --rm $@

  return $?
}
