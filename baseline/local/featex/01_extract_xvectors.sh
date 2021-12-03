#!/bin/bash

set -e

. path.sh
. cmd.sh
. config.sh

nj=$(nproc)

. utils/parse_options.sh

if [ $# != 3 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-dir> <nnet-dir> <xvector-out-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  exit 1;
fi

data_dir=$1
nnet_dir=$2
out_dir=$3

echo "Extracting x-vectors with $xvect_type model"
if [ $xvect_type = "kaldi" ]; then
  mfccdir=`pwd`/mfcc
  vaddir=`pwd`/mfcc

  mkdir -p ${out_dir}
  dataname=$(basename $data_dir)

  steps/make_mfcc.sh --write-utt2num-frames true --mfcc-config conf/mfcc.conf \
      --nj $nj --cmd "$train_cmd" ${data_dir} exp/make_mfcc $mfccdir || exit 1

  utils/fix_data_dir.sh ${data_dir} || exit 1

  sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" ${data_dir} exp/make_vad $vaddir || exit 1

  utils/fix_data_dir.sh ${data_dir} || exit 1

  sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd" --nj $nj \
      $nnet_dir ${data_dir} $out_dir/xvectors_$dataname || exit 1

elif [ $xvect_type = "sidekit" ]; then
  ../sidekit/tools/extract_xvectors.py \
              --vad \
              --model ${nnet_dir}/${xvec_model_name} \
              --wav-scp ${data_dir}/wav.scp \
              --out-scp ${out_dir}/x_vector.scp
else
    echo "Xvector-type not supported : " $xvect_type
fi