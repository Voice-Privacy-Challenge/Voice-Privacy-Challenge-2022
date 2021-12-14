#!/bin/bash
# Extract Mel-spectogram for AM of TTS
# Note that this mel-spectrogram is only used to train
# the acoustic model of TTS. 
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
output_dir=$3


if [ ! -d ${output_dir} ];then
    mkdir -p ${output_dir}
fi


# TO DO: loop over the script
# Assume this format
# 103-103_1241_000000_000001 sox path -r 16000 -t wav - downsample |
if ! type "parallel" &> /dev/null; then

    IFS=''
    while read data; do
	basename=`echo ${data} | awk '{print $1}'`
	input_wav=${norm_wav_dir}/${basename}.wav
	output_path=${output_dir}/${basename}.mel
	python3 local/featex/extract_mel_for_am.py ${input_wav} ${output_path}
    done < ${wav_scp}

else
    parallel -a ${wav_scp} --col-sep=' ' python3 local/featex/extract_mel_for_am.py ${norm_wav_dir}/{1}.wav  ${output_dir}/{1}.mel
fi

