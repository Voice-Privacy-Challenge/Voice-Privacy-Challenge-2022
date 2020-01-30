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


. path.sh
. cmd.sh

set -e
export LC_ALL=C

#===== begin config =======
nj=20
stage=0

librispeech_corpus=/PATH_TO/LibriSpeech # LibriSpeech corpus
libritts_corpus=/PATH_TO/LibriTTS       # LibriTTS train-other-500 corpus should be present here
data_netcdf=/PATH_TO/am_nsf_data       # change this to dir where VC features data will be stored

anoni_pool="libritts_train_other_500"
am_nsf_train_data="libritts_train_clean_100"


# Chain model for PPG extraction
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

# Anonymization configs
pseudo_xvec_rand_level=spk                # spk (all utterances will have same xvector) or utt (each utterance will have randomly selected xvector)
cross_gender="false"                      # true, same gender xvectors will be selected; false, other gender xvectors
distance="plda"                           # cosine or plda
proximity="farthest"                      # nearest or farthest speaker to be selected for anonymization

eval2_enroll=eval2_enroll
eval2_trial=eval2_trial

anon_data_suffix=_anon_${pseudo_xvec_rand_level}_${cross_gender}_${distance}_${proximity}

#=========== end config ===========

# Extract xvectors from anonymization pool
if [ $stage -le 0 ]; then
  # Prepare data for libritts-train-other-500
  printf "${GREEN}\nStage 0: Prepare anonymization pool data...${NC}\n"
  local/data_prep_libritts.sh ${libritts_corpus}/train-other-500 data/${anoni_pool}
fi
  
if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage 1: Extracting xvectors for anonymization pool.${NC}\n"
  local/featex/01_extract_xvectors.sh --nj $nj data/${anoni_pool} ${xvec_nnet_dir} \
	  ${anon_xvec_out_dir}
fi

# Make evaluation data
if [ $stage -le 2 ]; then
  printf "${GREEN}\nStage 2: Making evaluation data${NC}\n"
  local/make_eval2.sh proto/eval2 ${librispeech_corpus} ${eval2_enroll} ${eval2_trial}
fi

# Extract xvectors from data which has to be anonymized
if [ $stage -le 3 ]; then
  printf "${GREEN}\nStage 3: Anonymizing eval2 data.${NC}\n"
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

if [ $stage -le 4 ]; then
  printf "${GREEN}\nStage 4: Evaluate the dataset using speaker verification.${NC}\n"
  printf "${RED}**Exp 0.2 baseline: Eval 2, enroll - original, trial - original**${NC}\n"
  local/asv_eval.sh --nnet-dir ${asv_eval_model} --plda-dir ${plda_dir} \
	  ${eval2_enroll} ${eval2_trial} || exit 1;
  printf "${RED}**Exp 3: Eval 2, enroll - original, trial - anonymized**${NC}\n"
  local/asv_eval.sh --nnet-dir ${asv_eval_model} --plda-dir ${plda_dir} \
	  ${eval2_enroll} ${eval2_trial}${anon_data_suffix} || exit 1;
  printf "${RED}**Exp 4: Eval 2, enroll - anonymized, trial - anonymized**${NC}\n"
  local/asv_eval.sh --nnet-dir ${asv_eval_model} --plda-dir ${plda_dir} \
	  ${eval2_enroll}${anon_data_suffix} ${eval2_trial}${anon_data_suffix} || exit 1;
fi

# Not anonymizing train-clean-360 here since it takes enormous amount of time and memory
if [ $stage -le 5 ] && false; then
  printf "${GREEN}\nStage 5: Anonymizing train data for Informed xvector model.${NC}\n"
  local/data_prep_adv.sh ${librispeech_corpus}/train-clean-360 data/train_clean_360
  
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

if [ $stage -le 6 ]; then
  printf "${GREEN}\nStage 6: Anonymizing dev-clean data for intelligibility assessment.${NC}\n"
  local/data_prep_adv.sh ${librispeech_corpus}/dev-clean data/dev_clean
  
  local/anon/anonymize_data_dir.sh --nj $nj --anoni-pool ${anoni_pool} \
	 --data-netcdf ${data_netcdf} \
	 --ppg-model ${ppg_model} --ppg-dir ${ppg_dir} \
	 --xvec-nnet-dir ${xvec_nnet_dir} \
	 --anon-xvec-out-dir ${anon_xvec_out_dir} --plda-dir ${plda_dir} \
	 --pseudo-xvec-rand-level ${pseudo_xvec_rand_level} --distance ${distance} \
	 --proximity ${proximity} \
	 --cross-gender ${cross_gender} --anon-data-suffix ${anon_data_suffix} \
	 dev_clean || exit 1;
fi

if [ $stage -le 7 ]; then
  asr_eval_data=dev_clean${anon_data_suffix}
  printf "${GREEN}\nStage 7: Performing intelligibility assessment using ASR decoding on ${asr_eval_data}.${NC}\n"
  local/asr_eval.sh --nj $nj ${asr_eval_data} ${asr_eval_model}
fi
