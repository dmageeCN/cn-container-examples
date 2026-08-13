#!/usr/bin/env bash

## FIND THIS DIRECTORY
THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

export ROOT_DIR=$(dirname $(realpath ${THISFILE}))

NAME=$1
shift
export NAME
export TEST_DIR=${ROOT_DIR}/examples/${NAME}
VER=2

type=cpu
if nvidia-smi &> /dev/null; then
    type=nvidia
fi
if rocm-smi &> /dev/null; then
    type=amd
fi

DOCKERFILE=$TEST_DIR/Dockerfile.${NAME}.${type}
CNTR_NAME=cn-${NAME}-${type}

if [[ ! (-f $DOCKERFILE) ]]; then
    echo "NO BUILD AVAILABLE FOR $NAME of type ${type}"
    exit 1
fi

docker build -t ${CNTR_NAME}:v${VER} -f $DOCKERFILE --progress=plain . |& tee ${CNTR_NAME}.log

${TEST_DIR}/build.sh "$@"
