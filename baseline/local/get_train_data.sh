#!/bin/bash
# Download and preparing training data for ASR_eval / ASR_eval_anon  and ASV_eval / ASV_eval_anon

set -e

stage=0

. ./cmd.sh
#. ./path.sh
. ./config.sh

nj=10

. utils/parse_options.sh || exit 1


if [ $stage -le 0 ]; then
# Download LibriSpeech data sets for training evaluation models (train-clean-360)
  echo "train_data=$train_data"
  for part in $train_data; do
    printf "${GREEN}\nStage 0: Downloading LibriSpeech data set $train_data for training anonymization system...${NC}\n"
    local/download_and_untar.sh --remove-archive $corpora $data_url_librispeech $part LibriSpeech || exit 1
  done
fi

if [ $stage -le 1 ]; then
  # Prepare data for training evaluation models (train-clean-360) 
  printf "${GREEN}\nStage 1: Preparing data $train_data for training evaluation models...${NC}\n"
  # TODO: ...
fi

if [[ $data_proc == 'anon' ]] && [[ $stage -le 2 ]]; then
  # Anonymize data for training evaluation models (train-clean-360)
  printf "${GREEN}\nStage 2: Anonymizing data $train_data for training evaluation models...${NC}\n"
  # TODO: ...
fi

echo '  Done'
