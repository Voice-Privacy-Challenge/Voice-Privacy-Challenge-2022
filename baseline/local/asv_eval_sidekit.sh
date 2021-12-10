#!/bin/bash

set -e

. ./cmd.sh
. ./path.sh

plda_dir=
asv_eval_model=exp/models/asv_eval/sidekit_model

enrolls=libri_dev_enrolls
trials=libri_dev_trials_f

printf -v results '%(%Y-%m-%d-%H-%M-%S)T' -1
results=exp/results-$results

. ./utils/parse_options.sh

sidekit_xvector_model=$asv_eval_model/sidekit_model_asv.pt

for dset in $enrolls $trials; do
  extract_xvectors.py \
              --vad \
              --model $sidekit_xvector_model \
              --wav-scp data/$dset/wav.scp \
              --out-scp $asv_eval_model/xvect_$dset/x_vector_$dset.scp || exit 1
done

expo=$results/ASV-$enrolls-$trials
compute_spk_cosine.py \
          data/$trials/trials \
          data/$enrolls/utt2spk \
          $asv_eval_model/xvect_$trials/x_vector_$trials.scp \
          $asv_eval_model/xvect_$enrolls/x_vector_$enrolls.scp \
          $results/cosine_score_$enrolls.txt || exit 1

compute_metrics.py \
  -k data/$trials/trials \
  -s $results/cosine_score_$enrolls.txt > $expo || exit 1