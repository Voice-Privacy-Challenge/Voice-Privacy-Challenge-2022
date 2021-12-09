#!/bin/bash

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#ASV_eval training on LibriSpeech train_clean_360 corpus
nj=20

cd ../sidekit/egs/libri360_train
back_to_sidekit_root=../..

# Create csv file from dataset for sidekit input
mark=.done-sidekit-train-csv
if [ ! -f $mark ]; then
  sidekit_csv_from_kaldi.py --kaldi-data-path $back_to_sidekit_root/../baseline/data/train_clean_360 \
                            --out-csv list/libri_train_clean_360.csv \
                            --database-name libri_train_clean_360
  sed -i 's|corpora|/srv/storage/talc3@talc-data.nancy/multispeech/calcul/users/hnourtel/Voice-Privacy-Challenge-2022/baseline/corpora|g' list/libri_train_clean_360.csv
  touch $mark
fi

# Prepare data augmentation
mkdir -p data
mark=.done-sidekit-train-augment
if [ ! -f $mark ]; then
  python3 dataprep.py --save-path data --download-augment
  python3 dataprep.py --from ./data/RIRS_NOISES --make-csv-augment-reverb
  python3 dataprep.py --from ./data/musan_split --make-csv-augment-noise
  touch $mark
fi



# Apply Voice Activation Detector to input data
mark=.done-sidekit-train-vad
if [ ! -f $mark ]; then
  apply_vad_on_csv.py --nj $nj \
                      --in-csv list/libri_train_clean_360.csv \
                      --out-csv list/libri_train_clean_360_vad.csv \
                      --out-audio-dir ./data/libri_train_clean_360_vad \
                      --extension-name flac || exit 1
  touch $mark
fi

# To change train parameters (dataset location, hyperparameters, ...), edit sidekit/egs/libri360_train/cfg files
## Datat to launch
#export NUM_NODES=1
#export NUM_GPUS_PER_NODE=2
#export NODE_RANK=0
#export WORLD_SIZE=$(($NUM_NODES * $NUM_GPUS_PER_NODE))

dataset_file="egs/libri360_train/cfg/Librispeech.yaml"
model_file="egs/libri360_train/cfg/model.yaml"
training_file="egs/libri360_train/cfg/training.yaml"

train_xtractor.py --dataset $dataset_file --model $model_file --training $training_file

# Copy output sidekit model to final location in baseline tree
cp model/best_libri_train_clean_360.pt  $xvec_nnet_dir/$xvec_model_name

echo Done
