wp_compse_test() {
  if [ !-f "docker-compose.yaml" ] && [ !-f "docker-compose.yml" ]
  then
    wp_message ERROR "no docker-compose.yaml or docker-compose.yml file present"
    return 1
  fi
}

wp_compose_up() {
  wp_compse_test
  [ $? -ne 0 ] && return $?

  wp_execute ${COMPOSE} up -d $@

  return $?
}

wp_compose_down() {
  wp_compse_test
  [ $? -ne 0 ] && return $?

  wp_execute ${COMPOSE} down -v

  return $?
}

wp_compose_run() {
  wp_compse_test
  [ $? -ne 0 ] && return $?

  wp_execute ${COMPOSE} run --rm $@

  return $?
}
