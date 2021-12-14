#!/bin/bash
# -------
# scripts to train acoustic model for TTS
# 
. path.sh

# original scripts
proj_dir=${nii_pt_scripts}/projects/nsf
# a temporary name for the dataset
tmp_dataset_name=$1
# path to the feature directory
tmp_data_dir=$2
# path to save the trained model
tmp_output_dir=$3


####
# Prepare directory
#### 
# Copy scripts to the new directory
if [ ! -d ${tmp_output_dir} ];
then
    mkdir -p ${tmp_output_dir}
fi

printf "${GREEN}Copy scripts${NC}\nFrom ${proj_dir} to ${tmp_output_dir}\n"
printf "Training will be conducted in ${tmp_output_dir}\n"
cp ${proj_dir}/*.py ${tmp_output_dir}

####
# Export environment variables
####
#  name to save cached files
export TEMP_TRNSET_NAME=${tmp_dataset_name}_trn
export TEMP_DEVSET_NAME=${tmp_dataset_name}_dev
#  path to the data list
export TEMP_TRNSET_LIST=${tmp_data_dir}/scp/train.lst
export TEMP_DEVSET_LIST=${tmp_data_dir}/scp/dev.lst
#  path to the data (train and dev should be in the same folder)
export TEMP_TRNDEV_MEL=${tmp_data_dir}/mel
export TEMP_TRNDEV_XVEC=${tmp_data_dir}/xvector
export TEMP_TRNDEV_F0=${tmp_data_dir}/f0
export TEMP_TRNDEV_WAV=${tmp_data_dir}/wav_tts


####
# start training
####
cd ${tmp_output_dir}

log_train_name=log_train
log_err_name=log_err

printf "${GREEN}Training started... ${NC}\n"
printf "Please monitor the training log $PWD/${log_train_name}\n"
printf "Training error per utterance is in $PWD/${log_err_name}\n"

python3 main.py --lr 0.0001 --epochs 50 --no-best-epochs 20 --batch-size 5 \
	--num-workers 5  --ignore-length-invalid-data \
	--ignore-cached-file-infor \
	--cudnn-deterministic-toggle  \
	--cudnn-benchmark-toggle >${log_train_name} 2>${log_err_name}

if [ -e trained_network.pt ];
then
    printf "${GREEN}Latest trained model is $PWD/trained_network.pt${NC}\n"
    printf "However, please check whether the training has converged properly.\n"
fi

cd -

