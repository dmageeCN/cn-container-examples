#!/usr/bin/env bash

# Launch as apptainer:
# ctr_image=image_files/cn-nvidia-rocm-hpcg_v2.0.sif
# mpi_args='-np 2 -map-by ppr:${PPN}:node --report-bindings'
# ctr_args="apptainer exec --bind /lib/modules --bind common:/loc_mnt"
# AMD:    ctr_args+=" --rocm"
# NVIDIA: ctr_args+=" --nv --bind /dev/hfi1_gdr,/dev/gdrdrv"
# ctr_wrapper='/loc_mnt/hpcg_run.sh'
# mpirun ${mpi_args} ${ctr_args} ${ctr_image} ${ctr_wrapper}

source /usr/local/bin/cn_env.sh

env | grep PATH

setvar() {
    while [[ $# -gt 0 ]]; do
        export $1
        shift
    done
}

setvar "$@"

: ${NXi:=560}
: ${NYi:=280}
: ${NZi:=280}
: ${RTi:=60}

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
# HIP USE DMABUF?
if [[ $GPU == 'nvidia' ]]; then
    export FI_HMEM_CUDA_USE_DMABUF=1
    export FI_HMEM_CUDA_USE_GDRCOPY=0
fi

NRANK=$OMPI_COMM_WORLD_RANK
## rochpcg takes nx/ny/nz/runtime positionally; unlike rochplmxp there is no
## -P/-Q grid arg -- rank-to-GPU mapping is done internally (comm_rank % ndevs)
## so no --dev= needs to be passed here either.
HPCGARGS="${NXi} ${NYi} ${NZi} ${RTi}"

if [[ $NRANK == 0 ]]; then
    echo /usr/local/rocHPCG/rochpcg $HPCGARGS
fi
/usr/local/rocHPCG/rochpcg $HPCGARGS
