#!/bin/bash

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#Training TTS models on LibriTTS train_clean_100 corpus (data_train_tts)

nj=20
stage=1

. ./utils/parse_options.sh

train=$data_train_tts
libritts_corpus=$(realpath $corpora/LibriTTS)
train_tts=train_tts
xvec_out_dir=${xvec_nnet_dir}/$train_tts
ppg_dir=${ppg_model}/nnet3_cleaned

# (LibriTTS-clean-100 is downloaded in run.sh, this stage can be skipped)
if [ $stage -le 0 ]; then
  printf "${GREEN}\nStage 0: Downloading LibriTTS data sets for training TTS models...${NC}\n"
  for part in $data_train_tts; do
    echo $data_url_libritts
    local/download_and_untar.sh $corpora $data_url_libritts $part LibriTTS || exit 1
done
fi


if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage 1: Prepare LibriTTS data $data_train_tts...${NC}\n"
  local/data_prep_libritts.sh ${libritts_corpus}/${data_train_tts} data/${train_tts} || exit 1
fi


if [ $stage -le 3 ]; then
  printf "${RED}\nStage 3: Extracting x-vectors for $data/${train_tts}...${NC}\n"
  local/featex/01_extract_xvectors.sh --nj $nj data/${train_tts} ${xvec_nnet_dir} \
	  ${xvec_out_dir} || exit 1
fi


if [ $stage -le 4 ]; then
  printf "${RED}\nStage 4: Pitch extraction for $data/${train_tts}...${NC}\n"
  local/featex/02_extract_pitch.sh --nj $nj data/${train_tts} || exit 1
fi


if [ $stage -le 5 ]; then
  printf "${RED}\nStage 5: BN-feature extraction for $data/${train_tts}...${NC}\n"
  local/featex/extract_ppg.sh --nj $nj --stage 0 \
	  ${train_tts} ${ppg_model} ${ppg_dir}/ppg_${train_tts} || exit 1
fi


#TODO: add script to train TTS models train_tts_model.sh 
if [ $stage -le 6 ]; then
  printf "${RED}\nStage 6: Training TTS models}...${NC}\n"
  local/train_tts_model.sh || exit 1
fi

echo Done
