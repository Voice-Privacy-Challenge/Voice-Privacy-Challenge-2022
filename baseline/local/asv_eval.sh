#!/bin/bash
# Copyright   2017   Johns Hopkins University (Author: Daniel Garcia-Romero)
#             2017   Johns Hopkins University (Author: Daniel Povey)
#        2017-2018   David Snyder
#             2018   Ewald Enzinger
# Apache 2.0.
#
# See ../README.txt for more info on data required.
# Results (mostly equal error-rates) are inline in comments below.

. ./cmd.sh
. ./path.sh
set -e

mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc

nnet_dir=exp/0007_voxceleb_v2_1a/exp/xvector_nnet_1a # Pretrained model downloaded from Kaldi website
plda_dir=${nnet_dir}/xvectors_train

stage=1

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <enroll-dir> <trials-dir>"
  echo "Options"
  echo "   --nnet-dir=     # Directory where xvector extractor is present"
  echo "   --plda-dir=     # Directory where PLDA classifier is present"
  exit 1;
fi

libri_enroll=$1
libri_trials=$2
librispeech_trials_file=data/$libri_trials/trials
libri_male=${librispeech_trials_file}_male
libri_female=${librispeech_trials_file}_female

nj=29
if [ $stage -le 1 ]; then
  echo "Evaluating LibriSpeech trials using pretrained VoXceleb model."

  echo "Compute MFCC..."
  for name in $libri_enroll $libri_trials; do
    steps/make_mfcc.sh --write-utt2num-frames true --mfcc-config conf/mfcc.conf --nj $nj --cmd "$train_cmd" \
      data/${name} exp/make_mfcc $mfccdir
    
    utils/fix_data_dir.sh data/${name}
    
    sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" \
      data/${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh data/${name}
  done

fi

if [ $stage -le 2 ]; then
  echo "Extract xvectors..."
  for name in $libri_enroll $libri_trials; do
    sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 4G" --nj $nj \
      $nnet_dir data/${name} \
      $nnet_dir/xvectors_${name}
  done
fi

if [ $stage -le 3 ]; then
  echo "Scoring the trials..."
  $train_cmd exp/scores/log/librispeech_trial_scoring.log \
    ivector-plda-scoring --normalize-length=true \
    --num-utts=ark:${nnet_dir}/xvectors_${libri_enroll}/num_utts.ark \
    "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
    "ark:ivector-mean ark:data/${libri_enroll}/spk2utt scp:${nnet_dir}/xvectors_${libri_enroll}/xvector.scp ark:- | ivector-subtract-global-mean $plda_dir/mean.vec ark:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$nnet_dir/xvectors_${libri_trials}/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "cat '$librispeech_trials_file' | cut -d\  --fields=1,2 |" exp/scores_libri_trials || exit 1;

  utils/filter_scp.pl $libri_male exp/scores_libri_trials > exp/scores_libri_male
  utils/filter_scp.pl $libri_female exp/scores_libri_trials > exp/scores_libri_female
  pooled_eer=$(paste $librispeech_trials_file exp/scores_libri_trials | awk '{print $6, $3}' | compute-eer - 2>/dev/null)
  male_eer=$(paste $libri_male exp/scores_libri_male | awk '{print $6, $3}' | compute-eer - 2>/dev/null)
  female_eer=$(paste $libri_female exp/scores_libri_female | awk '{print $6, $3}' | compute-eer - 2>/dev/null)
  echo "EER: Pooled ${pooled_eer}%, Male ${male_eer}%, Female ${female_eer}%"
fi

