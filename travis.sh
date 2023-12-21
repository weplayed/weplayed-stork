wp_travis_install_docker() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

wp_travis_generate_tags() {
  if [ -n "${TRAVIS_PULL_REQUEST}" ] && [ "${TRAVIS_PULL_REQUEST}" != false ]
  then
	  wp_message WARNING "push skipped because of PR"
	  return 0
  fi

  tags=

  if [ "${TRAVIS_BRANCH}" == "develop" ]
  then
    tags="${tags} develop-latest"
  # elif [ "${TRAVIS_BRANCH}" == "master" ]
  # then
  #   tags="${tags} master-latest"
  elif [ -n "${TRAVIS_TAG}" ]
  then
    tag=$(wp_is_tag_build -t ${TRAVIS_TAG})
    if [ -n  "${tag}" ]
    then
      tags="${tags} master-latest ${tag}"
    fi
  fi

  if [ -n "${tags}" ]
  then
    tags="sha-${TRAVIS_COMMIT}${tags}"
  fi

  echo -n ${tags}
}
