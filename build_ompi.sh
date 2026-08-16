#!/usr/bin/env bash

setvar() {
    while [[ $# -gt 0 ]]; do
        export $1
        shift
    done
}

## FIND THIS DIRECTORY
if [[ -z $ROOT_DIR ]]; then
    THISFILE=${BASH_SOURCE[0]}
    : ${THISFILE:=$0}

    export ROOT_DIR=$(dirname $(realpath ${THISFILE}))
fi

# SET COMMAND LINE OPTIONS
setvar "$@"

: ${OMPI_VER:=5.0.8}
: ${OSUMB_VER:=7.5.2}
: ${TYPE:=cpu}
: ${INSTALL_DIR:=${ROOT_DIR}/install}
: ${CUDA_HOME:=/usr/local/cuda}
: ${ROCM_HOME:=/opt/rocm}
: ${OFI_HOME:=/usr}
: ${SRC_DIR:=${ROOT_DIR}/src/common}
: ${BUILD_DIR:=/tmp/build}
: ${REBUILD:=false}

export CUDA_HOME ROCM_HOME
export INSTALL_DIR+="${ROOT_DIR}/install"

export CC=gcc CXX=g++ FC=gfortran

export CFLAGS="-w"
export CXXFLAGS="-w"
export FCFLAGS="-w"
export LDFLAGS="-Wl,--enable-new-dtags -w"

OMPI_INSTALL="${INSTALL_DIR}/openmpi-${OMPI_VER}-${TYPE}"
OSUMB_INSTALL="${INSTALL_DIR}/osumb_ompi-${OMPI_VER}-${TYPE}"
OMPI_FLAGS="--with-ofi=${OFI_HOME} --prefix=${OMPI_INSTALL} "
OMPI_FLAGS+="--enable-orterun-prefix-by-default "
OMPI_FLAGS+="--with-pmix --without-xpmem "
OMPI_FLAGS+="--enable-mpi1-compatibility"
OSUMB_FLAGS="--prefix=${OSUMB_INSTALL}"

if [[ $TYPE == 'nvidia' ]]; then
    OMPI_FLAGS+=" --with-cuda=${CUDA_HOME}"
    OSUMB_FLAGS+=" --enable-cuda --with-cuda=${CUDA_HOME}"
    export CUDA_STUBS=${CUDA_HOME}/lib64/stubs
    export PATH="${CUDA_HOME}/bin:${PATH}"
    export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
fi

if [[ $TYPE == 'amd' ]]; then
    OMPI_FLAGS+=" --with-rocm=${ROCM_HOME} --enable-rocm"
    OSUMB_FLAGS+=" --with-rocm=${ROCM_HOME} --enable-rocm"
    export PATH="${ROCM_HOME}/bin:${PATH}"
    export LD_LIBRARY_PATH="${ROCM_HOME}/lib:${LD_LIBRARY_PATH}"
fi

if [[ (-d ${OMPI_INSTALL}) ]]; then
    if [[ $REBUILD == true ]]; then
        rm -rf $OMPI_INSTALL ${BUILD_DIR}/ompi-${OMPI_VER}-${TYPE}
    else
        echo "SKIPPING OMPI BUILD ALREADY BUILT ${OMPI_INSTALL}."
    fi
fi

set -e
export PATH="${OFI_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${OFI_HOME}/lib:${LD_LIBRARY_PATH}"

if [[ ! (-d ${OMPI_INSTALL}) ]]; then
    cd ${SRC_DIR}/ompi || exit
    git checkout v${OMPI_VER}
    git clean -ffdx
    ./autogen.pl

    mkdir -p ${BUILD_DIR}/ompi-${OMPI_VER}-${TYPE}
    cd ${BUILD_DIR}/ompi-${OMPI_VER}-${TYPE}

    echo "${SRC_DIR}/ompi/configure $OMPI_FLAGS"
    ${SRC_DIR}/ompi/configure $OMPI_FLAGS 
    make -j 16
    make -j 16 install
fi

export MPI_HOME=${OMPI_INSTALL}
export PATH="${MPI_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_HOME}/lib:${LD_LIBRARY_PATH}"
export CC=mpicc CXX=mpicxx FC=mpifort

if [[ (-d ${OSUMB_INSTALL}) ]]; then
    if [[ $REBUILD == true ]]; then
        rm -rf $OSUMB_INSTALL ${BUILD_DIR}/osumb-build-${OMPI_VER}-${TYPE}
    else
        echo "SKIPPING OSUMB BUILD ALREADY BUILT ${OSUMB_INSTALL}."
    fi
fi

if [[ ! (-d ${OSUMB_INSTALL}) ]]; then
    mkdir -p ${BUILD_DIR}/osumb-build-${OMPI_VER}-${TYPE}
    cd ${BUILD_DIR}/osumb-build-${OMPI_VER}-${TYPE}
    tar xzf osu-micro-benchmarks-${OSUMB_VER}.tar.gz
    OSU_CONFIGURE=./osu-micro-benchmarks-${OSUMB_VER}/configure
    echo "${OSU_CONFIGURE} $OSUMB_FLAGS"
    ${OSU_CONFIGURE} ${OSUMB_FLAGS}
    make -j 16
    make -j 16 install
fi
