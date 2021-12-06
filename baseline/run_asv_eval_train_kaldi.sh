#!/bin/bash

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#ASV_eval training on LibriSpeech train_clean_360 corpus
nj=20

voxceleb1_trials=data/voxceleb1_test/trials

lrate=01709
epochs=1
shrink=10
egs_dir=exp/xvect_egs

stage=0
train_stage=-1

. ./utils/parse_options.sh

nnet_dir=exp/xvect_${lrate}_${epochs}

if [ $stage -le 0 ]; then
  for name in voxceleb1_test train_clean_360; do
    steps/make_mfcc.sh \
      --write-utt2num-frames true \
      --mfcc-config conf/mfcc.conf \
      --nj $nj --cmd "$train_cmd" \
      data/$name || exit 1
    utils/fix_data_dir.sh data/$name || exit 1
    sid/compute_vad_decision.sh \
      --nj $nj --cmd "$train_cmd" \
      --vad-config conf/vad.conf \
      data/$name || exit 1
    utils/fix_data_dir.sh data/$name || exit 1
  done
fi

# Now we prepare the features to generate examples for xvector training.
if [ $stage -le 1 ]; then
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  local/nnet3/xvector/prepare_feats_for_egs.sh \
    --nj $nj --cmd "$train_cmd" \
    data/train_clean_360 data/train_clean_360_no_sil \
    exp/train_clean_360_no_sil || exit 1
  utils/fix_data_dir.sh data/train_clean_360_no_sil || exit 1
fi

if [ $stage -le 2 ]; then
  # Now, we need to remove features that are too short after removing silence
  # frames.  We want atleast 5s (500 frames) per utterance.
  min_len=400
  mv data/train_clean_360_no_sil/utt2num_frames data/train_clean_360_no_sil/utt2num_frames.bak
  awk -v min_len=${min_len} '$2 > min_len {print $1, $2}' data/train_clean_360_no_sil/utt2num_frames.bak > data/train_clean_360_no_sil/utt2num_frames
  utils/filter_scp.pl data/train_clean_360_no_sil/utt2num_frames data/train_clean_360_no_sil/utt2spk > data/train_clean_360_no_sil/utt2spk.new
  mv data/train_clean_360_no_sil/utt2spk.new data/train_clean_360_no_sil/utt2spk
  utils/fix_data_dir.sh data/train_clean_360_no_sil || exit 1

  # We also want several utterances per speaker. Now we'll throw out speakers
  # with fewer than 8 utterances.
  min_num_utts=8
  awk '{print $1, NF-1}' data/train_clean_360_no_sil/spk2utt > data/train_clean_360_no_sil/spk2num
  awk -v min_num_utts=${min_num_utts} '$2 >= min_num_utts {print $1, $2}' data/train_clean_360_no_sil/spk2num | utils/filter_scp.pl - data/train_clean_360_no_sil/spk2utt > data/train_clean_360_no_sil/spk2utt.new
  mv data/train_clean_360_no_sil/spk2utt.new data/train_clean_360_no_sil/spk2utt
  utils/spk2utt_to_utt2spk.pl data/train_clean_360_no_sil/spk2utt > data/train_clean_360_no_sil/utt2spk

  utils/filter_scp.pl data/train_clean_360_no_sil/utt2spk data/train_clean_360_no_sil/utt2num_frames > data/train_clean_360_no_sil/utt2num_frames.new
  mv data/train_clean_360_no_sil/utt2num_frames.new data/train_clean_360_no_sil/utt2num_frames

  # Now we're ready to create training examples.
  utils/fix_data_dir.sh data/train_clean_360_no_sil || exit 1
fi

# Stages 6 through 8 are handled in run_xvector.sh
if [ $stage -le 8 ]; then
  ./run_xvector.sh \
    --stage $stage --train-stage $train_stage \
    --data data/train_clean_360_no_sil --nnet-dir $nnet_dir \
    --epochs $epochs --shrink $shrink --lrate $lrate --egs-dir $egs_dir || exit 1
