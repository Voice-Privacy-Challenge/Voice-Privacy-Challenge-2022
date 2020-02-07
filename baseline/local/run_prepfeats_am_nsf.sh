#!/bin/bash

. path.sh
. cmd.sh

set -e

#===== begin config =======
nj=40
stage=0

# Chain model for PPG extraction
ppg_model=         # change this to your pretrained chain model
ppg_dir=           # change this to the dir where PPGs will be stored

# Xvector extractor
xvec_nnet_dir=     # change this to pretrained xvector model

#===== end config =========

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  exit 1;
fi

# Original data in ./data folder which will be splitted into train, dev and test based on speakers
train_data="$1" # change this to your actual data
feat_out_dir="$2"

# Mel spectrogram config
melspec_dir=data/${train_data}_mspec
melspec_file=${melspec_dir}/feats.scp

# Split data
dev_spks=20
test_spks=20
split_dir=data/am_nsf_train

# x-vector extraction
train_split=${train_data}_train
dev_split=${train_data}_dev
test_split=${train_data}_test
split_data="${train_split} ${dev_split} ${test_split}"
xvec_out_dir=${xvec_nnet_dir}/am_nsf

# Output directories for netcdf data that will be used by AM & NSF training
train_out=${feat_out_dir}/am_nsf_train # change this to the dir where train, dev data and scp files will be stored
test_out=${feat_out_dir}/am_nsf_test # change this to dir where test data will be stored


# Extract PPG using chain model
if [ $stage -le 0 ]; then
  echo "Stage 0: PPG extraction."
  local/featex/extract_ppg.sh --nj $nj --stage 0 data/${train_data} \
	  ${ppg_model} ${ppg_dir}/ppg_${train_data}
fi

# Extract 80 dimensional mel spectrograms
if [ $stage -le 1 ]; then
  echo "Stage 1: Mel spectrogram extraction."
  local/featex/extract_melspec.sh --nj $nj data/${train_data} ${melspec_dir}
fi

# Split the data into train, dev and test
if [ $stage -le 2 ]; then
  echo "Stage 2: Splitting the data into train, dev and test based on speakers."
  local/featex/00_make_am_nsf_data.sh --dev-spks ${dev_spks} --test-spks ${test_spks} \
	  data/${train_data} ${split_dir}
fi

# Extract xvectors from each split of data
if [ $stage -le 3 ]; then
  echo "Stage 3: x-vector extraction."
  for sdata in ${split_data}; do
    local/featex/01_extract_xvectors.sh --nj ${dev_spks} ${split_dir}/${sdata} ${xvec_nnet_dir} \
	  ${xvec_out_dir}
  done
fi

# Extract pitch from each split of data
if [ $stage -le 4 ]; then
  echo "Stage 4: Pitch extraction."
  for sdata in ${split_data}; do
    local/featex/02_extract_pitch.sh --nj ${dev_spks} ${split_dir}/${sdata}
  done
fi

# Create NetCDF data from each split
if [ $stage -le 5 ]; then
  echo "Stage 5: Making netcdf data for AM & NSF training."
  local/featex/03_make_am_nsf_netcdf_data.sh ${train_split} ${dev_split} ${test_split} \
	  ${ppg_dir}/ppg_${train_data}/phone_post.scp ${melspec_file} \
	  ${xvec_out_dir} ${train_out} ${test_out}
fi
