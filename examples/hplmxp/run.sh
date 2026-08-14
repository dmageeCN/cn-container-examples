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

: ${PPN:=8}
: ${HPLARGS:=''}
: ${NNODES:=$SLURM_NNODES}
: ${VER:=2}
: ${NPERGPU:=140000}
: ${NBi:=4096}

export VER

## detect_gpu (called by gpu_run_env) is a no-op if TYPE is already exported
## by the root run.sh dispatcher, so the *-smi probes only ever run once.
## Called early since TYPE feeds OUTFILE's name below.
gpu_run_env

NPROCS=$(( PPN*NNODES ))
rslt_dir=$RESULTS_DIR
mkdir -p $rslt_dir
export THEDATE=$(date +'%m-%d_%H-%M')
OUTFILE="$rslt_dir/${NAME}-${TYPE}-${THEDATE}.out"

mpi_args="-np ${NPROCS} --map-by ppr:${PPN}:node --report-bindings"
mpi_args_2='--mca mtl_ofi_provider_include opx --mca pml cm --mca mtl ofi'
mpi_args_2+=' -x FI_PROVIDER=opx'
ctr_args="apptainer exec --bind /lib/modules,${TEST_DIR}/common:/loc_mnt"
ctr_args+="${CTR_GPU_ARGS}"

hplargs=$(echo ${HPLARGS} | tr ';' ' ')
Pi=$(pq_grid $NPROCS)
Qi=$(( NPROCS/Pi ))

Ni=$($TEST_DIR/hplmxp_size.py $NPROCS $NPERGPU)
HPLMXARGS="-P ${Pi} -Q ${Qi} -N ${Ni} --NB ${NBi} ${hplargs}"

set_paths $TYPE
export HPLMXP_HOME="${HOST_INSTALL}/rocHPL-MxP"
export HOSTEXEC="${HPLMXP_HOME}/run_rochplmxp"

ctr_wrapper='/loc_mnt/hplmxp_run.sh'

exec_tests() {
    echo "FI_OPX_HFISVC=${FI_OPX_HFISVC}"
    echo "========== ++++++ ========="
    echo "------- HOST ----------"
    echo "mpirun ${mpi_args} ${mpi_args_2} ${HOSTEXEC} ${HPLMXARGS}"
    mpirun ${mpi_args} ${mpi_args_2} ${HOSTEXEC} ${HPLMXARGS}
    echo "========== ++++++ ========="
    echo "------- CONTAINER ----------"
    echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS}"
    mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} #${HPLMXARGS}
}

echo "--- __ NO HFISVC" | tee $OUTFILE

exec_tests | tee -a $OUTFILE

echo "--- __ YES HFISVC" | tee -a $OUTFILE

export FI_OPX_HFISVC=1

exec_tests | tee -a $OUTFILE

grep Final $OUTFILE

## POST PROC

## OLD CMD
# echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS}" | tee $OUTFILE
# mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${HPLMXARGS} | tee -a $OUTFILE
