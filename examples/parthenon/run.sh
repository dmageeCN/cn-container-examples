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

: ${NNODES:=$SLURM_NNODES}
: ${VER:=0.1}
: ${OMP_NUM_THREADS:=1}
: ${HFISVC:=1}

## Parthenon-VIBE (benchmarks/burgers) sizing knobs, per the LANL ATS-5
## benchmark doc (https://lanl.github.io/benchmarks/03_vibe/vibe.html). NX
## is the base-mesh cell count per dimension (the one thing meant to be
## varied for scaling); NXB (meshblock size, 16) and NLVL (AMR levels, 3)
## are the benchmark's canonical/fixed values -- left overridable here, but
## don't change them if you want results comparable to the official ATS
## numbers. NLIM caps the number of timesteps.
: ${NX:=128}
: ${NXB:=16}
: ${NLIM:=250}
: ${NLVL:=3}

export VER

gpu_run_env
: ${PPN:=$NGPUSYS}

NPROCS=$(( PPN*NNODES ))
rslt_dir=$RESULTS_DIR
mkdir -p $rslt_dir

OUTFILE="$rslt_dir/${NAME}-${TYPE}-${THEDATE}.out"

mpi_args="-np ${NPROCS} --map-by ppr:${PPN}:node:pe=${OMP_NUM_THREADS} --report-bindings"
ctr_args="apptainer exec --bind /lib/modules,${TEST_DIR}/common:/loc_mnt"
ctr_args+="${CTR_GPU_ARGS}"

## Parthenon-level KEY=VALUE args, consumed by the in-container wrapper's
## setvar -- the actual `parthenon/mesh/nx1=...`-style pin-file overrides
## get built from these inside common/parthenon_run.sh.
PARTHARGS="NX=${NX} NXB=${NXB} NLIM=${NLIM} NLVL=${NLVL} OMP_NUM_THREADS=${OMP_NUM_THREADS}"

set_paths $TYPE
export FI_OPX_HFISVC=$HFISVC

ctr_wrapper='/loc_mnt/parthenon_run.sh'

exec_tests() {
    echo "========== ++++++ ========="
    echo "------- CONTAINER ----------"
    echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${PARTHARGS}"
    mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${PARTHARGS}
}

exec_tests |& tee -a $OUTFILE

grep "zone-cycles/wallsecond" $OUTFILE
