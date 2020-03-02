#!/bin/bash
# Script for The First VoicePrivacy Challenge 2020
#
#
# Copyright (C) 2020  <Brij Mohan Lal Srivastava, Natalia Tomashenko, Xin Wang, Jose Patino,...>
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

#===== begin config =======

nj=$(nproc)
stage=0

download_full=false  # If download_full=true all the data that can be used in the training/development will be dowloaded (except for Voxceleb-1,2 corpus); otherwise - only those subsets that are used in the current baseline (with the pretrained models)
data_url_librispeech=www.openslr.org/resources/12  # Link to download LibriSpeech corpus
data_url_libritts=www.openslr.org/resources/60     # Link to download LibriTTS corpus
corpora=corpora


printf -v results '%(%Y-%m-%d-%H-%M-%S)T' -1
results=exp/results-$results

. utils/parse_options.sh || exit 1;

. path.sh
. cmd.sh

# Chain model for BN extraction
ppg_model=exp/models/1_asr_am/exp
ppg_dir=${ppg_model}/nnet3_cleaned

# Chain model for ASR evaluation
asr_eval_model=exp/models/asr_eval

# x-vector extraction
xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a
anon_xvec_out_dir=${xvec_nnet_dir}/anon

# ASV_eval config
asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=${asv_eval_model}/xvect_train_clean_360

anon_data_suffix=_anon

#McAdams anonymisation configs
n_lpc=20
mcadams=0.8

#=========== end config ===========

# Download datasets
if [ $stage -le 0 ]; then
  for dset in libri vctk; do
    for suff in dev test; do
      printf "${GREEN}\nStage 0: Downloading ${dset}_${suff} set...${NC}\n"
      local/download_data.sh ${dset}_${suff} || exit 1;
    done
  done
fi

# Download pretrained models
if [ $stage -le 1 ]; then
  printf "${GREEN}\nStage 1: Downloading pretrained models...${NC}\n"
  local/download_models.sh || exit 1;
fi
data_netcdf=$(realpath exp/am_nsf_data)   # directory where features for voice anonymization will be stored
mkdir -p $data_netcdf || exit 1;

# Make evaluation data
if [ $stage -le 8 ]; then
  printf "${GREEN}\nStage 8: Making evaluation subsets...${NC}\n"
  temp=$(mktemp)
  for suff in dev test; do
    for name in data/libri_$suff/{enrolls,trials_f,trials_m} \
        data/vctk_$suff/{enrolls_mic2,trials_f_common_mic2,trials_f_mic2,trials_m_common_mic2,trials_m_mic2}; do
      [ ! -f $name ] && echo "File $name does not exist" && exit 1
    done

    dset=data/libri_$suff
    utils/subset_data_dir.sh --utt-list $dset/enrolls $dset ${dset}_enrolls || exit 1
    cp $dset/enrolls ${dset}_enrolls || exit 1

    cut -d' ' -f2 $dset/trials_f | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${dset}_trials_f || exit 1
    cp $dset/trials_f ${dset}_trials_f/trials || exit 1

    cut -d' ' -f2 $dset/trials_m | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${dset}_trials_m || exit 1
    cp $dset/trials_m ${dset}_trials_m/trials || exit 1

    utils/combine_data.sh ${dset}_trials_all ${dset}_trials_f ${dset}_trials_m || exit 1
    cat ${dset}_trials_f/trials ${dset}_trials_m/trials > ${dset}_trials_all/trials

    dset=data/vctk_$suff
    utils/subset_data_dir.sh --utt-list $dset/enrolls_mic2 $dset ${dset}_enrolls || exit 1
    cp $dset/enrolls_mic2 ${dset}_enrolls/enrolls || exit 1

    cut -d' ' -f2 $dset/trials_f_mic2 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${dset}_trials_f || exit 1
    cp $dset/trials_f_mic2 ${dset}_trials_f/trials || exit 1

    cut -d' ' -f2 $dset/trials_f_common_mic2 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${dset}_trials_f_common || exit 1
    cp $dset/trials_f_common_mic2 ${dset}_trials_f_common/trials || exit 1

    utils/combine_data.sh ${dset}_trials_f_all ${dset}_trials_f ${dset}_trials_f_common || exit 1
    cat ${dset}_trials_f/trials ${dset}_trials_f_common/trials > ${dset}_trials_f_all/trials

    cut -d' ' -f2 $dset/trials_m_mic2 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${dset}_trials_m || exit 1
    cp $dset/trials_m_mic2 ${dset}_trials_m/trials || exit 1

    cut -d' ' -f2 $dset/trials_m_common_mic2 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${dset}_trials_m_common || exit 1
    cp $dset/trials_m_common_mic2 ${dset}_trials_m_common/trials || exit 1

    utils/combine_data.sh ${dset}_trials_m_all ${dset}_trials_m ${dset}_trials_m_common || exit 1
    cat ${dset}_trials_m/trials ${dset}_trials_m_common/trials > ${dset}_trials_m_all/trials

    utils/combine_data.sh ${dset}_trials_all ${dset}_trials_f_all ${dset}_trials_m_all || exit 1
    cat ${dset}_trials_f_all/trials ${dset}_trials_m_all/trials > ${dset}_trials_all/trials
  done
  rm $temp
