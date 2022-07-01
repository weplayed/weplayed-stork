
# binaries etc
export PATH=${PATH}:/${HOME}/.local/bin

# needs to be set to a something like 217808715544.dkr.ecr.us-east-1.amazonaws.com
# DOCKER_REGISTRY=

DOCKER=$(which docker)
COMPOSE=$(which docker-compose)

AWS=$(which aws)
[ -z "$AWS" ] && pip install awscli && AWS=$(which aws)

AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}

TRAVIS_TAG=${TRAVIS_TAG:-}
TRAVIS_BRANCH=${TRAVIS_BRANCH:-develop}
TRAVIS_COMMIT=${TRAVIS_COMMIT:-head}
TRAVIS_BUILD_NUMBER=${TRAVIS_BUILD_NUMBER:-0}

# set from $DOCKER_PREFIX by default
BASENAME="${BASENAME:-$DOCKER_PREFIX}"
BRANCHES="develop master"

wp_message INFO "Travis tag (${TRAVIS_TAG}), branch: (${TRAVIS_BRANCH})"
