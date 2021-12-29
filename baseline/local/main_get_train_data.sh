#!/bin/bash
# Download and preparing training data for evaluation models ASR_eval / ASR_eval_anon  and ASV_eval / ASV_eval_anon

set -e

stage=0

. ./cmd.sh
. ./path.sh
. ./config.sh

nj=10

. utils/parse_options.sh || exit 1

train=$data_to_train_eval_models
train_asv=$data_to_train_eval_models-asv


if [ $stage -le 0 ]; then
# Download LibriSpeech data sets for training evaluation models (train-clean-360)
  echo "train=$train"
  for part in $train; do
    printf "${GREEN}Downloading LibriSpeech data set $train for training evaluatio models...${NC}\n"
    local/download_and_untar.sh --remove-archive $corpora $data_url_librispeech $part LibriSpeech || exit 1
  done
  # lang directory link for ASR
  if [ -d "data/lang" ]; then
    echo "data/lang already exists"
  else
    ln -s ../exp/models/asr_eval/lang data/lang || exit 1
  fi	
fi


if [ $stage -le 1 ]; then
  # Prepare data for training evaluation models (train-clean-360): spk2utt with session-speaker ids
  printf "${GREEN}Preparing data $train for training evaluation models...${NC}\n"
  # TODO: ...
  # format the data as Kaldi data directories
  for part in $train; do
    # use underscore-separated names in data directories.
    #local/data_prep_libri.sh $corpora/LibriSpeech/$part data/$(echo $part | sed s/-/_/g) || exit 1
    local/data_prep_libri.sh $corpora/LibriSpeech/$part data/$part || exit 1
  done
fi


if [ $stage -le -2 ]; then
# Prepare data for training ASV evaluation model:  spk2utt with real speaker ids
  utils/copy_data_dir.sh data/$data_to_train_eval_models data/$train_asv || exit 1
  cp data/$data_to_train_eval_models-spk/utt2spk data/$train_asv
  utils/utt2spk_to_spk2utt.pl data/$train_asv/utt2spk > data/$train_asv/spk2utt || exit 1
  cp data/$data_to_train_eval_models-spk/spk2gender data/$train_asv 
  rm data/$train_asv/cmvn.scp
  utils/fix_data_dir.sh data/$train_asv || exit 1
  utils/validate_data_dir.sh data/$train_asv || exit 1
fi

echo '  Done'
