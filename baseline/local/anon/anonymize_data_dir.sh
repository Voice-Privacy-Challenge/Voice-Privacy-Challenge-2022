#!/bin/bash
# Script for first voice privacy challenge 2020
#
# This script anonymizes a kaldi data directory and produces a new 
# directory with given suffix in the name

. ./path.sh
. ./cmd.sh

set -e

#===== begin config =======
nj=20
stage=0

anoni_pool="libritts_train_other_500" # change this to the data you want to use for anonymization pool
data_netcdf= # change this to dir where VC features data will be stored

# Chain model for PPG extraction
ppg_model=
ppg_type=

ppg_dir=exp/nnet3_cleaned # change this to the dir where PPGs will be stored

# Type of the TTS for baseline 1
model_type=

# Option for incremental waveform generation
inference_trunc_len=-1


# x-vector extraction
xvec_nnet_dir= # change this to pretrained xvector model downloaded from Kaldi website
anon_xvec_out_dir=${xvec_nnet_dir}/anon

plda_dir=${xvec_nnet_dir}/xvectors_train

pseudo_xvec_rand_level=spk  # spk (all utterances will have same xvector) or utt (each utterance will have randomly selected xvector)
cross_gender="false"        # true, same gender xvectors will be selected; false, other gender xvectors
distance="cosine"           # cosine/plda
proximity="farthest"        # nearest/farthest

anon_data_suffix=_anon_${pseudo_xvec_rand_level}_${cross_gender}_${distance}_${proximity}

rand_seed=2020

#=========== end config ===========

. utils/parse_options.sh

echo "param=$1"

if [ $# != 1 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  exit 1;
fi

data_dir="$1" # Data to be anonymized, must be in Kaldi format

spk2utt=data/$data_dir/spk2utt
[ ! -f $spk2utt ] && echo "File $spk2utt does not exist" && exit 1
num_spk=$(wc -l < $spk2utt)
[ $nj -gt $num_spk ] && nj=$num_spk


# Extract xvectors from data which has to be anonymized
if [ $stage -le 0 ]; then
  printf "${RED}\nStage a.0: Extracting xvectors for ${data_dir}.${NC}\n"
  local/featex/01_extract_xvectors.sh --nj $nj data/${data_dir} ${xvec_nnet_dir} \
	  ${anon_xvec_out_dir} || exit 1;
fi

# Generate pseudo-speakers for source data
if [ $stage -le 1 ]; then
  printf "${RED}\nStage a.1: Generating pseudo-speakers for ${data_dir}.${NC}\n"
  local/anon/make_pseudospeaker.sh --rand-level ${pseudo_xvec_rand_level} \
      	  --cross-gender ${cross_gender} --distance ${distance} \
	  --proximity ${proximity} --rand-seed ${rand_seed} \
	  data/${data_dir} data/${anoni_pool} ${anon_xvec_out_dir} \
	  ${plda_dir} || exit 1;
fi

# Extract pitch for source data
if [ $stage -le 2 ]; then
  printf "${RED}\nStage a.2: Pitch extraction for ${data_dir}.${NC}\n"
  local/featex/02_extract_pitch.sh --nj ${nj} data/${data_dir} || exit 1;
fi

# Extract PPGs for source data
if [ $stage -le 3 ]; then
  printf "${RED}\nStage a.3: PPG extraction for ${data_dir}.${NC}\n"
  local/featex/extract_ppg.sh --nj $nj --stage 0 \
	  ${data_dir} ${ppg_model} ${ppg_dir}/ppg_${data_dir} || exit 1;
fi

# Create netcdf data for voice conversion
if [ $stage -le 4 ]; then
  printf "${RED}\nStage a.4: Make netcdf data for VC.${NC}\n"
  
  # only old model needs x-vector to be up-sampled to frame level
  case $model_type in
      
    am_nsf_old)
	xvector_dup_flag=1
	;;
    *)
	xvector_dup_flag=0
  esac


  local/anon/make_netcdf.sh --stage 0 data/${data_dir} ${ppg_dir}/ppg_${data_dir}/phone_post.scp \
	  ${anon_xvec_out_dir}/xvectors_${data_dir}/pseudo_xvecs/pseudo_xvector.scp \
	  ${data_netcdf}/${data_dir} ${xvector_dup_flag} || exit 1;
fi


# Decide the output folder name based on the model type
case $model_type in
    
    am_nsf_old)
	am_output_dir_name=am_out_mel
	wav_output_dir_name=nsf_output_wav
	script_am_dir=am
	script_wav_dir=nsf
	;;
    am_nsf_pytorch)
	am_output_dir_name=am_pt_out_mel
	wav_output_dir_name=nsf_pt_output_wav
	script_am_dir=am_pytorch
	script_wav_dir=nsf_pytorch
	;;
    joint_hifigan)
	am_output_dir_name="None"
	wav_output_dir_name=hifigan_output_wav
	script_am_dir="None"
	script_wav_dir=joint_tts_hifigan
	;;
    joint_nsf_hifigan)
	am_output_dir_name="None"
	wav_output_dir_name=nsf_hifigan_output_wav
	script_am_dir="None"
	script_wav_dir=joint_tts_nsf_hifigan
	;;
    *)
	printf "${RED}\nUnknown ${model_type}${NC}\n" 
	exit 1;
esac

if [ $stage -le 5 ]; then
  if [ "$script_am_dir" == "None" ];then   
      printf "${RED}\nStage a.5: Skip this step for model ${model_type}.${NC}\n"
  else
      printf "${RED}\nStage a.5: Generate melspec from acoustic model for ${data_dir}.${NC}\n"
      local/vc/${script_am_dir}/01_gen.sh ${data_netcdf}/${data_dir} ${am_output_dir_name} || exit 1;
  fi
fi

if [ $stage -le 6 ]; then
  printf "${RED}\nStage a.6: Generate waveform from ${model_type} for ${data_dir}.${NC}\n"
  local/vc/${script_wav_dir}/01_gen.sh ${data_netcdf}/${data_dir} ${am_output_dir_name} ${wav_output_dir_name} ${inference_trunc_len} || exit 1;
fi

if [ $stage -le 7 ]; then
  printf "${RED}\nStage a.7: Creating new data directories corresponding to anonymization.${NC}\n"
  wav_path=${data_netcdf}/${data_dir}/${wav_output_dir_name}
  new_data_dir=data/${data_dir}${anon_data_suffix}
  if [ -d "$new_data_dir" ]; then
    rm -rf ${new_data_dir}
  fi
  utils/copy_data_dir.sh data/${data_dir} ${new_data_dir}
  [ -f ${new_data_dir}/feats.scp ] && rm ${new_data_dir}/feats.scp
  [ -f ${new_data_dir}/vad.scp ] && rm ${new_data_dir}/vad.scp
    # Copy new spk2gender in case cross_gender vc has been done
  cp ${anon_xvec_out_dir}/xvectors_${data_dir}/pseudo_xvecs/spk2gender ${new_data_dir}/
  awk -v p="$wav_path" '{print $1, "sox", p"/"$1".wav", "-t wav -R -b 16 - |"}' data/${data_dir}/wav.scp > ${new_data_dir}/wav.scp
fi
