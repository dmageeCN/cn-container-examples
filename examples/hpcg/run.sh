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
: ${BASE_LIB:='rocm'}
: ${NNODES:=$SLURM_NNODES}
: ${VER:=2}
: ${Ni:=32000}
: ${NBi:=640}

export BASE_LIB VER

NPROCS=$(( PPN*NNODES ))
rslt_dir=$RESULTS_DIR
mkdir -p $rslt_dir
export THEDATE=$(date +'%m-%d_%H-%M')
OUTFILE="$rslt_dir/${NAME}-${BASE_LIB}-${THEDATE}.out"

mpi_args="-np ${NPROCS} --map-by ppr:${PPN}:node --report-bindings"
mpi_args_2='--mca mtl_ofi_provider_include opx --mca pml cm --mca mtl ofi'
mpi_args_2+=' -x FI_PROVIDER=opx'
ctr_args="apptainer exec --bind /lib/modules,${TEST_DIR}/common:/loc_mnt"

hplargs=$(echo ${HPLARGS} | tr ';' ' ')
Pi=$(pq_grid $NPROCS)
Qi=$(( NPROCS/Pi ))
HPLMXARGS="-P ${Pi} -Q ${Qi} -N ${Ni} --NB ${NBi} ${hplargs}"

type=cpu
if rocm-smi &> /dev/null; then
    ctr_args+=" --rocm"
    type=amd
    GPU_HOME=/opt/rocm
    export LD_LIBRARY_PATH=${GPU_HOME}/lib:${LD_LIBRARY_PATH}
fi
if nvidia-smi &> /dev/null; then
    ctr_args+=" --nv --bind /dev/hfi1_gdr,/dev/gdrdrv"
    type=nvidia
    GPU_HOME=/nfs-scratch/sw/cuda/13.1.0_590.44.01
    export LD_LIBRARY_PATH=${GPU_HOME}/lib64:${LD_LIBRARY_PATH}
fi

export GPU_HOME
set_paths $type
export HPLMXP_HOME="${HOST_INSTALL}/rocHPL-MxP-${BASE_LIB}"
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
