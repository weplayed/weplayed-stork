#!/bin/bash

# set -e

CWD=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

. ${CWD}/functions.sh
. ${CWD}/vars.sh
. ${CWD}/utils.sh
. ${CWD}/docker.sh
. ${CWD}/aws.sh
. ${CWD}/npm.sh

if [ "${TRAVIS}" == "true" ]
then
  source ${CWD}/travis.sh
elif [ "${GITHUB_ACTIONS}" == "true" ]
then
  . ${CWD}/github.sh
else
  wp_message ERROR "Build environment not supported, exiting"
  return 1
fi

if [ -f .storkrc ]
then
  wp_message INFO ".storkrc found"
  export $(grep -v '^#' .storkrc | xargs)
fi

wp_message INFO "Tag (${STORK_TAG}), Branch: (${STORK_BRANCH})"
