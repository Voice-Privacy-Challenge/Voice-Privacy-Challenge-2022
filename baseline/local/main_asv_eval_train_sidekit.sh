#!/bin/bash

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#ASV_eval training on LibriSpeech train_clean_360 corpus
nj=20
sidekit_root=../../sidekit

train_data=$data_to_train_eval_models-asv
if [[ $data_proc == 'anon' ]]; then
  printf "${GREEN} Training evaluation models on anonymized data...${NC}\n"
  train_data=$train_data$anon_data_suffix
else
  printf "${GREEN} Training evaluation models on original data...${NC}\n"
fi

# Create csv file from dataset for sidekit input
mark=.done-sidekit-train-csv
if [ ! -f $mark ]; then
  data_dir=data/$train_data
  # Read first line of the wav.scp file to detect if a command exists.
  # If it's the case, apply command to convert wav files
  first_line=$(head -n 1 $data_dir/wav.scp)
  first_line_trim=$(echo $first_line | awk '{$1=$1;print}')
  lastChar=${first_line_trim: -1}

  if [ $first_line_trim == "|" ]; then
    # Copy input directory with required data for csv creation
    out_dir_new_data=data/"$train_data"_sidekit
    mkdir $out_dir_new_data
    cp data/$train_data/spk2gender \
       data/$train_data/utt2spk \
       data/$train_data/utt2dur \
       $out_dir_new_data
    python3 prepare_sidekit_csv_from_kaldi.py --wav-scp data/$train_data/wav.scp --out-dir $out_dir_new_data
    data_dir=$out_dir_new_data
  fi
  sidekit_csv_from_kaldi.py --kaldi-data-path $data_dir \
                            --out-csv data/$train_data/sidekit_$train_data.csv \
                            --database-name $train_data
  touch $mark
fi

# Prepare data augmentation
mkdir -p data
mark=.done-sidekit-train-augment
if [ ! -f $mark ]; then
  python3 $sidekit_root/egs/libri360_train/dataprep.py --from data/RIRS_NOISES --out-csv data/RIRS_NOISES/reverb.csv --make-csv-augment-reverb
  python3 $sidekit_root/egs/libri360_train/dataprep.py --from data/musan_split --out-csv data/musan_split/musan.csv --make-csv-augment-noise
  touch $mark
fi



# Apply Voice Activation Detector to input data
mark=.done-sidekit-train-vad
if [ ! -f $mark ]; then
  mkdir -p data/$train_data/vad
  apply_vad_on_csv.py --nj $nj \
                      --in-csv data/$train_data/sidekit_$train_data.csv \
                      --audio-dir $(pwd) \
                      --out-csv data/$train_data/sidekit_vad_$train_data.csv \
                      --out-audio-dir data/$train_data/vad \
                      --extension-name flac || exit 1
  touch $mark
fi

# Copy and update configuration files for sidekit training
dataset_file="conf/sidekit_train/dataset.yaml"
model_file="conf/sidekit_train/model.yaml"
training_file="conf/sidekit_train/training.yaml"
mkdir -p conf/sidekit_train
cp $sidekit_root/egs/libri360_train/cfg/Librispeech.yaml $dataset_file
cp $sidekit_root/egs/libri360_train/cfg/model.yaml $model_file
cp $sidekit_root/egs/libri360_train/cfg/training.yaml $training_file

sed -i "s|dataset_csv:.*|dataset_csv: data/$train_data/sidekit_vad_$train_data.csv|g" $dataset_file
sed -i "s|noise_db_csv:.*|noise_db_csv: data/musan_split/musan.csv|g" $dataset_file
sed -i "s|rir_db_csv:.*|rir_db_csv: data/RIRS_NOISES/reverb.csv|g" $dataset_file

log_dir=sidekit_log
mkdir -p $log_dir
sed -i "s|log_file:.*|log_file: $log_dir/$train_data|g" $training_file
sed -i "s|tmp_model_name:.*|tmp_model_name: $xvec_nnet_dir/tmp_$train_data.pt|g" $training_file
sed -i "s|best_model_name:.*|best_model_name: $xvec_nnet_dir/best_$train_data.pt|g" $training_file


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
       $sidekit_root/tools/train_xtractor.py --dataset $dataset_file --model $model_file --training $training_file

echo Done
