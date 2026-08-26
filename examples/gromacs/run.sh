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

if [[ -z $UTIL_SOURCED ]]; then
    source $ROOT_DIR/util
    setvar "$@"
fi

: ${PPN:=8}
: ${NNODES:=$SLURM_NNODES}
: ${VER:=2}
: ${OMP_NUM_THREADS:=1}
: ${GMXARGS:=''}
: ${HFISVC:=1}

## Placeholder: the actual benchmark .tpr file(s) aren't checked into this
## repo yet (see AGENTS/sessions.md). Point TPR at wherever you've dropped
## your own .tpr, either on the host (bind-mounted under ${TEST_DIR}/common,
## which is already mounted at /loc_mnt) or elsewhere in the container.
: ${TPR:=/loc_mnt/REPLACE_WITH_TPR_PATH.tpr}

export VER

## detect_gpu (called by gpu_run_env) is a no-op if TYPE is already exported
## by the root run.sh dispatcher, so the *-smi probes only ever run once.
## Called early since TYPE feeds OUTFILE's name below.
gpu_run_env

NPROCS=$(( PPN*NNODES ))
rslt_dir=$RESULTS_DIR
mkdir -p $rslt_dir

OUTFILE="$rslt_dir/${NAME}-${TYPE}-${THEDATE}.out"

mpi_args="-np ${NPROCS} --map-by ppr:${PPN}:node:pe=${OMP_NUM_THREADS} --report-bindings"
ctr_args="apptainer exec --bind /lib/modules,${TEST_DIR}/common:/loc_mnt"
ctr_args+="${CTR_GPU_ARGS}"

## GMX-level KEY=VALUE args, consumed by the in-container wrapper's setvar.
## TPR is the only thing you're likely to need to override right now.
GMXARGS="TPR=${TPR} OMP_NUM_THREADS=${OMP_NUM_THREADS} ${GMXARGS}"

set_paths $TYPE
export FI_OPX_HFISVC=$HFISVC

ctr_wrapper='/loc_mnt/gromacs_run.sh'

exec_tests() {
    echo "========== ++++++ ========="
    echo "------- CONTAINER ----------"
    echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${GMXARGS}"
    mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${GMXARGS}
}

exec_tests | tee -a $OUTFILE

grep Performance: $OUTFILE
