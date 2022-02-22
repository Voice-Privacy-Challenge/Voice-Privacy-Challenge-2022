#!/bin/bash
#Training TTS models on $data_train_tts_out data (in the baseline: LibriTTS-train-clean-100)

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

nj=20
stage=0

# Type of the TTS for baseline 1
model_type=

# Folder to hold the data 
# Directory with the prepared data (x-vectors, BN, pitch, ...) for training TTS model 
data_dir=

. ./utils/parse_options.sh


if [ $stage -le 0 ]; then
    printf "${RED}\nStage a.0: Creating training, development, and testing data list for TTS models${NC}\n"
    local/vc/create_train_dev_test.sh --data-dir ${data_dir}
fi


# Decide the output folder name based on the model type
case $model_type in
    
    am_nsf_old)
	printf "${RED}\nTraining ${model_type} is obsolete${NC}\n" 
	printf "${RED}\nTry am_nsf_pytorch instead${NC}\n" 
	exit 1;
	;;
    am_nsf_pytorch)	
	script_am_dir=am_pytorch
	script_wav_dir=nsf_pytorch
	;;
    joint_hifigan)
	script_am_dir="None"
	script_wav_dir=joint_tts_hifigan
	;;
    joint_nsf_hifigan)
	script_am_dir="None"
	script_wav_dir=joint_tts_nsf_hifigan
	;;
    *)
	printf "${RED}\nUnknown ${model_type}${NC}\n" 
	exit 1;
esac

if [ $stage -le 1 ]; then
  if [ "$script_am_dir" == "None" ];then   
      printf "${RED}\nStage a.1: Skip this step for model ${model_type}.${NC}\n"
  else
      printf "${RED}\nStage a.1: Train acoustic model for ${model_type}.${NC}\n"
      # we need the full path to the data folder
      tmp_data_path=`realpath ${data_dir}`
      local/vc/${script_am_dir}/00_run.sh tmp_${data_train_tts} \
	       ${tmp_data_path} ${tts_model_save}/am  ${xvect_type} || exit 1;
  fi
fi

if [ $stage -le 2 ]; then
  printf "${RED}\nStage a.2: Train waveform model for ${model_type}.${NC}\n"
  tmp_data_path=`realpath ${data_dir}`

  if [ "$script_am_dir" == "None" ];then
      tmp_tts_model_save=${tts_model_save}
  else
      # if this is for am_nsf, use a separate folder 
      tmp_tts_model_save=${tts_model_save}/nsf
  fi
  local/vc/${script_wav_dir}/00_run.sh tmp_${data_train_tts} \
	 ${tmp_data_path} ${tmp_tts_model_save} ${xvect_type} || exit 1;
fi

echo Done
