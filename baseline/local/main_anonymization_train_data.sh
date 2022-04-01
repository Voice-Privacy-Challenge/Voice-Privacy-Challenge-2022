#!/bin/bash

set -e

. ./config.sh

rand_seed=$rand_seed_start
dset=${data_to_train_eval_models}-asv #train-clean-360-asv
anon_level=$train_anon_level

train=$data_to_train_eval_models
train_asv=$data_to_train_eval_models-asv
train_anon=${data_to_train_eval_models}$anon_data_suffix
train_asv_anon=$data_to_train_eval_models-asv$anon_data_suffix

echo "anon_level = $anon_level"
echo $dset


if [ $baseline_type = 'baseline-2' ]; then
  printf "${GREEN}\n Anonymizing using McAdams coefficient...${NC}\n"
  printf "mc_coeff_min = $mc_coeff_min\n"
  printf "mc_coeff_max = $mc_coeff_max\n"
  
  #copy content of the folder to the new folder
  utils/copy_data_dir.sh data/$dset data/$dset$anon_data_suffix || exit 1
  rm -rf data/$dset$anon_data_suffix/.backup
  #create folder that will contain the anonymised wav files
  mkdir -p data/$dset$anon_data_suffix/wav
  #anonymise subset based on the current wav.scp file 
  python local/anon/anonymise_dir_mcadams_rand_seed.py \
    --data_dir=data/$dset --anon_suffix=$anon_data_suffix \
    --n_coeffs=$n_lpc --mc_coeff_min=$mc_coeff_min --mc_coeff_max=$mc_coeff_max --subset=$dset --seed=$rand_seed --anon_level=$anon_level || exit 1
else
  data_netcdf=$(realpath $anonym_data)   # directory where features for voice anonymization will be stored
  echo $data_netcdf
  mkdir -p $data_netcdf || exit 1;
  
  printf "${GREEN}\n Anonymizing using x-vectors and neural wavform models...${NC}\n"
  ppg_dir=${ppg_model}/nnet3_cleaned
  echo "Dataset:     $dset"
 
  echo "local/anon/anonymize_data_dir.sh \
    --nj $nj --anoni-pool $anoni_pool \
    --data-netcdf $data_netcdf \
    --ppg-model $ppg_model --ppg-dir $ppg_dir \
    --xvec-nnet-dir $xvec_nnet_dir \
    --anon-xvec-out-dir $anon_xvec_out_dir --plda-dir $xvec_nnet_dir \
    --pseudo-xvec-rand-level $anon_level --distance $distance \
    --proximity $proximity --cross-gender $cross_gender \
    --rand-seed $rand_seed \
    --anon-data-suffix $anon_data_suffix \
    --model-type $tts_type \
    --inference-trunc-len $inference_trunc_len \
    --inference-batch-size-am $inference_batch_size_am \
    --inference-batch-size-wav $inference_batch_size_wav \
    ${dset} || exit 1"
 
  local/anon/anonymize_data_dir.sh \
    --nj $nj --anoni-pool $anoni_pool \
    --data-netcdf $data_netcdf \
    --ppg-model $ppg_model --ppg-dir $ppg_dir \
    --xvec-nnet-dir $xvec_nnet_dir \
    --anon-xvec-out-dir $anon_xvec_out_dir --plda-dir $xvec_nnet_dir \
    --pseudo-xvec-rand-level $anon_level --distance $distance \
    --proximity $proximity --cross-gender $cross_gender \
    --rand-seed $rand_seed \
    --anon-data-suffix $anon_data_suffix \
    --model-type $tts_type \
    --inference-trunc-len $inference_trunc_len \
    --inference-batch-size-am $inference_batch_size_am \
    --inference-batch-size-wav $inference_batch_size_wav \
    $dset || exit 1
fi  


# Copy train_anon from train_asv_anon and replace spk2utt with session-speaker ids
printf "${GREEN}\n: Copy  $train_anon from $train_asv_anon and modication of spk2utt...${NC}\n"
utils/copy_data_dir.sh data/$train_asv_anon data/$train_anon || exit 1
cp data/$train/utt2spk data/$train_anon
utils/utt2spk_to_spk2utt.pl data/$train_asv/utt2spk > data/$train_anon/spk2utt || exit 1
cp data/$train/spk2gender data/$train_anon 
rm -f data/$train_anon/cmvn.scp
utils/fix_data_dir.sh data/$train_anon || exit 1
utils/validate_data_dir.sh --no-feats data/$train_anon || exit 1

echo '  Done'
