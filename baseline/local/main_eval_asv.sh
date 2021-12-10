#!/bin/bash

set -e

. ./config.sh

if [ $xvect_type = "kaldi" ]; then
  asv_script=local/asv_eval.sh
elif [ $xvect_type = "sidekit" ]; then
  asv_script=local/asv_eval_sidekit.sh
else
  >&2 echo "X-vector type not supported : " $xvect_type
fi

for suff in $eval_subsets; do
  echo suff=$suff
  plda_dir=${asv_eval_model}/xvect_train_clean_360 # ASV_eval model (plda)
  echo plda_dir=$plda_dir
  printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1

  printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_m, enroll - anonymized, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1;

  printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f$anon_data_suffix --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_f$anon_data_suffix --results $results || exit 1;

  printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m$anon_data_suffix --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - anonymized, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_m$anon_data_suffix --results $results || exit 1;

  printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - original, trial - original**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f_common --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - original, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f_common$anon_data_suffix --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - anonymized, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_f_common$anon_data_suffix --results $results || exit 1;

  printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - original, trial - original**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m_common --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - original, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m_common$anon_data_suffix --results $results || exit 1;
  printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - anonymized, trial - anonymized**${NC}\n"
  $asv_script --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_m_common$anon_data_suffix --results $results || exit 1;
done

echo '  Done'
