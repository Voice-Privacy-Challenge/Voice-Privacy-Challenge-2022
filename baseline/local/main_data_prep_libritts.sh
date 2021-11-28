#!/bin/bash

set -e

. ./path.sh
. ./config.sh

libritts_corpus=$(realpath $corpora/LibriTTS)       # Directory for LibriTTS corpus 

local/data_prep_libritts.sh ${libritts_corpus}/${libritts_train_other_500} data/${anoni_pool} || exit 1

echo '  Done'