fi

# Extract xvectors from data which has to be anonymized
if [ $stage -le 9 ]; then
  printf "${GREEN}\nStage 9: Anonymizing evaluation datasets...${NC}\n"
  #for dset in libri_dev_{enrolls,trials_f}; do
   for dset in libri_dev_{enrolls,trials_f,trials_m} \
              vctk_dev_{enrolls,trials_f_all,trials_m_all} \
              libri_test_{enrolls,trials_f,trials_m} \
              vctk_test_{enrolls,trials_f_all,trials_m_all}; do
     #copy content of the folder to the new folder
     cp -r data/$dset data/$dset$anon_data_suffix
     
     #create folder that will contain the anonymised wav files
     mkdir -p data/$dset$anon_data_suffix/wav
     
     #anonymise subset based on the current wav.scp file 
     python local/anon/anonymise_dir_mcadams.py --data_dir=data/$dset --anon_suffix=$anon_data_suffix --n_coeffs=$n_lpc --mc_coeff=$mcadams     
     
     echo $dset
     #overwrite wav.scp file with new anonymised content
     #note sox is inclued to by-pass that files written by local/anon/anonymise_dir_mcadams.py were in float32 format and not pcm
     ls data/$dset$anon_data_suffix/wav/*/*.wav | awk -F'[/.]' '{print $5 " sox " $0 " -t wav -r 16000 -b 16 - |"}' > data/$dset$anon_data_suffix/wav.scp
  done
fi

# Make VCTK anonymized evaluation subsets
if [ $stage -le 10 ]; then
  printf "${GREEN}\nStage 10: Making VCTK anonymized evaluation subsets...${NC}\n"
  temp=$(mktemp)
  for suff in dev test; do
    dset=data/vctk_$suff
    for name in ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_m_all$anon_data_suffix; do
      [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
    done
    cut -d' ' -f2 ${dset}_trials_f/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_f${anon_data_suffix} || exit 1
    cp ${dset}_trials_f/trials ${dset}_trials_f${anon_data_suffix} || exit 1

    cut -d' ' -f2 ${dset}_trials_f_common/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_f_common${anon_data_suffix} || exit 1
    cp ${dset}_trials_f_common/trials ${dset}_trials_f_common${anon_data_suffix} || exit 1

    cut -d' ' -f2 ${dset}_trials_m/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_m_all$anon_data_suffix ${dset}_trials_m${anon_data_suffix} || exit 1
    cp ${dset}_trials_m/trials ${dset}_trials_m${anon_data_suffix} || exit 1

    cut -d' ' -f2 ${dset}_trials_m_common/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_m_all$anon_data_suffix ${dset}_trials_m_common${anon_data_suffix} || exit 1
    cp ${dset}_trials_m_common/trials ${dset}_trials_m_common${anon_data_suffix} || exit 1
  done
  rm $temp
fi

if [ $stage -le 11 ]; then
  printf "${GREEN}\nStage 11: Evaluate datasets using speaker verification...${NC}\n"
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

# Make ASR evaluation subsets
if [ $stage -le 12 ]; then
  printf "${GREEN}\nStage 12: Making ASR evaluation subsets...${NC}\n"
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
        printf "${GREEN}\nStage 13: Performing intelligibility assessment using ASR decoding on $dset...${NC}\n"
        local/asr_eval.sh --nj $nj --dset $data --model $asr_eval_model --results $results || exit 1;
      done
    done
  done
fi

if [ $stage -le 14 ]; then
  printf "${GREEN}\nStage 14: Collecting results${NC}\n"
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
  done
  for name in `find $results -type f -name "ASR-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    while read line; do
      echo "  $line" | tee -a $expo
    done < $name
  done
fi

echo Done
