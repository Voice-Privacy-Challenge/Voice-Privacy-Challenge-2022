#!/bin/bash

. path.sh
. cmd.sh

set -e

plda_dir=$1
src_xvectors_dir=$2
pool_xvectors_dir=$3
src_spk=$4
trial_scores=$5

fake_trials_dir=${src_xvectors_dir}/fake_trials
mkdir -p ${fake_trials_dir}
fake_trials=${fake_trials_dir}/trial_${src_spk}

# Creating the fake trials file
cut -d' ' -f 1 ${pool_xvectors_dir}/spk_xvector.scp | awk -v a="${src_spk}" '{print a,$1}'  - > ${fake_trials}

$train_cmd exp/scores/log/libritts_pool_scoring.log \
  ivector-plda-scoring --normalize-length=true \
    "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
    "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:${src_xvectors_dir}/spk_xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:${pool_xvectors_dir}/spk_xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "cat '${fake_trials}' | cut -d\  --fields=1,2 |" ${trial_scores} || exit 1;


