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
: ${VER:=2}
: ${OMP_NUM_THREADS:=1}
: ${HFISVC:=1}

## Branson (LANL IMC thermal radiative transport proxy app) sizing knobs.
## INPUT selects which shipped inputs/*.xml deck to run -- the multi-node
## deck uses PARTICLE_PASS domain decomposition and is meant for
## multi-rank/multi-node scaling runs (see the repo's README "Running
## Branson on performance problems" section). PHOTONS is the deck's own
## <photons> tag, overridden here via Branson's --key value CLI mechanism,
## and is the primary scaling knob. 
: ${INPUT:=3D_hohlraum_multi_node.xml}
: ${PHOTONS:=250M} #Use M for million, B for billion and k for thousand.

th='000'
PHOTONS=${PHOTONS//k/"${th}"}
PHOTONS=${PHOTONS//M/"${th}${th}"}
PHOTONS=${PHOTONS//B/"${th}${th}${th}"}

export VER

## detect_gpu (called by gpu_run_env) is a no-op if TYPE is already exported
## by the root run.sh dispatcher, so the *-smi probes only ever run once.
## Called early since TYPE feeds OUTFILE's name below.
gpu_run_env
: ${PPN:=$NGPUSYS}


NPROCS=$(( PPN*NNODES ))
rslt_dir=$RESULTS_DIR
mkdir -p $rslt_dir

OUTFILE="$rslt_dir/${NAME}-${TYPE}-${THEDATE}.out"

mpi_args="-np ${NPROCS} --map-by ppr:${PPN}:node:pe=${OMP_NUM_THREADS} --report-bindings"
ctr_args="apptainer exec --bind /lib/modules,${TEST_DIR}/common:/loc_mnt"
ctr_args+="${CTR_GPU_ARGS}"

## Branson-level KEY=VALUE args, consumed by the in-container wrapper's
## setvar -- the actual `BRANSON <input> --photons ...`-style CLI gets
## built from these inside common/branson_run.sh.
BRANSONARGS="INPUT=${INPUT} PHOTONS=${PHOTONS} OMP_NUM_THREADS=${OMP_NUM_THREADS}"

set_paths $TYPE
export FI_OPX_HFISVC=$HFISVC

ctr_wrapper='/loc_mnt/branson_run.sh'

exec_tests() {
    echo "========== ++++++ ========="
    echo "------- CONTAINER ----------"
    echo "mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${BRANSONARGS}"
    mpirun ${mpi_args} ${ctr_args} ${CTR_IMAGE} ${ctr_wrapper} ${BRANSONARGS}
}

exec_tests | tee -a $OUTFILE

grep "Photons Per Second (FOM)" $OUTFILE
