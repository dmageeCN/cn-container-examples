#!/usr/bin/env bash

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
: ${OSUMB_VER:=7.5.2}

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
## Associative array: test-name -> space-separated list of source URLs.
## To add a second (or third...) URL for a test, just append with +=" ...".
declare -A URLS
URLS[common]="${gitprefix}open-mpi/ompi.git https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${OSUMB_VER}.tar.gz" ## ?? VERSION?. LIBFABRIC ??
URLS[hplmxp]="${gitprefix}dmageeCN/rocHPL-MxP.git"
URLS[hpl]="${gitprefix}dmageeCN/rocHPL.git"
URLS[branson]="${gitprefix}lanl/branson.git"
URLS[hpcg]="${gitprefix}hpcg-benchmark/hpcg.git" ## ?? GPU ENABLED VERSION.
URLS[hpcg]="${gitprefix}dmageeCN/rocHPCG.git"
URLS[gromacs]="${gitprefix}gromacs/gromacs.git"
URLS[parthenon]="${gitprefix}parthenon-hpc-lab/parthenon.git"

for k in "${!URLS[@]}"; do
    mkdir -p ${ALL_SRC_DIR}/${k}
    cd ${ALL_SRC_DIR}/$k
    get_pkgs ${URLS[$k]} # Intentionally unquoted
done

#SETUP venv
VENV_DIR=${ROOT_DIR}/install/container_venv
if [[ ! (-d $VENV_DIR) ]]; then
    python3 -m venv ${VENV_DIR}
    source ${VENV_DIR}/bin/activate
    python3 -m pip install --upgrade pip
    pip3 install pandas numpy matplotlib ipython
fi