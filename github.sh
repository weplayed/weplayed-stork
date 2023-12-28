STORK_BRANCH=
STORK_TAG=

if [ "${GITHUB_REF_TYPE}" == "branch" ]
then
  export STORK_BRANCH="${GITHUB_REF_NAME}"
elif [ "${GITHUB_REF_TYPE}" == "tag" ]
  export STORK_TAG="${GITHUB_REF_NAME}"
fi

export STORK_PULL_REQUEST=false

if [ "${GITHUB_EVENT_NAME}" == "pull_request" ]
then
  export STORK_PULL_REQUEST=$(echo "${GITHUB_REF}" | sed -e 's|^refs/pull/\([0-9]\+)\/merge|\1|')
fi

export STORK_EVENT_TYPE=${GITHUB_EVENT_NAME}
export STORK_COMMIT=${GITHUB_SHA:-head}
export STORK_BUILD_NUMBER=${GITHUB_RUN_ID:-0}
