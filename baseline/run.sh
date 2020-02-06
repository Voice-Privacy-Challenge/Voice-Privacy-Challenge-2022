#!/bin/bash
# Script for The First VoicePrivacy Challenge 2020
#
#
# Copyright (C) 2020  <Brij Mohan Lal Srivastava, Natalia Tomashenko, Xin Wang,...>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#


set -e

. path.sh
. cmd.sh

#===== begin config =======

nj=$(nproc)
stage=0

data_url_librispeech=www.openslr.org/resources/12  # Link to download LibriSpeech corpus
data_url_libritts=www.openslr.org/resources/60     # Link to download LibriTTS corpus

librispeech_corpus=$(realpath corpora/LibriSpeech) # Directory for LibriSpeech corpus 
libritts_corpus=$(realpath corpora/LibriTTS)       # Directory for LibriTTS corpus 

anoni_pool="libritts_train_other_500"
am_nsf_train_data="libritts_train_clean_100"

. parse_options.sh || exit 1;

# Chain model for BN extraction
ppg_model=exp/models/1_asr_am/exp
ppg_dir=${ppg_model}/nnet3_cleaned

# Chain model for ASR evaluation
asr_eval_model=exp/models/asr_eval

# x-vector extraction
xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a
anon_xvec_out_dir=${xvec_nnet_dir}/anon

# ASV_eval config
asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=${asv_eval_model}/xvect_train_clean_360
asv_eval_sets=vctk_dev
[ -d data/vctk_test ] && asv_eval_sets="$asv_eval_sets vctk_test"

# ASR_eval config
asr_eval_sets=vctk_dev_asr
[ -d data/vctk_test_asr ] && asr_eval_sets="$asr_eval_sets vctk_test_asr"

# Anonymization configs
pseudo_xvec_rand_level=spk                # spk (all utterances will have same xvector) or utt (each utterance will have randomly selected xvector)
cross_gender="false"                      # true, same gender xvectors will be selected; false, other gender xvectors
distance="plda"                           # cosine or plda
proximity="farthest"                      # nearest or farthest speaker to be selected for anonymization

eval2_enroll=eval2_enroll
eval2_trial=eval2_trial

anon_data_suffix=_anon_${pseudo_xvec_rand_level}_${cross_gender}_${distance}_${proximity}

#=========== end config ===========

# Download VCTK development set
if [ $stage -le 0 ]; then
  printf "${GREEN}\nStage 0: Downloading LibriSpeech development set...${NC}\n"
  local/download_dev.sh libri '_f _m' || exit 1;
  printf "${GREEN}\nStage 0: Downloading VCTK development set...${NC}\n"
  local/download_dev.sh vctk '_f_mic2 _f_common_mic2 _m_mic2 _m_common_mic2' || exit 1;
fi

# Download pretrained models
if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage 1: Downloading pretrained models...${NC}\n"
  local/download_models.sh || exit 1;
fi
data_netcdf=$(realpath exp/am_nsf_data)   # directory where features for voice anonymization will be stored

# Download LibriSpeech data sets for training anonymization system (train-other-500, train-clean-100) and data sets for training evaluation models ASR_eval and ASV_eval (train-clean-360)
if [ $stage -le 2 ]; then
  printf "${GREEN}\nStage 2: Downloading LibriSpeech data sets for training anonymization system (train-other-500, train-clean-100) and for training evaluation models ASR_eval and ASV_eval (train-clean-360)...${NC}\n"
  for part in train-clean-100 train-other-500 train-clean-360 LibriSpeech; do
    local/download_and_untar.sh corpora $data_url_librispeech $part 
  done
fi

# Download LibriTTS data sets for training anonymization system (train-other-500, train-clean-100)
if [ $stage -le 3 ]; then
  printf "${GREEN}\nStage 3: Downloading LibriTTS data sets fortraining anonymization system (train-other-500, train-clean-100)...${NC}\n"
  for part in train-clean-100 train-other-500; do
    local/download_and_untar.sh corpora $data_url_libritts $part LibriTTS
  done
fi

# Extract xvectors from anonymization pool
if [ $stage -le 4 ]; then
  # Prepare data for libritts-train-other-500
  printf "${GREEN}\nStage 4: Prepare anonymization pool data...${NC}\n"
  local/data_prep_libritts.sh ${libritts_corpus}/train-other-500 data/${anoni_pool} || exit 1;
fi
  
if [ $stage -le 5 ]; then
  printf "${GREEN}\nStage 5: Extracting xvectors for anonymization pool.${NC}\n"
  local/featex/01_extract_xvectors.sh --nj $nj data/${anoni_pool} ${xvec_nnet_dir} \
	  ${anon_xvec_out_dir} || exit 1;
fi

# Make evaluation data
if [ $stage -le 6 ]; then
  printf "${GREEN}\nStage 6: Making evaluation data${NC}\n"
  local/make_eval2.sh proto/eval2 ${librispeech_corpus} ${eval2_enroll} ${eval2_trial} || exit 1;
fi

