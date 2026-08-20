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
: ${HPLARGS:=''}
: ${NNODES:=$SLURM_NNODES}
: ${VER:=2}
: ${NPERGPU:=140000}
: ${NBi:=4096}
: ${HFISVC:=1}

export VER

## detect_gpu (called by gpu_run_env) is a no-op if TYPE is already exported
## by the root run.sh dispatcher, so the *-smi probes only ever run once.
## Called early since TYPE feeds OUTFILE's name below.
gpu_run_env

NPROCS=$(( PPN*NNODES ))
rslt_dir=$RESULTS_DIR
mkdir -p $rslt_dir

OUTFILE="$rslt_dir/${NAME}-${TYPE}-${THEDATE}.out"

mpi_args="-np ${NPROCS} --map-by ppr:${PPN}:node --report-bindings"
ctr_args="apptainer exec --bind /lib/modules,${TEST_DIR}/common:/loc_mnt"
ctr_args+="${CTR_GPU_ARGS}"

Ni=$($TEST_DIR/hplmxp_size.py $NPROCS $NPERGPU)
HPLMXARGS="Ni=${Ni} NBi=${NBi}" # ${hplargs}"

set_paths $TYPE
export FI_OPX_HFISVC=$HFISVC

ctr_wrapper='/loc_mnt/hplmxp_run.sh'

exec_tests() {
    echo "========== ++++++ ========="
    echo "------- CONTAINER ----------"
    echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS}"
    mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS}
}

exec_tests | tee -a $OUTFILE

grep Final $OUTFILE

## POST PROC

## OLD CMD
# echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS}" | tee $OUTFILE
# mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS} | tee -a $OUTFILE
