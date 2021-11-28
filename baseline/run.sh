#!/bin/bash
# Script for The 2022 VoicePrivacy Challenge
##
# Copyright (C) 2022  <Brij Mohan Lal Srivastava, Natalia Tomashenko, Xin Wang, Jose Patino, Paul-Gauthier Noé, Andreas Nautsch, ...>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

set -e

. ./path.sh
. ./cmd.sh
. ./config.sh

stage=10

. utils/parse_options.sh || exit 1

# Download datasets
if [ $stage -le 0 ]; then
  printf "${GREEN}\nStage $stage: Downloading data...${NC}\n"
  local/main_download_data.sh || exit 1
fi


# Download pretrained models
if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage $stage: Downloading pretrained models...${NC}\n"
  local/download_models.sh || exit 1;
fi


if [ $baseline_type = 'baseline-1' ]; then

  # Download  VoxCeleb-1,2 corpus for training anonymization system models
  if $download_full && [[ $stage -le 2 ]]; then
    printf "${GREEN}\nStage $stage: In order to download VoxCeleb-1,2 corpus, please go to: http://www.robots.ox.ac.uk/~vgg/data/voxceleb/ ...${NC}\n"
    sleep 10; 
  fi

  # Download LibriSpeech data sets for training anonymization system (train-other-500, train-clean-100) 
  if $download_full && [[ $stage -le 3 ]]; then
    printf "${GREEN}\nStage $stage: Downloading LibriSpeech data sets for training anonymization system $libri_train_sets...${NC}\n"
    local/main_download_and_untar_libri.sh || exit 1
  fi

  # Download LibriTTS data sets for training anonymization system (train-other-500, train-clean-100)
  if $download_full && [[ $stage -le 4 ]]; then
    printf "${GREEN}\nStage $stage: Downloading LibriTTS data sets for training anonymization system libritts_train_sets...${NC}\n"
    local/main_download_and_untar_libritts.sh || exit 1
  fi
   
  # Extract xvectors from anonymization pool
  if [ $stage -le 5 ]; then
    # Prepare data for libritts-train-other-500
    printf "${GREEN}\nStage $stage: Prepare anonymization pool data...${NC}\n"
    local/main_data_prep_libritts.sh || exit 1
  fi
    
  if [ $stage -le 6 ]; then
    printf "${GREEN}\nStage $stage: Extracting xvectors for anonymization pool...${NC}\n"
    local/main_extract_xvectors_pool.sh || exit 1
  fi

fi # baseline-1


# Make evaluation data
if [ $stage -le 8 ]; then
  printf "${GREEN}\nStage $stage: Making evaluation subsets...${NC}\n"
  local/main_make_eval_data.sh || exit 1
fi


# Anonymization
if [ $stage -le 9 ]; then
  printf "${GREEN}\nStage $stage: Anonymizing evaluation datasets...${NC}\n"
  local/main_anonymization.sh || exit 1
fi


# Make VCTK anonymized evaluation subsets
if [ $stage -le 10 ]; then
  printf "${GREEN}\nStage $stage: Making VCTK anonymized evaluation subsets...${NC}\n"
  local/main_make_vctk_anon_eval_sets.sh || exit 1
fi


if [ $stage -le 11 ]; then
  printf "${GREEN}\n Stage $stage: Evaluate datasets using speaker verification...${NC}\n"
  for suff in dev test; do
    printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f --results $results || exit 1;
    printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: libri_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m --results $results || exit 1;
    printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: libri_${suff}_trials_m, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_f$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_m$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f_common --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f_common$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_f_common$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m_common --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m_common$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_m_common$anon_data_suffix --results $results || exit 1;
  done
fi




echo Done
exit










