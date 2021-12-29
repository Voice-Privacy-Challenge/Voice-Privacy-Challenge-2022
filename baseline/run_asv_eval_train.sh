#!/bin/bash
#ASV_eval training on LibriSpeech train_clean_360 corpus

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

nj=20

lrate=01709  
epochs=1
shrink=10
egs_dir=exp/xvect_egs

stage=11
train_stage=-1

. ./utils/parse_options.sh

train=$data_to_train_eval_models-asv  

if [[ $data_proc == 'anon' ]]; then
  printf "${GREEN} Training evaluation models on anonymized data...${NC}\n"
  train=$train$anon_data_suffix
else
  printf "${GREEN} Training evaluation models on original data...${NC}\n"
fi
nnet_dir=$asv_eval_model_trained    #asv_eval_model_trained=exp/models/user_asv_eval_${data_proc}

if [ $stage -le 0 ]; then
  for name in $train; do
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
    data/$train data/${train}_no_sil \
    exp/${train}_no_sil || exit 1
  utils/fix_data_dir.sh data/${train}_no_sil || exit 1
fi

if [ $stage -le 2 ]; then
  # Now, we need to remove features that are too short after removing silence
  # frames.  We want atleast 5s (500 frames) per utterance.
  min_len=400
  mv data/${train}_no_sil/utt2num_frames data/${train}_no_sil/utt2num_frames.bak
  awk -v min_len=${min_len} '$2 > min_len {print $1, $2}' data/${train}_no_sil/utt2num_frames.bak > data/${train}_no_sil/utt2num_frames
  utils/filter_scp.pl data/${train}_no_sil/utt2num_frames data/${train}_no_sil/utt2spk > data/${train}_no_sil/utt2spk.new
  mv data/${train}_no_sil/utt2spk.new data/${train}_no_sil/utt2spk
  utils/fix_data_dir.sh data/${train}_no_sil || exit 1

  # We also want several utterances per speaker. Now we'll throw out speakers
  # with fewer than 8 utterances.
  min_num_utts=8
  awk '{print $1, NF-1}' data/${train}_no_sil/spk2utt > data/${train}_no_sil/spk2num
  awk -v min_num_utts=${min_num_utts} '$2 >= min_num_utts {print $1, $2}' data/${train}_no_sil/spk2num | utils/filter_scp.pl - data/${train}_no_sil/spk2utt > data/${train}_no_sil/spk2utt.new
  mv data/${train}_no_sil/spk2utt.new data/${train}_no_sil/spk2utt
  utils/spk2utt_to_utt2spk.pl data/${train}_no_sil/spk2utt > data/${train}_no_sil/utt2spk

  utils/filter_scp.pl data/${train}_no_sil/utt2spk data/${train}_no_sil/utt2num_frames > data/${train}_no_sil/utt2num_frames.new
  mv data/${train}_no_sil/utt2num_frames.new data/${train}_no_sil/utt2num_frames

  # Now we're ready to create training examples.
  utils/fix_data_dir.sh data/${train}_no_sil || exit 1
fi

# Stages 6 through 8 are handled in run_xvector.sh
if [ $stage -le 8 ]; then
  ./run_xvector.sh \
    --stage $stage --train-stage $train_stage \
    --data data/${train}_no_sil --nnet-dir $nnet_dir \
    --epochs $epochs --shrink $shrink --lrate $lrate --egs-dir $egs_dir || exit 1
fi

if [ $stage -le 9 ]; then
  # Extract x-vectors for centering, LDA, and PLDA training.
  sid/nnet3/xvector/extract_xvectors.sh \
    --cmd "$train_cmd --mem 4G" --nj $nj \
    $nnet_dir data/$train \
    $nnet_dir/xvect_$train || exit 1
fi

if [ $stage -le 10 ]; then
  # Compute the mean vector for centering the evaluation xvectors.
  $train_cmd $nnet_dir/xvect_${train}/log/compute_mean.log \
    ivector-mean scp:$nnet_dir/xvect_${train}/xvector.scp \
    $nnet_dir/xvect_$train/mean.vec || exit 1

  # This script uses LDA to decrease the dimensionality prior to PLDA.
  lda_dim=200
  $train_cmd $nnet_dir/xvect_$train/log/lda.log \
    ivector-compute-lda --total-covariance-factor=0.0 --dim=$lda_dim \
    "ark:ivector-subtract-global-mean scp:$nnet_dir/xvect_${train}/xvector.scp ark:- |" \
    ark:data/$train/utt2spk $nnet_dir/xvect_$train/transform.mat || exit 1

  # Train the PLDA model.
  $train_cmd $nnet_dir/xvect_$train/log/plda.log \
    ivector-compute-plda ark:data/$train/spk2utt \
    "ark:ivector-subtract-global-mean scp:$nnet_dir/xvect_$train/xvector.scp ark:- | transform-vec $nnet_dir/xvect_$train/transform.mat ark:- ark:- | ivector-normalize-length ark:-  ark:- |" \
    $nnet_dir/xvect_$train/plda || exit 1
fi

if [ $stage -le 11 ]; then
  printf "${GREEN}\n Coping the final model/links to the user directory...${NC}\n"
  if [ -f "$nnet_dir/plda" ]; then
    echo "$nnet_dir/plda already exists"
  else
    cd $nnet_dir
    ln -s xvect_$train/plda plda
	ln -s xvect_$train/mean.vec mean.vec
    ln -s xvect_$train/transform.mat transform.mat
	cd ../../..
  fi
fi

echo Done
