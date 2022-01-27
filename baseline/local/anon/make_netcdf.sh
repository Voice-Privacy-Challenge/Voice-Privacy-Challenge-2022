#!/bin/bash

. path.sh
. cmd.sh
. config.sh

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


if [ $stage -le 0 ]; then
  dataname=$(basename $src_data)
  if [[ "$tts_type" == "ssl" ]]; then
     mkdir -p $out_dir/scp $out_dir/xvector $out_dir/f0
     echo "Writing ssl SCP file.."
     if [[ ${dataname} != *"train"* ]];then
	  cut -f 2 -d' ' ${src_data}/wav.scp > ${out_dir}/scp/data_ssl.lst || exit 1;
     else 
	  cut -f 6 -d' ' ${src_data}/wav.scp > ${out_dir}/scp/data_ssl.lst || exit 1;
     fi
  else
      mkdir -p $out_dir/scp $out_dir/xvector $out_dir/f0 $out_dir/ppg
      echo "Writing SCP file.."
      cut -f 1 -d' ' ${src_data}/utt2spk > ${out_dir}/scp/data.lst || exit 1;
  fi
fi

# initialize pytools
. local/vc/am/init.sh

if [ $stage -le 1 ]; then
  if [ "$tts_type" == "ssl" ];then
      printf "${RED}\n Skip ppg step for model ${tts_type}.${NC}\n"
  else
      python local/featex/create_ppg_data.py ${ppg_file} ${out_dir} || exit 1;
  fi
fi

if [ $stage -le 2 ]; then
  echo "Writing xvector and F0 for train."
  if [ "$tts_type" == "ssl" ];then
      python local/featex/create_xvector_f0_data.py ${src_data} ${xvector_file} ${out_dir} ${tts_type}|| exit 1;
  else
      python local/featex/create_xvector_f0_data.py ${src_data} ${xvector_file} ${out_dir} || exit 1;
  fi
fi

