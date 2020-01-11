#!/bin/bash
. path.sh
. cmd.sh

nj=40

. utils/parse_options.sh

if [ $# != 3 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-dir> <nnet-dir> <xvector-out-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  exit 1;
fi

mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
data_dir=$1

nnet_dir=$2
out_dir=$3

mkdir -p ${out_dir}
dataname=$(basename $data_dir)

steps/make_mfcc.sh --write-utt2num-frames true --mfcc-config conf/mfcc.conf \
       	--nj $nj --cmd "$train_cmd" ${data_dir} exp/make_mfcc $mfccdir
utils/fix_data_dir.sh ${data_dir}
    
sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" ${data_dir} exp/make_vad $vaddir
utils/fix_data_dir.sh ${data_dir}

sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 4G" --nj $nj \
	$nnet_dir ${data_dir} \
	$out_dir/xvectors_$dataname

