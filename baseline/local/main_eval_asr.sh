#!/bin/bash

set -e

. ./path.sh
. ./config.sh

for dset in $eval_sets; do
  for suff in $eval_subsets; do
    for data in ${dset}_${suff}_asr ${dset}_${suff}_asr$anon_data_suffix; do
      printf "${GREEN}\n Performing intelligibility assessment using ASR decoding on $dset...${NC}\n"
      local/asr_eval.sh --nj $nj --dset $data --model $asr_eval_model --results $results || exit 1;
    done
  done
done

echo '  Done'
