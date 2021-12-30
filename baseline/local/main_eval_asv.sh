#!/bin/bash

set -e

. ./config.sh

if [ $train_asv_eval ]; then
  asv_eval_model=$asv_eval_model_trained
  echo "The user trained ASV model $asv_eval_model will be used in evaluation"
else
  echo "The pretrained (downloaded) ASV model $asv_eval_model will be used in evaluation"
fi

for suff in $eval_subsets; do
  echo suff=$suff
  plda_dir=${asv_eval_model} # ASV_eval model (plda)
  echo plda_dir=$plda_dir
  printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
  local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
  local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
  local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1

  printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
  local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m --results $results || exit 1
  printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
  local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1
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

echo '  Done'