# Extract xvectors from data which has to be anonymized
if [ $stage -le 7 ]; then
  printf "${GREEN}\nStage 7: Anonymizing eval2 data.${NC}\n"
  for name in $eval2_enroll $eval2_trial; do
    local/anon/anonymize_data_dir.sh --nj $nj --anoni-pool ${anoni_pool} \
	 --data-netcdf ${data_netcdf} \
	 --ppg-model ${ppg_model} --ppg-dir ${ppg_dir} \
	 --xvec-nnet-dir ${xvec_nnet_dir} \
	 --anon-xvec-out-dir ${anon_xvec_out_dir} --plda-dir ${plda_dir} \
	 --pseudo-xvec-rand-level ${pseudo_xvec_rand_level} --distance ${distance} \
	 --proximity ${proximity} \
	 --cross-gender ${cross_gender} --anon-data-suffix ${anon_data_suffix} \
	 ${name} || exit 1;
  done
fi

if [ $stage -le 8 ]; then
  printf "${GREEN}\nStage 8: Evaluate the dataset using speaker verification.${NC}\n"
  printf "${RED}**Exp 0.2 baseline: Eval 2, enroll - original, trial - original**${NC}\n"
  local/asv_eval_libri.sh --nnet-dir ${asv_eval_model} --plda-dir ${plda_dir} \
	  ${eval2_enroll} ${eval2_trial} || exit 1;
  printf "${RED}**Exp 3: Eval 2, enroll - original, trial - anonymized**${NC}\n"
  local/asv_eval_libri.sh --nnet-dir ${asv_eval_model} --plda-dir ${plda_dir} \
	  ${eval2_enroll} ${eval2_trial}${anon_data_suffix} || exit 1;
  printf "${RED}**Exp 4: Eval 2, enroll - anonymized, trial - anonymized**${NC}\n"
  local/asv_eval_libri.sh --nnet-dir ${asv_eval_model} --plda-dir ${plda_dir} \
	  ${eval2_enroll}${anon_data_suffix} ${eval2_trial}${anon_data_suffix} || exit 1;
fi

if [ $stage -le 9 ]; then
  asr_eval_data=${eval2_trial}${anon_data_suffix}
  printf "${GREEN}\nStage 9: Performing intelligibility assessment using ASR decoding on ${asr_eval_data}.${NC}\n"
  printf "${RED}**Exp 0.3 baseline: Eval 2 trial - original, ASR performance**${NC}\n"
  local/asr_eval.sh --nj $nj ${eval2_trial} ${asr_eval_model} || exit 1;
  printf "${RED}**Exp 5: Eval 2, trial - anonymized, ASR performance**${NC}\n"
  local/asr_eval.sh --nj $nj ${asr_eval_data} ${asr_eval_model} || exit 1;
fi

if [ $stage -le 10 ]; then
  for asr_eval_data in $asr_eval_sets; do
    printf "${GREEN}\nStage 10: Performing intelligibility assessment using ASR decoding on ${asr_eval_data}.${NC}\n"
    local/asr_eval.sh --nj $nj ${asr_eval_data} ${asr_eval_model} || exit 1;
  done
fi

if [ $stage -le 11 ]; then
  printf "${GREEN}\nStage 11: Extracting xvectors for ASV evaluation datasets.${NC}\n"
  for dset in $asv_eval_sets; do
    local/featex/01_extract_xvectors.sh \
      --nj $nj data/$dset $asv_eval_model \
      $asv_eval_model || exit 1;
  done
fi

if [ $stage -le 12 ]; then
  printf "${GREEN}\nStage 12: Evaluate datasets using speaker verification.${NC}\n"
  for subset in '_m_common' '_m' '_f_common' '_f'; do
    local/asv_eval.sh \
      --plda_dir $plda_dir \
      --asv_eval_model $asv_eval_model \
      --asv_eval_sets "$asv_eval_sets" \
      --subset $subset --channel '_mic2' || exit 1;
  done
fi

# Not anonymizing train-clean-360 here since it takes enormous amount of time and memory
if [ $stage -le 13 ] && false; then
  printf "${GREEN}\nStage 13: Anonymizing train data for Informed xvector model.${NC}\n"
  local/data_prep_adv.sh ${librispeech_corpus}/train-clean-360 data/train_clean_360 || exit 1;
  local/anon/anonymize_data_dir.sh --nj $nj --stage 0 --anoni-pool ${anoni_pool} \
	 --data-netcdf ${data_netcdf} \
	 --ppg-model ${ppg_model} --ppg-dir ${ppg_dir} \
	 --xvec-nnet-dir ${xvec_nnet_dir} \
	 --anon-xvec-out-dir ${anon_xvec_out_dir} --plda-dir ${plda_dir} \
	 --pseudo-xvec-rand-level ${pseudo_xvec_rand_level} --distance ${distance} \
	 --proximity ${proximity} \
	 --cross-gender ${cross_gender} --anon-data-suffix ${anon_data_suffix} \
	 train_clean_360 || exit 1;
  axvec_train_data=train_clean_360${anon_data_suffix}
fi

echo Done