fi

if [ $stage -le 9 ]; then
  # Extract x-vectors for centering, LDA, and PLDA training.
  sid/nnet3/xvector/extract_xvectors.sh \
    --cmd "$train_cmd --mem 4G" --nj $nj \
    $nnet_dir data/train_clean_360 \
    $nnet_dir/xvect_train_clean_360 || exit 1
  # Extract x-vectors used in the evaluation.
  sid/nnet3/xvector/extract_xvectors.sh \
    --cmd "$train_cmd --mem 4G" --nj $nj \
    $nnet_dir data/voxceleb1_test \
    $nnet_dir/xvect_voxceleb1_test || exit 1
fi

if [ $stage -le 10 ]; then
  # Compute the mean vector for centering the evaluation xvectors.
  $train_cmd $nnet_dir/xvect_train_clean_360/log/compute_mean.log \
    ivector-mean scp:$nnet_dir/xvect_train_clean_360/xvector.scp \
    $nnet_dir/xvect_train_clean_360/mean.vec || exit 1

  # This script uses LDA to decrease the dimensionality prior to PLDA.
  lda_dim=200
  $train_cmd $nnet_dir/xvect_train_clean_360/log/lda.log \
    ivector-compute-lda --total-covariance-factor=0.0 --dim=$lda_dim \
    "ark:ivector-subtract-global-mean scp:$nnet_dir/xvect_train_clean_360/xvector.scp ark:- |" \
    ark:data/train_clean_360/utt2spk $nnet_dir/xvect_train_clean_360/transform.mat || exit 1

  # Train the PLDA model.
  $train_cmd $nnet_dir/xvect_train_clean_360/log/plda.log \
    ivector-compute-plda ark:data/train_clean_360/spk2utt \
    "ark:ivector-subtract-global-mean scp:$nnet_dir/xvect_train_clean_360/xvector.scp ark:- | transform-vec $nnet_dir/xvect_train_clean_360/transform.mat ark:- ark:- | ivector-normalize-length ark:-  ark:- |" \
    $nnet_dir/xvect_train_clean_360/plda || exit 1
fi

if [ $stage -le 11 ]; then
  $train_cmd $nnet_dir/scores/log/voxceleb1_test_scoring.log \
    ivector-plda-scoring --normalize-length=true \
    "ivector-copy-plda --smoothing=0.0 $nnet_dir/xvect_train_clean_360/plda - |" \
    "ark:ivector-subtract-global-mean $nnet_dir/xvect_train_clean_360/mean.vec scp:$nnet_dir/xvect_voxceleb1_test/xvector.scp ark:- | transform-vec $nnet_dir/xvect_train_clean_360/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "ark:ivector-subtract-global-mean $nnet_dir/xvect_train_clean_360/mean.vec scp:$nnet_dir/xvect_voxceleb1_test/xvector.scp ark:- | transform-vec $nnet_dir/xvect_train_clean_360/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "cat '$voxceleb1_trials' | cut -d\  --fields=1,2 |" $nnet_dir/scores_voxceleb1_test || exit 1
fi

if [ $stage -le 12 ]; then
  eer=`compute-eer <(local/prepare_for_eer.py $voxceleb1_trials $nnet_dir/scores_voxceleb1_test) 2> /dev/null`
  mindcf1=`sid/compute_min_dcf.py --p-target 0.01 $nnet_dir/scores_voxceleb1_test $voxceleb1_trials 2> /dev/null`
  mindcf2=`sid/compute_min_dcf.py --p-target 0.001 $nnet_dir/scores_voxceleb1_test $voxceleb1_trials 2> /dev/null`
  echo "EER: $eer%" | tee $nnet_dir/scores/voxceleb1_test.txt
  echo "minDCF(p-target=0.01): $mindcf1" | tee -a $nnet_dir/scores/voxceleb1_test.txt
  echo "minDCF(p-target=0.001): $mindcf2" | tee -a $nnet_dir/scores/voxceleb1_test.txt

fi

echo Done
