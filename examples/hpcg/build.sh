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

SRC=${SRC_DIR}/rocHPCG
cd $SRC

## detect_gpu (called by gpu_build_env) is a no-op if TYPE is already
## exported by the root build.sh dispatcher, so the *-smi probes only ever
## run once per invocation.
gpu_build_env
case $TYPE in
    amd )    git checkout develop; CMAKE_FLAGS+=" -DOPT_ROCTX=ON" ;;
    nvidia ) git checkout cuda_port; CMAKE_FLAGS+=" -DCUDAToolkit_ROOT=${GPU_HOME} -DOPT_NVTX=ON -DGPU_AWARE_MPI=ON" ;;
esac

CMAKE_FLAGS+=" -DCMAKE_BUILD_TYPE=Release"

set_paths $TYPE
export TEST_HOME="${HOST_INSTALL}/${NAME}-${TYPE}"
CMAKE_FLAGS+=" -DCMAKE_INSTALL_PREFIX=${TEST_HOME} -DHPCG_MPI_DIR=${MPI_HOME}"

export CC=mpicc CXX=mpicxx FC=mpifort

BUILD_DIR=/tmp/${NAME}-${TYPE}
mkcd $BUILD_DIR
cmake_it $CMAKE_FLAGS $SRC
