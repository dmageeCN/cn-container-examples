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

source $ROOT_DIR/util

## Detect the GPU once here and export TYPE so every downstream script
## (this file, examples/<test>/build.sh) reuses it instead of re-running
## the slow *-smi probes.
detect_gpu

DOCKERFILE=$TEST_DIR/Dockerfile.${NAME}.${TYPE}
CNTR_NAME=cn-${NAME}-${TYPE}

if [[ ! (-f $DOCKERFILE) ]]; then
    echo "NO BUILD AVAILABLE FOR $NAME of type ${TYPE}"
    exit 1
fi

docker build -t ${CNTR_NAME}:v${VER} -f $DOCKERFILE --progress=plain . |& tee ${CNTR_NAME}.log

${TEST_DIR}/build.sh "$@"
