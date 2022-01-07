#!/bin/bash

wav_scp="$1"
pitch_dir="$2"
temp_wav="$3"
#extractor="pyworld"
extractor="yaapt"


echo $wav_scp, $pitch_dir, $temp_wav

# get F0
python local/featex/external_get_f0.py $wav_scp $pitch_dir ${extractor}

# make the parent script happy
touch ${temp_wav}
