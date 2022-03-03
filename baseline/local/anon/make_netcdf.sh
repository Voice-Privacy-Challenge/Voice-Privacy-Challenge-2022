#!/bin/bash

. path.sh
. cmd.sh

stage=0

. utils/parse_options.sh

if [ $# != 4 ]; then
  echo "Usage: "
  echo "  $0 [options] <train-dir> <ppg-file> <xvec-out-dir> <data-out-dir>"
  echo "Options"
  echo "   --stage 0     # Number of CPUs to use for feature extraction"
  exit 1;
fi

src_data=$1

ppg_file=$2
xvector_file=$3

out_dir=$4
xvector_dup_flag=$5

if [ $stage -le 0 ]; then
  mkdir -p $out_dir/scp $out_dir/xvector $out_dir/f0 $out_dir/ppg

  echo "Writing SCP file.."
  cut -f 1 -d' ' ${src_data}/utt2spk > ${out_dir}/scp/data.lst || exit 1;
fi

# initialize pytools
. local/vc/am/init.sh

if [ $stage -le 1 ]; then
  python local/featex/create_ppg_data.py ${ppg_file} ${out_dir} || exit 1;
fi

if [ $stage -le 2 ]; then
  echo "Writing xvector and F0 for train."
  python local/featex/create_xvector_f0_data.py ${src_data} ${xvector_file} ${out_dir} ${xvector_dup_flag}  || exit 1;
fi

