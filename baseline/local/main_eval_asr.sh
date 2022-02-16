#!/bin/bash

set -e

. ./config.sh


# Recognition with the original ASR_eval^orig
for dset in $eval_sets; do
  for suff in $eval_subsets; do
    for data in ${dset}_${suff}_asr ${dset}_${suff}_asr$anon_data_suffix; do
      printf "${GREEN}\n Performing intelligibility assessment using ASR decoding on $dset...${NC}\n"
      local/asr_eval.sh --nj $nj --dset $data --model $asr_eval_model --results $results.orig || exit 1;
    done
  done
done

# Recognition with the trained ASR_eval^anon
if [ $train_asr_eval ]; then
  asr_eval_model=$asr_eval_model_trained
  echo "The user trained ASR model $asr_eval_model_trained will be used in evaluation"
else
  echo "The pretrained (downloaded) ASR model $asr_eval_model will be used in evaluation"
fi

for dset in $eval_sets; do
  for suff in $eval_subsets; do
    for data in ${dset}_${suff}_asr ${dset}_${suff}_asr$anon_data_suffix; do
      printf "${GREEN}\n Performing intelligibility assessment using ASR decoding on $dset...${NC}\n"
      local/asr_eval.sh --nj $nj --dset $data --model $asr_eval_model --results $results || exit 1;
    done
  done
done

echo '  Done'
