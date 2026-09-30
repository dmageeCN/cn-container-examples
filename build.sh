#!/usr/bin/env bash

## BUILD ALL=
# for k in $(ls examples); do
#     ./build.sh $k
# done

set -eo pipefail

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

: ${VER:=0.1} # VER OF THE EXAMPLE CONTAINERS
: ${CONTAINER_LOC:=remote} # remote (ghcr.io) or local BASE container
: ${VERSION:=latest} # TAG OF THE BASE CONTAINER (cn-<TYPE>:${VERSION})

## Detect the GPU once here and export TYPE so every downstream script
## (this file, examples/<test>/build.sh) reuses it instead of re-running
## the slow *-smi probes.
gpu_build_env

# MAKE IT NAME IN LIST OF ILLEGAL BUILDS.
no_allarch="parthenon"
if [[ ($GPU_PRESENT == 0) && (${no_allarch} =~ $NAME) ]]; then
    echo "SORRY ${NAME} can't be built on a node without ${TYPE} GPUs."
    exit 1
fi

DOCKERFILE=${TEST_DIR}/Dockerfile.${NAME}.${TYPE}
CNTR_NAME=cn-${NAME}-${TYPE}
OUTDIR=${ROOT_DIR}/logs/build_log
mkdir -p $OUTDIR
OUTFILE=${OUTDIR}/${CNTR_NAME}.log

if [[ ! (-f $DOCKERFILE) ]]; then
    echo "NO BUILD AVAILABLE FOR $NAME of type ${TYPE}"
    exit 1
fi

CNTR_TITLE=${CNTR_NAME}:v${VER}

## Pass GPU-architecture overrides through to `docker build` as --build-arg,
## if the user set any of them (e.g. `./build.sh gromacs CUDA_ARCH=90` or
## `./build.sh parthenon NVIDIA_ARCH=AMPERE80`). Every Dockerfile that
## doesn't declare a given ARG just ignores it (Docker prints a harmless
## "not consumed" warning), so it's safe to always check the same whitelist
## regardless of which test/TYPE is being built.
BUILD_ARGS=()
for arch_var in CUDA_ARCH HIP_ARCH NVIDIA_ARCH AMD_ARCH; do
    if [[ -n ${!arch_var} ]]; then
        BUILD_ARGS+=(--build-arg ${arch_var}=${!arch_var})
    fi
done

case $CONTAINER_LOC in
    remote )
        BUILD_ARGS+=(--build-arg BASE_REGISTRY=ghcr.io/dmageecn/)
        ;;
    local )
        BUILD_ARGS+=(--build-arg BASE_REGISTRY=)
        ;;
    * )
        echo "ERROR: unknown CONTAINER_LOC=${CONTAINER_LOC} (expected remote or local)." >&2
        exit 1
        ;;
esac
BUILD_ARGS+=(--build-arg BASE_VERSION=${VERSION})

si=${SECONDS}

docker build -t ${CNTR_TITLE} -f $DOCKERFILE "${BUILD_ARGS[@]}" --progress=plain . |& tee $OUTFILE

# if [ $? -ne 0 ]; then
#     exit 1
# fi

apptainer_build $CNTR_TITLE

sf=$(( SECONDS-si ))

echo "Took ${sf} seconds to build $CNTR_TITLE"
echo "APPTAINER sif: $CNTR_TITLE"
