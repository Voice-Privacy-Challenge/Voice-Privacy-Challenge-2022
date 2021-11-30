#!/bin/bash
# Download and preparing training data for ASR_eval / ASR_eval_anon  and ASV_eval / ASV_eval_anon

set -e

. ./config.sh

for part in $train_data; do
  local/download_and_untar.sh $corpora $data_url_librispeech $part LibriSpeech --remove-archive || exit 1
done

echo '  Done'
