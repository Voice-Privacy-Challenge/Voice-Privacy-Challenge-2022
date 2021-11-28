#!/bin/bash

set -e

. ./path.sh
. ./config.sh

for part in libritts_train_sets; do
  local/download_and_untar.sh $corpora $data_url_librispeech $part LibriTTS || exit 1
done

echo '  Done'
