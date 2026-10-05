#!/bin/bash

#SBATCH -o cn-examples-%j.out
#SBATCH -J cntr-expl-build             # job name
#SBATCH -t 1:00:00

#exit 0

date

action=$1
shift

arch='amd' #'cpu nvidia amd'
#tests=$(ls examples)
tests='hpl hpcg hplmxp'

# This will fail for some (if examples/$t/Dockerfile.$k?)
for k in $arch; do
    for t in $tests; do
        ./${action}.sh $t TYPE=$k $@
    done
done

cp cn-examples-${SLURM_JOB_ID}.out logs/cn-examples-${action}.out
