#!/usr/bin/env bash

## FIND THIS DIRECTORY
THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

export ROOT_DIR=$(dirname $(realpath ${THISFILE}))

NAME=$1
shift
export NAME
export TEST_DIR=${ROOT_DIR}/examples/${NAME}

source $ROOT_DIR/util
setvar "$@"

ulimit -n 65000

${TEST_DIR}/run.sh "$@"
