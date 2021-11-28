#!/bin/bash

set -e

. ./path.sh
. ./config.sh

for dset in $eval_sets; do
  for suff in $eval_subsets; do
    printf "${GREEN}\n: Downloading ${dset}_${suff} set...${NC}\n"
    local/download_data.sh ${dset}_${suff} || exit 1
  done
done

echo '  Done'
