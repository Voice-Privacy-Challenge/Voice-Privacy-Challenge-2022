#!/bin/bash
# Script for first voice privacy challenge 2020
#
# This script anonymizes a kaldi data directory and produces a new 
# directory with given suffix in the name

. ./path.sh
. ./cmd.sh
. ./config.sh

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
# Option for batch size during inference
inference_batch_size_am=10
inference_batch_size_wav=2

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
  if [ $xvect_type = "kaldi" ]; then
    local/featex/01_extract_xvectors_kaldi.sh --nj $nj data/${data_dir} ${xvec_nnet_dir} \
	    ${anon_xvec_out_dir} || exit 1;
  elif [ $xvect_type = "sidekit" ]; then
    local/featex/01_extract_xvectors_sidekit.sh data/${data_dir} ${xvec_nnet_dir} ${anon_xvec_out_dir} || exit 1;
	fi
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
  # TEMPORAL (to speed up): use the dowloaded F0 files (yaapt) for train-clean-360-asv 
  printf "f0_download=$f0_download, data_dir=$data_dir"
  if [[ $f0_download == 'true' ]] && [[ $data_dir == 'train-clean-360-asv' ]]; then
	if [ ! -d 'exp/am_nsf_data/train-clean-360-asv/f0' ]; then
      printf "Directory exp/am_nsf_data/$data_dir/f0 does not exist. Please download train-clean-360-asv/f0 from the server or compute it (set up f0_download=false)"
	  exit 1;
	else
	  printf "${RED}\nStage a.2: Skipping pitch extraction for exp/am_nsf_data/${data_dir}: dowloaded f0 will be used... ${NC}\n"
	fi
  else
    printf "${RED}\nStage a.2: Pitch extraction for ${data_dir}.${NC}\n"
   local/featex/02_extract_pitch.sh --nj ${nj} data/${data_dir} || exit 1;
  fi
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
  local/anon/make_netcdf.sh --stage 0 data/${data_dir} ${ppg_dir}/ppg_${data_dir}/phone_post.scp \
	  ${anon_xvec_out_dir}/xvectors_${data_dir}/pseudo_xvecs/pseudo_xvector.scp \
	  ${data_netcdf}/${data_dir} || exit 1;
fi


# Decide the output folder name based on the model type
case $model_type in
    
    am_nsf_old)
    if [ $xvect_type = "sidekit" ];
    then
        printf "${RED}\nam_nsf_old cannot suport ${xvect_type}${NC}\n"
        printf "${RED}Please use am_nsf_pytorch${NC}\n "
        exit 1;
    else
        am_output_dir_name=am_out_mel
        wav_output_dir_name=nsf_output_wav
    fi
    script_am_dir=am
    script_wav_dir=nsf
    ;;
    am_nsf_pytorch)
		if [ $xvect_type = "sidekit" ];
	  then
	    am_output_dir_name=am_pt_sidekit_out_mel
	    wav_output_dir_name=nsf_pt_sidekit_output_wav
	  else
	    am_output_dir_name=am_pt_out_mel
	    wav_output_dir_name=nsf_pt_output_wav
    fi
    script_am_dir=am_pytorch
    script_wav_dir=nsf_pytorch
    ;;
      joint_hifigan)
    am_output_dir_name="None"
    if [ $xvect_type = "sidekit" ];
    then
        wav_output_dir_name=hifigan_sidekit_output_wav
    else
        wav_output_dir_name=hifigan_output_wav
    fi
    script_am_dir="None"
    script_wav_dir=joint_tts_hifigan
    ;;
      joint_nsf_hifigan)
    am_output_dir_name="None"
    if [ $xvect_type = "sidekit" ];
    then
        wav_output_dir_name=nsf_hifigan_sidekit_output_wav
    else
        wav_output_dir_name=nsf_hifigan_output_wav
    fi
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
      local/vc/${script_am_dir}/01_gen.sh ${data_netcdf}/${data_dir} ${am_output_dir_name} ${inference_batch_size_am} ${xvect_type  || exit 1;
  fi
fi

if [ $stage -le 6 ]; then
  printf "${RED}\nStage a.6: Generate waveform from ${model_type} for ${data_dir}.${NC}\n"
  local/vc/${script_wav_dir}/01_gen.sh ${data_netcdf}/${data_dir} ${am_output_dir_name} ${wav_output_dir_name} ${inference_trunc_len} ${inference_batch_size_wav} ${xvect_type} || exit 1;
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
