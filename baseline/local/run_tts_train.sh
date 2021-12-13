#!/bin/bash
#Training TTS models on $data_train_tts data (in the baseline: LibriTTS-train-clean-100)

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

nj=20
stage=1

. ./utils/parse_options.sh

data=$data_train_tts
data_out=data/${data_train_tts}_tts #Directory to save prepared data (x-vectors, BN, pitch, ...) for training TTS model 

libritts_corpus=$(realpath $corpora/LibriTTS)
xvec_out_dir=${xvec_nnet_dir}/$data
ppg_dir=${ppg_model}/nnet3_cleaned

# (LibriTTS-clean-100 is downloaded in run.sh, thus this stage can be skipped)
if [ $stage -le 0 ]; then
  printf "${GREEN}\nStage 0: Downloading LibriTTS data sets for training TTS models...${NC}\n"
  for part in $data; do
  echo $data_url_libritts
  local/download_and_untar.sh $corpora $data_url_libritts $part LibriTTS || exit 1
done
fi


if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage 1: Prepare LibriTTS data ${data_train_tts}...${NC}\n"
  local/data_prep_libritts.sh ${libritts_corpus}/${data} data/${data} || exit 1
fi

#TODO: add sidekit option
if [ $stage -le 2 ]; then
  printf "${GREEN}\nStage 2: Extracting x-vectors for data/${data}...${NC}\n"
  local/featex/01_extract_xvectors.sh --nj $nj data/${data} ${xvec_nnet_dir} \
	  ${xvec_out_dir} || exit 1
fi


if [ $stage -le 3 ]; then
  printf "${GREEN}\nStage 3: Pitch extraction for data/${data}...${NC}\n"
  local/featex/02_extract_pitch.sh --nj $nj data/${data} || exit 1
fi


if [ $stage -le 4 ]; then
  printf "${GREEN}\nStage 4: BN-feature extraction for data/${data}...${NC}\n"
  local/featex/extract_ppg.sh --nj $nj --stage 0 \
	  ${data} ${ppg_model} ${ppg_dir}/ppg_${data} || exit 1
fi

#TODO: add mel spectrograms
if [ $stage -le 5 ]; then
  printf "${GREEN}\nStage 5: Make netcdf data (${data}) for VC...${NC}\n"
  local/anon/make_netcdf.sh --stage 0 data/${data} ${ppg_dir}/ppg_${data}/phone_post.scp \
	  ${xvec_out_dir}/xvectors_${data}/xvector.scp \
	  ${data_netcdf}/${data} || exit 1
fi


#TODO: add script to train TTS models train_tts_model.sh 
if [ $stage -le 6 ]; then
  printf "${GREEN}\nStage 6: Training TTS models...${NC}\n"
  local/train_tts_model.sh || exit 1
fi

echo Done
