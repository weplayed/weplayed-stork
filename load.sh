#!/bin/bash

CWD=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

. ${CWD}/functions.sh
. ${CWD}/vars.sh
. ${CWD}/docker.sh
. ${CWD}/compose.sh
. ${CWD}/aws.sh
