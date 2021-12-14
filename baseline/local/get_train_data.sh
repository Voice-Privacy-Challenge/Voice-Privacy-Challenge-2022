#!/bin/bash
# Download and preparing training data for ASR_eval / ASR_eval_anon  and ASV_eval / ASV_eval_anon

set -e

stage=0

. ./cmd.sh
. ./path.sh
. ./config.sh

nj=10

. utils/parse_options.sh || exit 1

train=$data_to_train_eval_models

if [ $stage -le 0 ]; then
# Download LibriSpeech data sets for training evaluation models (train-clean-360)
  echo "train=$train"
  for part in $train; do
    printf "${GREEN}\nStage 0: Downloading LibriSpeech data set $train for training evaluatio models...${NC}\n"
    local/download_and_untar.sh --remove-archive $corpora $data_url_librispeech $part LibriSpeech || exit 1
  done
fi

if [ $stage -le 1 ]; then
  # Download language model and directory lang
  printf "${GREEN}\nStage 1: Download LM and lang...${NC}\n"
  # TODO: ...
  # local/download_lm.sh || exit 1
fi

if [ $stage -le 2 ]; then
  # Prepare data for training evaluation models (train-clean-360) 
  printf "${GREEN}\nStage 2: Preparing data $train for training evaluation models...${NC}\n"
  # TODO: ...
  # format the data as Kaldi data directories
  for part in $train; do
    # use underscore-separated names in data directories.
    local/data_prep_libri.sh $corpora/LibriSpeech/$part data/$(echo $part | sed s/-/_/g) || exit 1
  done
fi


if [[ $data_proc == 'anon' ]] && [[ $stage -le 3 ]]; then
  # Anonymize data for training evaluation models (train-clean-360)
  printf "${GREEN}\nStage 3: Anonymizing data $train for training evaluation models...${NC}\n"
  # TODO: ...
fi

echo '  Done'
