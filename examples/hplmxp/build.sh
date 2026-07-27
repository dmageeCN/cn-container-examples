#!/bin/bash

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

: ${BASE_LIB:='rocm'}
: ${VER:=2}

export BASE_LIB VER

SRC=${SRC_DIR}/rocHPL-MxP
cd $SRC

cmake_flags="-DCMAKE_BUILD_TYPE=Release -DHPLMXP_VERBOSE_PRINT=ON"
cmake_flags+=" -DHPLMXP_PROGRESS_REPORT=ON -DHPLMXP_DETAILED_TIMING=ON"

type=cpu
if rocm-smi &> /dev/null; then
    type=amd
    GPU_HOME=/opt/rocm
    export PATH=${GPU_HOME}/bin:${PATH}
    export LD_LIBRARY_PATH=${GPU_HOME}/lib:${LD_LIBRARY_PATH}
    gpu_arch=$(get_gpu_arch $type)
    git checkout main
    cmake_flags+=" -DROCM_PATH=${ROCM_HOME}"
fi
if nvidia-smi &> /dev/null; then
    type=nvidia
    GPU_HOME=/nfs-scratch/sw/cuda/13.1.0_590.44.01
    export PATH=${GPU_HOME}/bin:${PATH}
    export LD_LIBRARY_PATH=${GPU_HOME}/lib64:${LD_LIBRARY_PATH}
    gpu_arch=$(get_gpu_arch $type)
    git checkout cuda_port
    cmake_flags+=" -DCMAKE_CUDA_ARCHITECTURES=${gpu_arch}"
    export NVCC_APPEND_FLAGS="-forward-unknown-to-host-compiler --expt-relaxed-constexpr"
fi

export GPU_HOME
set_paths $type
export HPLMXP_HOME="${HOST_INSTALL}/rocHPL-MxP-${BASE_LIB}"
cmake_flags+=" -DCMAKE_INSTALL_PREFIX=${HPLMXP_HOME} -DHPLMXP_MPI_DIR=${MPI_HOME}"

export CC=mpicc CXX=mpicxx FC=mpifort

BUILD_DIR=/tmp/hplmxp-${BASE_LIB}-${type}
mkcd $BUILD_DIR
echo "--PATH--"
empath $PATH
echo "--LIBRARIES--"
empath $LD_LIBRARY_PATH
echo "cmake $cmake_flags $SRC"
cmake $cmake_flags $SRC
make -j
make -j install
