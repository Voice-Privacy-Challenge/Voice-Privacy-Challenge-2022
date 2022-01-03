#!/bin/bash

set -e

. ./config.sh

rand_seed=$rand_seed_start

data_netcdf=$(realpath $anonym_data)   # directory where features for voice anonymization will be stored
echo $data_netcdf
mkdir -p $data_netcdf || exit 1;

for dset in libri_dev_{enrolls,trials_f,trials_m} \
            vctk_dev_{enrolls,trials_f_all,trials_m_all} \
            libri_test_{enrolls,trials_f,trials_m} \
            vctk_test_{enrolls,trials_f_all,trials_m_all}; do
  if [ -z "$(echo $dset | grep enrolls)" ]; then
    anon_level=$anon_level_trials
    mc_coeff=$mc_coeff_trials
  else
    anon_level=$anon_level_enroll
    mc_coeff=$mc_coeff_enroll
  fi
  echo "anon_level = $anon_level"
  echo $dset
  if [ $baseline_type = 'baseline-2' ]; then
    printf "${GREEN}\n Anonymizing using McAdams coefficient...${NC}\n"
    #copy content of the folder to the new folder
    utils/copy_data_dir.sh data/$dset data/$dset$anon_data_suffix || exit 1
    #create folder that will contain the anonymised wav files
    mkdir -p data/$dset$anon_data_suffix/wav
    #anonymise subset based on the current wav.scp file 
    python local/anon/anonymise_dir_mcadams.py \
      --data_dir=data/$dset --anon_suffix=$anon_data_suffix \
      --n_coeffs=$n_lpc --mc_coeff=$mc_coeff || exit 1
    #overwrite wav.scp file with new anonymised content
    #note sox is inclued to by-pass that files written by local/anon/anonymise_dir_mcadams.py were in float32 format and not pcm
    ls data/$dset$anon_data_suffix/wav/*/*.wav | \
      awk -F'[/.]' '{print $5 " sox " $0 " -t wav -R -b 16 - |"}' > data/$dset$anon_data_suffix/wav.scp
  else
    printf "${GREEN}\n Anonymizing using x-vectors and neural wavform models...${NC}\n"
    ppg_dir=${ppg_model}/nnet3_cleaned
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
      $dset || exit 1
  fi
  if [ -f data/$dset/enrolls ]; then
    cp data/$dset/enrolls data/$dset$anon_data_suffix/ || exit 1
  else
    [ ! -f data/$dset/trials ] && echo "File data/$dset/trials does not exist" && exit 1
    cp data/$dset/trials data/$dset$anon_data_suffix/ || exit 1
  fi
  rand_seed=$((rand_seed+1))
done

echo '  Done'
