#!/bin/bash

# Training speech synthesis acoustic model (see the trained model in /baseline/exp/models/3_ss_am/) LibriTTS-train-clean-100

# TO CORRECT

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

libritts_corpus=$(realpath $corpora/LibriTTS)

ppg_model=exp/models/1_asr_am/exp
ppg_dir=${ppg_model}/nnet3_cleaned
xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a

am_nsf_train_data="libritts_train_clean_100"
feats_out_dir=$(realpath exp/am_nsf_data)

stage=0

. utils/parse_options.sh

if [ $stage -le 0 ]; then
  local/data_prep_libritts.sh ${libritts_corpus}/train-clean-100 data/${am_nsf_train_data} || exit 1;
  local/run_prepfeats_am_nsf.sh --ppg-model ${ppg_model} --ppg-dir ${ppg_dir} \
	--xvec-nnet-dir ${xvec_nnet_dir} \
	${am_nsf_train_data} ${feats_out_dir} || exit 1;
fi

if [ $stage -le 1 ]; then
  local/vc/am/00_run.sh ${feats_out_dir} || exit 1;
  echo "Model is trained and stored at ${nii_scripts}/acoustic-modeling/project-DAR-continuous/MODELS/DAR_001/"
fi



