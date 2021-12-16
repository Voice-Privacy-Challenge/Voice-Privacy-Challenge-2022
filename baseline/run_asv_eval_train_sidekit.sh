#!/bin/bash

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#ASV_eval training on LibriSpeech train_clean_360 corpus
nj=20

# Create csv file from dataset for sidekit input
mark=.done-sidekit-train-csv
if [ ! -f $mark ]; then
  sidekit_csv_from_kaldi.py --kaldi-data-path data/$data_to_train_eval_models \
                            --out-csv data/$data_to_train_eval_models/sidekit_$data_to_train_eval_models.csv \
                            --database-name $data_to_train_eval_models
  touch $mark
fi

# Prepare data augmentation
mkdir -p data
mark=.done-sidekit-train-augment
if [ ! -f $mark ]; then
  python3 ../sidekit/egs/libri360_train/dataprep.py --from data/RIRS_NOISES --out-csv data/RIRS_NOISES/reverb.csv --make-csv-augment-reverb
  python3 ../sidekit/egs/libri360_train/dataprep.py --from data/musan_split --out-csv data/musan_split/musan.csv --make-csv-augment-noise
  touch $mark
fi



# Apply Voice Activation Detector to input data
mark=.done-sidekit-train-vad
if [ ! -f $mark ]; then
  mkdir -p data/$data_to_train_eval_models/vad
  apply_vad_on_csv.py --nj $nj \
                      --in-csv data/$data_to_train_eval_models/sidekit_$data_to_train_eval_models.csv \
                      --audio-dir $(pwd) \
                      --out-csv data/$data_to_train_eval_models/sidekit_vad_$data_to_train_eval_models.csv \
                      --out-audio-dir data/$data_to_train_eval_models/vad \
                      --extension-name flac || exit 1
  touch $mark
fi

# Copy and update configuration files for sidekit training
dataset_file="conf/sidekit_train/dataset.yaml"
model_file="conf/sidekit_train/model.yaml"
training_file="conf/sidekit_train/training.yaml"
mkdir -p conf/sidekit_train
cp ../sidekit/egs/libri360_train/cfg/Librispeech.yaml $dataset_file
cp ../sidekit/egs/libri360_train/cfg/model.yaml $model_file
cp ../sidekit/egs/libri360_train/cfg/training.yaml $training_file

sed -i "s|dataset_csv:.*|dataset_csv: data/$data_to_train_eval_models/sidekit_vad_$data_to_train_eval_models.csv|g" $dataset_file
sed -i "s|noise_db_csv:.*|noise_db_csv: data/musan_split/musan.csv|g" $dataset_file
sed -i "s|rir_db_csv:.*|rir_db_csv: data/RIRS_NOISES/reverb.csv|g" $dataset_file

log_dir=sidekit_log
mkdir -p $log_dir
sed -i "s|log_file:.*|log_file: $log_dir/$data_to_train_eval_models|g" $training_file
sed -i "s|tmp_model_name:.*|tmp_model_name: $xvec_nnet_dir/tmp_$data_to_train_eval_models.pt|g" $training_file
sed -i "s|best_model_name:.*|best_model_name: $xvec_nnet_dir/best_$data_to_train_eval_models.pt|g" $training_file


# To change train parameters (dataset location, hyperparameters, ...), edit sidekit/egs/libri360_train/cfg files
## Datat to launch
export NUM_NODES=1
export NUM_GPUS_PER_NODE=2
export NODE_RANK=0
export WORLD_SIZE=$(($NUM_NODES * $NUM_GPUS_PER_NODE))


mkdir -p log
mkdir -p $xvec_nnet_dir
python3 -m torch.distributed.launch \
       --nproc_per_node=$NUM_GPUS_PER_NODE \
       --nnodes=$NUM_NODES \
       --node_rank $NODE_RANK \
       ../sidekit/tools/train_xtractor.py --dataset $dataset_file --model $model_file --training $training_file

echo Done
