#!/bin/bash

wav_scp="$1"
pitch_dir="$2"
temp_wav="$3"

echo $wav_scp, $pitch_dir, $temp_wav

while read line; do
  echo $line
  utid=$(echo $line | cut -d' ' -f1)
  rspec=$(echo $line | cut -d' ' -f2-)
  wav-copy "$rspec" $temp_wav
  python local/featex/f0_yaapt/get_f0.py $temp_wav $pitch_dir/${utid}.f0
done < ${wav_scp}


