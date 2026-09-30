#!/usr/bin/env bash

# Launch as apptainer:
# ctr_image=image_files/cn-nvidia-branson_v2.0.sif
# mpi_args='-np 2 --map-by ppr:${PPN}:node:pe=${OMP_NUM_THREADS} --report-bindings'
# ctr_args="apptainer exec --bind /lib/modules --bind common:/loc_mnt"
# AMD:    ctr_args+=" --rocm"
# NVIDIA: ctr_args+=" --nv --bind /dev/hfi1_gdr,/dev/gdrdrv"
# ctr_wrapper='/loc_mnt/branson_run.sh'
# mpirun ${mpi_args} ${ctr_args} ${ctr_image} ${ctr_wrapper} INPUT=3D_hohlraum_multi_node.xml PHOTONS=250000000

source /usr/local/bin/cn_env.sh

#env | grep PATH

setvar() {
    while [[ $# -gt 0 ]]; do
        export $1
        shift
    done
}

setvar "$@"

: ${INPUT:=3D_hohlraum_multi_node.xml}
: ${PHOTONS:=250000000}
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

BRANSON_BIN=/usr/local/branson/bin/BRANSON
BRANSON_INPUT=/usr/local/branson/inputs/${INPUT}

## Branson's own --key value (or --key=value) CLI mechanism overrides any
## tag inside the input deck's <common> block -- --photons is the primary
## scaling knob, --n_omp_threads wires up Kokkos-style host threading.
BARGS="--photons ${PHOTONS} --n_omp_threads ${OMP_NUM_THREADS}"

if [[ $NRANK == 0 ]]; then
    echo ${BRANSON_BIN} ${BRANSON_INPUT} ${BARGS}
fi
${BRANSON_BIN} ${BRANSON_INPUT} ${BARGS}
