#!/usr/bin/env bash

## FIND THIS DIRECTORY
if [[ -z $TEST_DIR ]]; then
    THISFILE=${BASH_SOURCE[0]}
    : ${THISFILE:=$0}

    export TEST_DIR=$(dirname $(realpath ${THISFILE}))
fi
: ${NAME:=$(basename ${TEST_DIR})}
export NAME

## FIND ROOT_DIR (walk up until we find util) AND SOURCE util
if [[ -z $ROOT_DIR ]]; then
    d=$TEST_DIR
    while [[ ! -f $d/util && $d != / ]]; do
        d=$(dirname $d)
    done
    export ROOT_DIR=$d
fi

source $ROOT_DIR/util

setvar "$@"

: ${VER:=2}

export VER

SRC=${SRC_DIR}/rocHPL-MxP
cd $SRC

## detect_gpu (called by gpu_build_env) is a no-op if TYPE is already
## exported by the root build.sh dispatcher, so the *-smi probes only ever
## run once per invocation.
gpu_build_env
case $TYPE in
    amd )    git checkout main ;;
    nvidia ) git checkout cuda_port ;;
esac

CMAKE_FLAGS+=" -DCMAKE_BUILD_TYPE=Release -DHPLMXP_VERBOSE_PRINT=ON"
CMAKE_FLAGS+=" -DHPLMXP_PROGRESS_REPORT=ON -DHPLMXP_DETAILED_TIMING=ON"

set_paths $TYPE
export HPLMXP_HOME="${HOST_INSTALL}/rocHPL-MxP"
CMAKE_FLAGS+=" -DCMAKE_INSTALL_PREFIX=${HPLMXP_HOME} -DHPLMXP_MPI_DIR=${MPI_HOME}"

export CC=mpicc CXX=mpicxx FC=mpifort

BUILD_DIR=/tmp/hplmxp-${TYPE}
mkcd $BUILD_DIR
cmake_it $CMAKE_FLAGS $SRC
