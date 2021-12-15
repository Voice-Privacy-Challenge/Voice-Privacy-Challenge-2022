#!/bin/bash

set -e

. ./cmd.sh
. ./path.sh
. ./config.sh

asv_eval_model=
plda_dir=

enrolls=libri_dev_enrolls
trials=libri_dev_trials_f

. ./utils/parse_options.sh

sidekit_xvector_model=$asv_eval_model/sidekit_model_asv.pt

for dset in $enrolls $trials; do
  out_dir=$asv_eval_model/xvect_$dset
  mkdir -p $out_dir
  extract_xvectors.py \
              --vad \
              --model $sidekit_xvector_model \
              --wav-scp data/$dset/wav.scp \
              --out-scp $out_dir/x_vector_$dset.scp || exit 1
done

expo=$results/ASV-$enrolls-$trials
scores_dir=$expo/scores
mkdir -p $expo
mkdir -p $scores_dir
compute_spk_cosine.py \
          data/$trials/trials \
          data/$enrolls/utt2spk \
          $asv_eval_model/xvect_$trials/x_vector_$trials.scp \
          $asv_eval_model/xvect_$enrolls/x_vector_$enrolls.scp \
          $scores_dir/cosine_score_$enrolls.txt || exit 1

compute_metrics.py \
  -k data/$trials/trials \
  -s $scores_dir/cosine_score_$enrolls.txt > $expo/results.txt || exit 1