#!/bin/bash
# Download and preparing training data for ASR_eval / ASR_eval_anon  and ASV_eval / ASV_eval_anon

set -e

stage=1

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
	# TODO: download spk data for asv
  done
fi


if [ $stage -le 1 ]; then
  # Prepare data for training evaluation models (train-clean-360) 
  printf "${GREEN}\nStage 1: Preparing data $train for training evaluation models...${NC}\n"
  # TODO: ...
  # format the data as Kaldi data directories
  for part in $train; do
    # use underscore-separated names in data directories.
    #local/data_prep_libri.sh $corpora/LibriSpeech/$part data/$(echo $part | sed s/-/_/g) || exit 1
    local/data_prep_libri.sh $corpora/LibriSpeech/$part data/$part || exit 1
  done
fi


if [[ $data_proc == 'anon' ]] && [[ $stage -le 2 ]]; then
  # Anonymize data for training evaluation models (train-clean-360)
  printf "${GREEN}\nStage 2: Anonymizing data $train for training evaluation models...${NC}\n"
  local/main_anonymization_train_data.sh || exit 1
fi

echo '  Done'
