#!/bin/bash
# Script to down-sample and normalzie the waveform amplitude
#
set -e

. path.sh
. cmd.sh

nj=$(nproc)

. utils/parse_options.sh

# TO DO: make it distributed
#if [ $# != 3 ]; then
#  echo "Usage: "
#  echo "  $0 [options] <data-dir> <nnet-dir> <xvector-out-dir>"
#  echo "Options"
#  echo "   --nj=40     # Number of CPUs to use for feature extraction"
#  exit 1;
#fi

# list of waveform files
wav_scp=$1

# normalized waveform directory
norm_wav_dir=$2

# sampling rate
sampling_rate=$3


if [ ! -d ${norm_wav_dir} ];then
    mkdir -p ${norm_wav_dir}
fi

# TO DO: loop over the script
# Assume this format
# 103-103_1241_000000_000001 sox path -r 16000 -t wav - downsample |

if ! type "parallel" &> /dev/null; then
    IFS=''
    while read data; do
	basename=`echo ${data} | awk '{print $1}'`
	filepath=`echo ${data} | awk '{print $3}'`
	
	output_path=${norm_wav_dir}/${basename}.wav
	bash local/featex/prepare_waveform_for_tts.sh ${filepath} ${output_path} ${sampling_rate} || exit 1;
    done < ${wav_scp}
else
    parallel -a ${wav_scp} --col-sep=' ' bash local/featex/prepare_waveform_for_tts.sh {3} ${norm_wav_dir}/{1}.wav ${sampling_rate}
fi

