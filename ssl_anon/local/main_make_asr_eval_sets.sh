#!/bin/bash

set -e

. ./config.sh

for suff in $eval_subsets; do
  for name in data/libri_${suff}_{trials_f,trials_m} data/libri_${suff}_{trials_f,trials_m}$anon_data_suffix \
      data/vctk_${suff}_{trials_f_all,trials_m_all} data/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix; do
    [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
  done
  utils/combine_data.sh data/libri_${suff}_asr data/libri_${suff}_{trials_f,trials_m} || exit 1
  utils/combine_data.sh data/libri_${suff}_asr$anon_data_suffix data/libri_${suff}_{trials_f,trials_m}$anon_data_suffix || exit 1
  utils/combine_data.sh data/vctk_${suff}_asr data/vctk_${suff}_{trials_f_all,trials_m_all} || exit 1
  utils/combine_data.sh data/vctk_${suff}_asr$anon_data_suffix data/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix || exit 1
done

echo '  Done'
