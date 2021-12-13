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

stage=0

. utils/parse_options.sh || exit 1

# Download development and evaluation datasets
if [ $stage -le 0 ]; then
  printf "${GREEN}\nStage 0: Downloading data...${NC}\n"
  local/main_download_data.sh || exit 1
fi


# Download pretrained models
if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage 1: Downloading pretrained models...${NC}\n"
  local/download_models.sh || exit 1;
fi


if [ $baseline_type = 'baseline-1' ]; then

  # Download  VoxCeleb-1,2 corpus for training anonymization system models
  if $download_full && [[ $stage -le 2 ]]; then
    printf "${GREEN}\nStage 2: In order to download VoxCeleb-1,2 corpus, please go to: http://www.robots.ox.ac.uk/~vgg/data/voxceleb/ ...${NC}\n"
    sleep 10; 
  fi

  # Download LibriSpeech data sets for training anonymization system (train-other-500, train-clean-100) 
  if $download_full && [[ $stage -le 3 ]]; then
    printf "${GREEN}\nStage 3.1: Downloading LibriSpeech data sets for training anonymization system $libri_train_sets...${NC}\n"
    local/main_download_and_untar_libri.sh || exit 1

    printf "${GREEN}\nStage 3.2: Downloading Augmentation data for training anonymization system...${NC}\n"
    cd ../sidekit/egs/libri360_train
    python3 dataprep.py --save-path data --download-augment
    cd -
  fi

  # Download LibriTTS data sets for training anonymization system (train-other-500, train-clean-100)
  if $download_full && [[ $stage -le 4 ]]; then
    printf "${GREEN}\nStage 4: Downloading LibriTTS data sets for training anonymization system libritts_train_sets...${NC}\n"
    local/main_download_and_untar_libritts.sh || exit 1
  fi
   
  # Prepare data for anonymization pool data (libritts-train-other-500)
  if [ $stage -le 5 ]; then
    printf "${GREEN}\nStage 5: Prepare anonymization pool data...${NC}\n"
    local/main_data_prep_libritts.sh || exit 1
  fi
    
  # Extract xvectors from anonymization pool
  if [ $stage -le 6 ]; then
    printf "${GREEN}\nStage 6: Extracting xvectors for anonymization pool...${NC}\n"
    local/main_extract_xvectors_pool.sh || exit 1
  fi

fi # baseline-1


# Make evaluation data
if [ $stage -le 7 ]; then
  printf "${GREEN}\nStage 7: Making evaluation subsets...${NC}\n"
  local/main_make_eval_data.sh || exit 1
fi


# Anonymization
if [ $stage -le 8 ]; then
  printf "${GREEN}\nStage 8: Anonymizing evaluation datasets...${NC}\n"
  local/main_anonymization.sh || exit 1
fi


# Make VCTK anonymized evaluation subsets
if [ $stage -le 9 ]; then
  printf "${GREEN}\nStage 9: Making VCTK anonymized evaluation subsets...${NC}\n"
  local/main_make_vctk_anon_eval_sets.sh || exit 1
fi


# ASV evaluation
if [ $stage -le 10 ]; then
  printf "${GREEN}\n Stage 10: Evaluate datasets using speaker verification...${NC}\n"
  local/main_eval_asv.sh || exit 1
fi


# Make ASR evaluation subsets
if [ $stage -le 11 ]; then
  printf "${GREEN}\nStage 11: Making ASR evaluation subsets...${NC}\n"
  local/main_make_asr_eval_sets.sh || exit 1
fi


# ASR evaluation
if [ $stage -le 12 ]; then
  printf "${GREEN}\nStage 12: Performing intelligibility assessment using ASR decoding...${NC}\n"
  local/main_eval_asr.sh || exit 1
fi


if [ $stage -le 13 ]; then
  printf "${GREEN}\nStage 13: Collecting results${NC}\n"
  local/main_collect_results.sh || exit 1
fi


if [ $stage -le 14 ]; then
  printf "${GREEN}\nStage 14: Compute the de-indentification and the voice-distinctiveness preservation with the similarity matrices${NC}\n"
  local/main_compute_deid.sh || exit 1
fi


if [ $stage -le 15 ]; then
  printf "${GREEN}\nStage 15: Collecting results for re-indentification and the voice-distinctiveness preservation${NC}\n"
  local/main_collect_deid_results.sh || exit 1
fi


if [ $stage -le 16 ]; then
  printf "${GREEN}\nStage 16: Summarizing ZEBRA plots for all experiments${NC}\n"
  local/main_zebra_results.sh || exit 1
fi

echo Done
