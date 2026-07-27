#!/bin/bash

## FIND THIS DIRECTORY
if [[ -z $ROOT_DIR ]]; then
    THISFILE=${BASH_SOURCE[0]}
    : ${THISFILE:=$0}

    export ROOT_DIR=$(dirname $(realpath ${THISFILE}))
fi

source $ROOT_DIR/util

# SET COMMAND LINE OPTIONS
setvar "$@"

: ${RESET_REPO:=false}
# : ${CUDA_VER:=13.1.0_590.44.01}

gitprefix="https://github.com/"
# gitprefix="git@github.com:"
ALL_SRC_DIR=${ROOT_DIR}/src
HPLMXP_URL="${gitprefix}dmageeCN/rocHPL-MxP.git"

# AMD_URL=https://repo.radeon.com/amdgpu-install/7.0.2/el/9.6/amdgpu-install-7.0.2.70002-1.el9.noarch.rpm
AMD_URL=https://repo.radeon.com/amdgpu-install/latest/rhel/9.6/amdgpu-install-7.2.4.70204-1.el9.noarch.rpm

for k in hplmxp branson hpcg gromacs parthenon; do
    mkdir -p ${ALL_SRC_DIR}/${k}
done

cd ${ALL_SRC_DIR}/hplmxp
get_pkgs $AMD_URL $HPLMXP_URL

#SETUP venv
VENV_DIR=${ROOT_DIR}/install/container_venv
if [[ ! (-d $VENV_DIR) ]]; then
    python3 -m venv ${VENV_DIR}
    source ${VENV_DIR}/bin/activate
    python3 -m pip install --upgrade pip
    pip3 install pandas numpy matplotlib ipython
fi