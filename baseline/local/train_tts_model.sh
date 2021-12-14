#!/bin/bash
#Training TTS models on $data_train_tts_out data (in the baseline: LibriTTS-train-clean-100)

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

nj=20
stage=0

. ./utils/parse_options.sh

data=data/$data_train_tts_out #Directory with the prepared data (x-vectors, BN, pitch, ...) for training TTS model 
echo $data

# if [ $stage -le 0 ]; then
  # vc/nsf/00_run.sh ${data} || exit 1
# fi

# if [ $stage -le 1 ]; then
  # local/vc/am/00_run.sh ${data} || exit 1
# fi


echo Done
