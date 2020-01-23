#!/bin/bash

#
# Extract PPGs using chain model
# This script extract word position dependent phonemes (346) posteriors and 256-bottleneck PPGs based on ppg-type  option.
#
. path.sh
. cmd.sh

nj=32
stage=0

. utils/parse_options.sh

if [ $# != 3 ]; then
  echo "Usage: "
  echo "  $0 [options] <srcdir> <model-dir> <ppg-destdir>"
  echo "Options"
  echo "   --nj=40             # Number of CPUs to use for feature extraction"
  echo "   --stage=0           # Extraction stage"
  exit 1;
fi

data=$1
ppg_model=$2
ppg_dir=$3

original_data_dir=data/${data}
data_dir=data/${data}_hires

ivec_extractor=${ppg_model}/nnet3_cleaned/extractor
ivec_data_dir=${ppg_model}/nnet3_cleaned/ivectors_${data}_hires

model_dir=${ppg_model}/chain_cleaned/tdnn_1d_sp



export LC_ALL=C
if [ $stage -le 0 ]; then
  utils/copy_data_dir.sh ${original_data_dir} ${data_dir}
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
	--cmd "$train_cmd" ${data_dir}

  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
       	${data_dir} ${ivec_extractor} ${ivec_data_dir} 
fi

if [ $stage -le 1 ]; then
    # Keeping nj to 1 due to GPU memory issues
    local/featex/extract_bn.sh --cmd "$train_cmd" --nj 1 \
	--iv-root ${ivec_data_dir} --model-dir ${model_dir} \
       	${data} ${ppg_dir} || exit 1;
fi
