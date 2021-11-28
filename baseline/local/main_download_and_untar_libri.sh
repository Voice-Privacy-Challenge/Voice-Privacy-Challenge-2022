#!/bin/bash

set -e

. ./config.sh

for part in $libri_train_sets; do
  local/download_and_untar.sh $corpora $data_url_librispeech $part LibriSpeech || exit 1
done

echo '  Done'
