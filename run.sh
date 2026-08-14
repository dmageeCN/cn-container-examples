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

## Detect the GPU once here and export TYPE so every downstream script
## (examples/<test>/run.sh) reuses it instead of re-running the slow
## *-smi probes.
detect_gpu

${TEST_DIR}/run.sh "$@"
