#!/bin/bash

. path.sh
. cmd.sh

set -e

#===== begin config =======
nj=40
stage=0

# Original data in ./data folder which will be splitted into train, dev and test based on speakers
am_nsf_train_data=libritts_train_clean_100 # change this to your actual data

# Chain model for PPG extraction
ivec_extractor=exp/nnet3_cleaned/extractor # change this to the ivector extractor trained by chain models
ivec_data_dir=exp/nnet3_cleaned # change this to the directory where ivectors will stored for your data

tree_dir=exp/chain_cleaned/tree_sp # change this to tree dir of your chain model
model_dir=exp/chain_cleaned/tdnn_1d_sp # change this to your pretrained chain model
lang_dir=data/lang_chain # change this to the land dir of your chain model

ppg_dir=exp/nnet3_cleaned # change this to the dir where PPGs will be stored

# Mel spectrogram config
am_nsf_melspec_dir=data/${train_data}_mspec
am_nsf_melspec_file=${melspec_dir}/feats.scp

# Split data
am_nsf_dev_spks=20
am_nsf_test_spks=20
am_nsf_split_dir=data/am_nsf

# x-vector extraction
am_nsf_train_split=${train_data}_train
am_nsf_dev_split=${train_data}_dev
am_nsf_test_split=${train_data}_test
am_nsf_split_data="${train_split} ${dev_split} ${test_split}"

xvec_nnet_dir=exp/0007_voxceleb_v2_1a/exp/xvector_nnet_1a # change this to pretrained xvector model downloaded from Kaldi website
am_nsf_xvec_out_dir=${xvec_nnet_dir}/am_nsf

plda_dir=${xvec_nnet_dir}/xvectors_train

# Output directories for netcdf data that will be used by AM & NSF training
am_nsf_train_out=/media/data/am_nsf_data/libritts/train_100 # change this to the dir where train, dev data and scp files will be stored
am_nsf_test_out=/media/data/am_nsf_data/libritts/test # change this to dir where test data will be stored
#===== end config =========

# Extract PPG using chain model
if [ $stage -le 0 ]; then
  echo "Stage 0: PPG extraction."
  local/featex/extract_ppg.sh --nj $nj --stage 0 data/${am_nsf_train_data} \
	  ${ivec_extractor} ${ivec_data_dir}/ivectors_${am_nsf_train_data} \
	  ${tree_dir} ${model_dir} ${lang_dir} ${ppg_dir}/ppg_${am_nsf_train_data}
fi

# Extract 80 dimensional mel spectrograms
if [ $stage -le 1 ]; then
  echo "Stage 1: Mel spectrogram extraction."
  local/featex/extract_melspec.sh --nj $nj data/${am_nsf_train_data} ${am_nsf_melspec_dir}
fi

# Split the data into train, dev and test
if [ $stage -le 2 ]; then
  echo "Stage 2: Splitting the data into train, dev and test based on speakers."
  local/featex/00_make_am_nsf_data.sh --dev-spks ${am_nsf_dev_spks} --test-spks ${am_nsf_test_spks} \
	  data/${am_nsf_train_data} ${am_nsf_split_dir}
fi

# Extract xvectors from each split of data
if [ $stage -le 3 ]; then
  echo "Stage 3: x-vector extraction."
  for sdata in ${am_nsf_split_data}; do
    local/featex/01_extract_xvectors.sh --nj $nj ${am_nsf_split_dir}/${sdata} ${xvec_nnet_dir} \
	  ${am_nsf_xvec_out_dir}
  done
fi

# Extract pitch from each split of data
if [ $stage -le 4 ]; then
  echo "Stage 4: Pitch extraction."
  for sdata in ${am_nsf_split_data}; do
    local/featex/02_extract_pitch.sh --nj ${am_nsf_dev_spks} ${am_nsf_split_dir}/${sdata}
  done
fi

# Create NetCDF data from each split
if [ $stage -le 5 ]; then
  echo "Stage 5: Making netcdf data for AM & NSF training."
  local/featex/03_make_am_nsf_netcdf_data.sh ${am_nsf_train_split} ${am_nsf_dev_split} ${am_nsf_test_split} \
	  ${ppg_dir}/ppg_${am_nsf_train_data}/phone_post.scp ${am_nsf_melspec_file} \
	  ${am_nsf_xvec_out_dir} ${am_nsf_train_out} ${am_nsf_test_out}
fi
