#!/bin/bash

#
# Extract BNs using chain model

. path.sh
. cmd.sh

nj=32
stage=0

. utils/parse_options.sh


# remove layers after BN
# nnet3-am-copy --raw=true --prepare-for-test=true --nnet-config='echo output-node name=output input=prefinal-l |' --edits='remove-orphans' final.mdl prefinal-l.raw

nj=1
use_gpu=yes
iv_root=exp/nnet3_cleaned
md_name=prefinal-l.raw
cmvn_op='--norm-means=false --norm-vars=false'
dsets="librispeech_dev_clean train_clean_100"


. parse_options.sh


./compute_hires.sh --nj $nj --dsets "$dsets"

./compute_ivect.sh --nj $nj --dsets "$dsets" --model $iv_root

./nnet3_compute.sh --nj 1 --use_gpu $use_gpu --iv_root $iv_root --md_name $md_name --dsets "$dsets"



echo Done
