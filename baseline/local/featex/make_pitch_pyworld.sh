#!/bin/bash

wav_scp="$1"
pitch_dir="$2"
temp_wav="$3"

echo $wav_scp, $pitch_dir, $temp_wav

# make temp_wav as a directory
if [ ! -d ${temp_wav} ];
then
    mkdir ${temp_wav}
fi

while read line; do
  echo $line
  utid=$(echo $line | cut -d' ' -f1)
  rspec=$(echo $line | cut -d' ' -f2-)
  wav-copy "$rspec" $temp_wav/${utid}.wav
done < ${wav_scp}

# get F0
python local/featex/pyworld_get_f0.py $temp_wav $pitch_dir

# rm 
rm -r ${temp_wav}

# make the parent script happy
touch ${temp_wav}
