#!/bin/bash
# Script for The First VoicePrivacy Challenge 2020
#
# This clean-up script should be used before re-running anonymization system (for example, with different parametrs, models, etc.) 
# in order to delete all old directories (in data, exp, ..., which should be updated) from the previous run of anonymization and evaluation sripts.
#
#

set -e

# ls | awk '{for (i=1; i<=NF; ++i) print $i}' | sort >> ../cleanup.sh

names='
libri_dev_asr
libri_dev_asr_anon
libri_dev_enrolls
libri_dev_enrolls_anon
libri_dev_trials_all
libri_dev_trials_f
libri_dev_trials_f_anon
libri_dev_trials_m
libri_dev_trials_m_anon
libri_test_asr
libri_test_asr_anon
libri_test_enrolls
libri_test_enrolls_anon
libri_test_trials_all
libri_test_trials_f
libri_test_trials_f_anon
libri_test_trials_m
libri_test_trials_m_anon
vctk_dev_asr
vctk_dev_asr_anon
vctk_dev_enrolls
vctk_dev_enrolls_anon
vctk_dev_trials_all
vctk_dev_trials_f
vctk_dev_trials_f_all
vctk_dev_trials_f_all_anon
vctk_dev_trials_f_anon
vctk_dev_trials_f_common
vctk_dev_trials_f_common_anon
vctk_dev_trials_m
vctk_dev_trials_m_all
vctk_dev_trials_m_all_anon
vctk_dev_trials_m_anon
vctk_dev_trials_m_common
vctk_dev_trials_m_common_anon
vctk_test_asr
vctk_test_asr_anon
vctk_test_enrolls
vctk_test_enrolls_anon
vctk_test_trials_all
vctk_test_trials_f
vctk_test_trials_f_all
vctk_test_trials_f_all_anon
vctk_test_trials_f_anon
vctk_test_trials_f_common
vctk_test_trials_f_common_anon
vctk_test_trials_m
vctk_test_trials_m_all
vctk_test_trials_m_all_anon
vctk_test_trials_m_anon
vctk_test_trials_m_common
vctk_test_trials_m_common_anon'

for name in $names; do
  dir=data/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

names='
decode_libri_dev_asr_anon_tglarge
decode_libri_dev_asr_anon_tgsmall
decode_libri_dev_asr_tglarge
decode_libri_dev_asr_tgsmall
decode_libri_test_asr_anon_tglarge
decode_libri_test_asr_anon_tgsmall
decode_libri_test_asr_tglarge
decode_libri_test_asr_tgsmall
decode_vctk_dev_asr_anon_tglarge
decode_vctk_dev_asr_anon_tgsmall
decode_vctk_dev_asr_tglarge
decode_vctk_dev_asr_tgsmall
decode_vctk_test_asr_anon_tglarge
decode_vctk_test_asr_anon_tgsmall
decode_vctk_test_asr_tglarge
decode_vctk_test_asr_tgsmall'

for name in $names; do
  dir=exp/models/asr_eval/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

names='
ivect_libri_dev_asr
ivect_libri_dev_asr_anon
ivect_libri_test_asr
ivect_libri_test_asr_anon
ivect_vctk_dev_asr
ivect_vctk_dev_asr_anon
ivect_vctk_test_asr
ivect_vctk_test_asr_anon'

for name in $names; do
  dir=exp/models/asr_eval/extractor/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

names='
ivectors_libri_dev_enrolls_hires
ivectors_libri_dev_trials_f_hires
ivectors_libri_dev_trials_m_hires
ivectors_libri_test_enrolls_hires
ivectors_libri_test_trials_f_hires
ivectors_libri_test_trials_m_hires
ivectors_vctk_dev_enrolls_hires
ivectors_vctk_dev_trials_f_all_hires
ivectors_vctk_dev_trials_m_all_hires
ivectors_vctk_test_enrolls_hires
ivectors_vctk_test_trials_f_all_hires
ivectors_vctk_test_trials_m_all_hires
ppg_libri_dev_enrolls
ppg_libri_dev_trials_f
ppg_libri_dev_trials_m
ppg_libri_test_enrolls
ppg_libri_test_trials_f
ppg_libri_test_trials_m
ppg_vctk_dev_enrolls
ppg_vctk_dev_trials_f_all
ppg_vctk_dev_trials_m_all
ppg_vctk_test_enrolls
ppg_vctk_test_trials_f_all
ppg_vctk_test_trials_m_all'

for name in $names; do
  dir=exp/models/1_asr_am/exp/nnet3_cleaned/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

names='
xvect_libri_dev_enrolls
xvect_libri_dev_enrolls_anon
xvect_libri_dev_trials_f
xvect_libri_dev_trials_f_anon
xvect_libri_dev_trials_m
xvect_libri_dev_trials_m_anon
xvect_libri_test_enrolls
xvect_libri_test_enrolls_anon
xvect_libri_test_trials_f
xvect_libri_test_trials_f_anon
xvect_libri_test_trials_m
xvect_libri_test_trials_m_anon
xvect_vctk_dev_enrolls
xvect_vctk_dev_enrolls_anon
xvect_vctk_dev_trials_f
xvect_vctk_dev_trials_f_anon
xvect_vctk_dev_trials_f_common
xvect_vctk_dev_trials_f_common_anon
xvect_vctk_dev_trials_m
xvect_vctk_dev_trials_m_anon
xvect_vctk_dev_trials_m_common
xvect_vctk_dev_trials_m_common_anon
xvect_vctk_test_enrolls
xvect_vctk_test_enrolls_anon
xvect_vctk_test_trials_f
xvect_vctk_test_trials_f_anon
xvect_vctk_test_trials_f_common
xvect_vctk_test_trials_f_common_anon
xvect_vctk_test_trials_m
xvect_vctk_test_trials_m_anon
xvect_vctk_test_trials_m_common
xvect_vctk_test_trials_m_common_anon'

for name in $names; do
  dir=exp/models/asv_eval/xvect_01709_1/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

names='
xvectors_libri_dev_enrolls
xvectors_libri_dev_trials_f
xvectors_libri_dev_trials_m
xvectors_libri_test_enrolls
xvectors_libri_test_trials_f
xvectors_libri_test_trials_m
xvectors_vctk_dev_enrolls
xvectors_vctk_dev_trials_f_all
xvectors_vctk_dev_trials_m_all
xvectors_vctk_test_enrolls
xvectors_vctk_test_trials_f_all
xvectors_vctk_test_trials_m_all'

for name in $names; do
  dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

names='
libri_dev_enrolls
libri_dev_trials_f
libri_dev_trials_m
libri_test_enrolls
libri_test_trials_f
libri_test_trials_m
vctk_dev_enrolls
vctk_dev_trials_f_all
vctk_dev_trials_m_all
vctk_test_enrolls
vctk_test_trials_f_all
vctk_test_trials_m_all'

for name in $names; do
  dir=exp/am_nsf_data/$name
  #[ ! -d $dir ] && echo $dir
  if [ -d $dir ]; then echo $dir; rm -r $dir; fi
done

echo Done
