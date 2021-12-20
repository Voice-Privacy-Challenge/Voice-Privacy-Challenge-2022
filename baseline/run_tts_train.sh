#!/bin/bash
#Training TTS models on $data_train_tts data (in the baseline: LibriTTS-train-clean-100)

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

nj=20
stage=0

. ./utils/parse_options.sh

data=$data_train_tts
#Directory to save prepared data (x-vectors, BN, pitch, ...) for training TTS model 
data_out=data/$data_train_tts_out 

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


if [ $stage -le 5 ]; then
  printf "${GREEN}\nStage 5: Make netcdf data (${data}) for VC...${NC}\n"
  local/anon/make_netcdf.sh --stage 0 data/${data} ${ppg_dir}/ppg_${data}/phone_post.scp \
	  ${xvec_out_dir}/xvectors_${data}/xvector.scp \
	  ${data_out}/${data} || exit 1
fi


if [ $stage -le 6 ]; then
    printf "${GREEN}\nStage 6: prepare waveform data for TTS training...${NC}\n"
    local/featex/04_create_wav_downsample_norm.sh --nj $nj data/${data}/wav.scp \
	  ${data_out}/${data}/wav_tts ${tts_sampling_rate} || exit 1
fi


if [ $stage -le 7 ]; then
    printf "${GREEN}\nStage 7: extract mel-spectrogram for TTS AM training${NC}\n"
    local/featex/05_extract_mel_for_am.sh --nj $nj data/${data}/wav.scp \
	  ${data_out}/${data}/wav_tts ${data_out}/${data}/mel || exit 1
fi


if [ $stage -le 8 ]; then
  printf "${GREEN}\nStage 8: Training TTS models...${NC}\n"
  local/train_tts_model.sh --nj $nj --stage 0 \
	  --model-type ${tts_type} --data-dir ${data_out}/${data} || exit 1
fi

echo Done