# Make ASR evaluation subsets
if [ $stage -le 12 ]; then
  printf "${GREEN}\nStage $stage: Making ASR evaluation subsets...${NC}\n"
  for suff in dev test; do
    for name in data/libri_${suff}_{trials_f,trials_m} data/libri_${suff}_{trials_f,trials_m}$anon_data_suffix \
        data/vctk_${suff}_{trials_f_all,trials_m_all} data/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix; do
      [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
    done
    utils/combine_data.sh data/libri_${suff}_asr data/libri_${suff}_{trials_f,trials_m} || exit 1
    utils/combine_data.sh data/libri_${suff}_asr$anon_data_suffix data/libri_${suff}_{trials_f,trials_m}$anon_data_suffix || exit 1
    utils/combine_data.sh data/vctk_${suff}_asr data/vctk_${suff}_{trials_f_all,trials_m_all} || exit 1
    utils/combine_data.sh data/vctk_${suff}_asr$anon_data_suffix data/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix || exit 1
  done
fi

if [ $stage -le 13 ]; then
  for dset in libri vctk; do
    for suff in dev test; do
      for data in ${dset}_${suff}_asr ${dset}_${suff}_asr$anon_data_suffix; do
        printf "${GREEN}\nStage $stage: Performing intelligibility assessment using ASR decoding on $dset...${NC}\n"
        local/asr_eval.sh --nj $nj --dset $data --model $asr_eval_model --results $results || exit 1;
      done
    done
  done
fi

if [ $stage -le 14 ]; then
  printf "${GREEN}\nStage $stage: Collecting results${NC}\n"
  expo=$results/results.txt
  for name in `find $results -type d -name "ASV-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
    #for label in 'EER:' 'minDCF(p-target=0.01):' 'minDCF(p-target=0.001):'; do
    for label in 'EER:'; do
      value=$(grep "$label" $name/EER)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/Cllr ] && echo "Directory $name/Cllr does not exist" && exit 1
    for label in 'Cllr (min/act):' 'ROCCH-EER:'; do
      value=$(grep "$label" $name/Cllr)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/linkability_log ] && echo "Directory $name/linkability_log does not exist" && exit 1
    for label in 'linkability:'; do
      value=$(grep "$label" $name/linkability_log)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/zebra ] && echo "Directory $name/zebra does not exist" && exit 1
    for label in 'Population:' 'Individual:'; do
      value=$(grep "$label" $name/zebra)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
  done
  for name in `find $results -type f -name "ASR-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    while read line; do
      echo "  $line" | tee -a $expo
    done < $name
  done
fi

if [ $stage -le 15 ]; then
   printf "${GREEN}\nStage $stage: Compute the de-indentification and the voice-distinctiveness preservation with the similarity matrices${NC}\n"
   for suff in dev test; do
      for data in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
         printf "${BLUE}\nStage 15: Compute the de-indentification and the voice-distinctiveness for $data${NC}\n"
         local/similarity_matrices/compute_similarity_matrices_metrics.sh --asv_eval_model $asv_eval_model --plda_dir $plda_dir --set_test $data --results $results || exit 1;
     done
   done
fi

if [ $stage -le 16 ]; then
   printf "${GREEN}\nStage $stage: Collecting results for re-indentification and the voice-distinctiveness preservation${NC}\n"
  expo=$results/results.txt
  dir="similarity_matrices_DeID_Gvd"
  for suff in dev test; do
     for name in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
       echo "$name" | tee -a $expo
	   echo $results/$dir/$name/DeIDentification
       [ ! -f $results/$dir/$name/DeIDentification ] && echo "File $results/$dir/$name/DeIDentification does not exist" && exit 1
       label='De-Identification :'
       value=$(grep "$label" $results/$dir/$name/DeIDentification)
       value=$(echo $value)
       echo "  $value" | tee -a $expo
	   [ ! -f $results/$dir/$name/gain_of_voice_distinctiveness ] && echo "File $name/gain_of_voice_distinctiveness does not exist" && exit 1
       label='Gain of voice distinctiveness :'
       value=$(grep "$label" $results/$dir/$name/gain_of_voice_distinctiveness)
       value=$(echo $value)
       echo "  $value" | tee -a $expo
     done
  done
fi

if [ $stage -le 17 ]; then
  printf "${GREEN}\nStage $stage: Summarizing ZEBRA plots for all experiments${NC}\n"
  mkdir -p voiceprivacy-challenge-2020
  PYTHONPATH=$(realpath ../zebra) python ../zebra/voiceprivacy_challenge_plots.py || exit 1
fi

echo Done
