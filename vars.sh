
# binaries etc
export PATH=${PATH}:/${HOME}/.local/bin

# needs to be set to a something like 217808715544.dkr.ecr.us-east-1.amazonaws.com
# DOCKER_REGISTRY=

DOCKER=docker
DOCKER_BUILDKIT=1
BUILDKIT_PROGRESS=plain
AWS=aws
JQ=jq

[ -z "$(which ${AWS})" ] && wp_execute pip install awscli
[ -z "$(which ${JQ})" ] && \
  wp_execute "curl -qL -o \"/usr/local/bin/${JQ}\" https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod 755 /usr/local/bin/${JQ}"

AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}

# set from $DOCKER_PREFIX by default
BRANCHES="develop master"

STORK_BRANCH=
STORK_TAG=
STORK_PULL_REQUEST=false
STORK_EVENT_TYPE=
STORK_COMMIT=head
STORK_BUILD_NUMBER=0

STORK_DOCKER_REGISTRY=${STORK_DOCKER_REGISTRY:-}
STORK_DOCKER_PREFIX=${STORK_DOCKER_PREFIX:-}
STORK_DOCKER_IMAGE=${STORK_DOCKER_IMAGE:-}
STORK_DOCKER_FILE=${STORK_DOCKER_FILE:-Dockerfile}
STORK_DOCKER_CONTEXT=${STORK_DOCKER_CONTEXT:-.}
STORK_DOCKER_CACHE=${STORK_DOCKER_CACHE:-}
