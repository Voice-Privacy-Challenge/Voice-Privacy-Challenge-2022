#!/bin/bash

set -e

. ./config.sh

for part in $libritts_train_sets; do
  echo $data_url_libritts
  local/download_and_untar.sh $corpora $data_url_libritts $part LibriTTS || exit 1
done

echo '  Done'
