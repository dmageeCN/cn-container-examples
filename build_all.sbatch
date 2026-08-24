#!/bin/bash

#SBATCH -o cn-examples-%j.out
#SBATCH -J cntr-expl-bld             # job name
#SBATCH -t 3:00:00

#exit 0

date 

arch='cpu nvidia amd'
tests=$(ls examples)

# This will fail for some (Parthenon when the arch is mismatched)
for k in $arch; do
    for t in $tests; do
        ./build.sh $t TYPE=$k
    done
done