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

## Prefer SSH (git@github.com:) if the user has a working GitHub SSH key
## registered. `ssh -T git@github.com` never grants a shell, so a
## successfully authenticated key still exits 1 (message: "You've
## successfully authenticated, but GitHub does not provide shell access.");
## a missing/rejected key instead exits 255 ("Permission denied
## (publickey)."). BatchMode=yes disables password/passphrase prompts so
## this check is non-interactive; ConnectTimeout bounds it to a few seconds
## when offline.
if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
    -T git@github.com &> /dev/null; [[ $? -eq 1 ]]; then
    gitprefix="git@github.com:"
else
    gitprefix="https://github.com/"
fi
ALL_SRC_DIR=${ROOT_DIR}/src

## URLS
COMMON_URL="${gitprefix}open-mpi/ompi.git" ## ?? VERSION?. LIBFABRIC ??
HPLMXP_URL="${gitprefix}dmageeCN/rocHPL-MxP.git"
BRANSON_URL="${gitprefix}lanl/branson.git"
HPCG_URL="${gitprefix}hpcg-benchmark/hpcg.git" ## ?? GPU ENABLED VERSION.
GROMACS_URL="${gitprefix}gromacs/gromacs.git"
PARTHENON_URL="${gitprefix}parthenon-hpc-lab/parthenon.git"

for k in common hplmxp branson hpcg gromacs parthenon; do
    mkdir -p ${ALL_SRC_DIR}/${k}
    cd ${ALL_SRC_DIR}/$k
    varname="${k^^}_URL"
    get_pkgs "${!varname}"
done

#SETUP venv
VENV_DIR=${ROOT_DIR}/install/container_venv
if [[ ! (-d $VENV_DIR) ]]; then
    python3 -m venv ${VENV_DIR}
    source ${VENV_DIR}/bin/activate
    python3 -m pip install --upgrade pip
    pip3 install pandas numpy matplotlib ipython
fi