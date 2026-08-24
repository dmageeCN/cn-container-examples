#!/usr/bin/env bash

# Launch as apptainer:
# ctr_image=image_files/cn-nvidia-parthenon_v2.0.sif
# mpi_args='-np 2 --map-by ppr:${PPN}:node:pe=${OMP_NUM_THREADS} --report-bindings'
# ctr_args="apptainer exec --bind /lib/modules --bind common:/loc_mnt"
# AMD:    ctr_args+=" --rocm"
# NVIDIA: ctr_args+=" --nv --bind /dev/hfi1_gdr,/dev/gdrdrv"
# ctr_wrapper='/loc_mnt/parthenon_run.sh'
# mpirun ${mpi_args} ${ctr_args} ${ctr_image} ${ctr_wrapper} NX=128 NXB=16 NLIM=250 NLVL=3

source /usr/local/bin/cn_env.sh

env | grep PATH

setvar() {
    while [[ $# -gt 0 ]]; do
        export $1
        shift
    done
}

setvar "$@"

: ${NX:=128}
: ${NXB:=16}
: ${NLIM:=250}
: ${NLVL:=3}
: ${OMP_NUM_THREADS:=1}

export OMP_NUM_THREADS

# Set MPI parameters
export OMPI_MCA_mtl=ofi
export OMPI_MCA_pml=cm
export OMPI_MCA_mtl_ofi_provider_include=opx
export FI_PROVIDER=opx

if [[ $GPU == 'amd' ]]; then
    export FI_HMEM_ROCR_USE_DMABUF=1
    export FI_HMEM_ROCR=1
    export ROCR_USE_DMABUF=1

    ## for IPC HANDLE[should enable xgmi on intra node comm]
    export FI_OPX_GPU_IPC_INTRANODE=1
    export FI_HMEM_CUDA_USE_GDRCOPY=1
fi

# # ENABLE HFISVC?
# export FI_OPX_HFISVC=1
if [[ $GPU == 'nvidia' ]]; then
    export FI_HMEM_CUDA=1
    export FI_HMEM_CUDA_USE_DMABUF=1
    export FI_HMEM_CUDA_USE_GDRCOPY=0
fi

NRANK=$OMPI_COMM_WORLD_RANK

PARTHENON_BIN=/usr/local/parthenon/bin/burgers-benchmark
PARTHENON_PIN=/usr/local/parthenon/burgers.pin

## `<block>/<param>=<value>` CLI overrides on top of burgers.pin, per the
## LANL ATS-5 doc's own example invocation. NXB (meshblock size) and NLVL
## (AMR levels) default to the benchmark's canonical/fixed values (16, 3);
## NX (base mesh size per dimension) is the one meant to be varied for
## scaling.
PARG="parthenon/mesh/nx1=${NX} parthenon/mesh/nx2=${NX} parthenon/mesh/nx3=${NX}"
PARG+=" parthenon/meshblock/nx1=${NXB} parthenon/meshblock/nx2=${NXB} parthenon/meshblock/nx3=${NXB}"
PARG+=" parthenon/time/nlim=${NLIM} parthenon/mesh/numlevel=${NLVL}"

if [[ $NRANK == 0 ]]; then
    echo ${PARTHENON_BIN} -i ${PARTHENON_PIN} ${PARG}
fi
${PARTHENON_BIN} -i ${PARTHENON_PIN} ${PARG}
