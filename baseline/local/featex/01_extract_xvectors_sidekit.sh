#!/bin/bash

set -e

. path.sh ""
. cmd.sh ""
. config.sh ""

if [ $# != 3 ]; then
  echo "Usage: "
  echo "  $0 <data-dir> <nnet-dir> <xvector-out-dir>"
  exit 1;
fi

data_dir=$1
nnet_dir=$2
out_dir=$3

dataname=$(basename $data_dir)
mkdir -p $out_dir
extract_xvectors.py \
    --vad \
    --model $(pwd)/${nnet_dir}/${xvec_model_name} \
    --wav-scp $(pwd)/${data_dir}/wav.scp \
    --out-scp $(pwd)/${out_dir}/xvectors_$dataname/xvector.scp \
    --out-spk-scp $(pwd)/${out_dir}/xvectors_$dataname/spk_xvector.scp \
    --spk2utt-file $(pwd)/${data_dir}/spk2utt