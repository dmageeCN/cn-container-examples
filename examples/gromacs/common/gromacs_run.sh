#!/usr/bin/env bash
# Launch as apptainer:
# ctr_image=image_files/cn-nvidia-gromacs_v2.0.sif
# mpi_args='-np 2 --map-by ppr:${PPN}:node:pe=${OMP_NUM_THREADS} --report-bindings'
# ctr_args="apptainer exec --bind /lib/modules --bind common:/loc_mnt"
# AMD:    ctr_args+=" --rocm"
# NVIDIA: ctr_args+=" --nv --bind /dev/hfi1_gdr,/dev/gdrdrv"
# ctr_wrapper='/loc_mnt/gromacs_run.sh'
# mpirun ${mpi_args} ${ctr_args} ${ctr_image} ${ctr_wrapper} TPR=... OMP_NUM_THREADS=...

source /usr/local/bin/cn_env.sh

#env | grep PATH

setvar() {
    while [[ $# -gt 0 ]]; do
        export $1
        shift
    done
}

setvar "$@"

: ${TPR:=/loc_mnt/REPLACE_WITH_TPR_PATH.tpr}
: ${OMP_NUM_THREADS:=1}

source /usr/local/gromacs/bin/GMXRC.bash

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
    export FI_HMEM_CUDA_USE_DMABUF=1
    export FI_HMEM_CUDA_USE_GDRCOPY=0

    ## From NVIDIA's own GROMACS multi-node scaling guidance -- only
    ## verified/recommended on CUDA, left unset on HIP.
    export GMX_ENABLE_DIRECT_GPU_COMM=1
    export GMX_GPU_PME_DECOMPOSITION=1
fi

NRANK=$OMPI_COMM_WORLD_RANK

GMX_OPTS="-ntomp ${OMP_NUM_THREADS} -noconfout -dlb no -pin off -nstlist 300"

## GPU is set by cn_env.sh based on what's actually present in this image
## (nvidia/amd/none) -- only offload PME/bonded/update to the GPU when one
## is actually available; a CPU-only container has nothing to offload to.
if [[ $GPU == 'nvidia' || $GPU == 'amd' ]]; then
    GMX_OPTS="${GMX_OPTS} -pme gpu -bonded gpu -update gpu"
fi

if [[ $NRANK == 0 ]]; then
    echo gmx_mpi mdrun -v -s $TPR $GMX_OPTS
fi
gmx_mpi mdrun -v -s $TPR $GMX_OPTS
