#!/bin/bash
#Compute pitch/prosody correlation metric
set -e

. ./config.sh


for suff in $eval_subsets; do
  for data in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
    printf "${BLUE}\n Compute prosody correlation between original and anonymized data for $data${NC}\n"
    local/compute_pitch_corr.sh --data $data || exit 1;
  done
done

echo '  Done'
