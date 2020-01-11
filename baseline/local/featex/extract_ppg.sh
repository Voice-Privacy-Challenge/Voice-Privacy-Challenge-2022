#!/bin/bash

#
# Extract PPGs using chain model
# This script extract word position dependent phonemes (346) posteriors
#
. path.sh
. cmd.sh

nj=32
stage=0

. utils/parse_options.sh

if [ $# != 7 ]; then
  echo "Usage: "
  echo "  $0 [options] <srcdir> <ivec-extractor> <ivec-datadir> <tree-dir> <model-dir> <lang-dir> <ppg-destdir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  echo "   --stage=0     # Extraction stage"
  exit 1;
fi

data=$1
original_data_dir=data/${data}

data_dir=data/${data}_hires
ivec_extractor=$2
ivec_data_dir=$3

tree_dir=$4
model_dir=$5
lang_dir=$6

ppg_dir=$7


export LC_ALL=C
if [ $stage -le 0 ]; then
  utils/copy_data_dir.sh ${original_data_dir} ${data_dir}
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
	--cmd "$train_cmd" ${data_dir}

  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
       	${data_dir} ${ivec_extractor} ${ivec_data_dir} 
fi

if [ $stage -le 1 ]; then
  steps/nnet3/chain/get_phone_post.sh --cmd "$train_cmd" --nj $nj \
       	--remove-word-position-dependency false --online-ivector-dir ${ivec_data_dir} \
	${tree_dir} ${model_dir} ${lang_dir} ${data_dir} ${ppg_dir}
fi
