#!/bin/bash

. ./config.sh

[ ! -z $nj ] && echo "nj=$nj"
[ ! -z $baseline_type ] && echo "baseline_type=$baseline_type"

[ ! -z $download_full ] && echo "download_full=$download_full"
[ ! -z $data_url_librispeech ] && echo "data_url_librispeech=$data_url_librispeech"
[ ! -z $data_url_libritts ] && echo "data_url_libritts=$data_url_libritts"
[ ! -z $corpora ] && echo "corpora=$corpora"
[ ! -z $anoni_pool ] && echo "anoni_pool=$anoni_pool"

echo "eval_sets=$eval_sets"
echo "eval_subsets=$eval_subsets"

[ ! -z $anon_level_trials ] && echo "anon_level_trials=$anon_level_trials"
[ ! -z $anon_level_enroll ] && echo "anon_level_enroll=$anon_level_enroll"
[ ! -z $anon_data_suffix ] && echo "anon_data_suffix=$anon_data_suffix"

[ ! -z $mc_coeff_enroll ] && echo "mc_coeff_enroll=$mc_coeff_enroll"
[ ! -z $mc_coeff_trials ] && echo "mc_coeff_trials=$mc_coeff_trials"
[ ! -z $ppg_model ] && echo "ppg_model=$ppg_model"
[ ! -z $ppg_dir ] && echo "ppg_dir=$ppg_dir"
[ ! -z $cross_gender ] && echo "cross_gender=$cross_gender"
[ ! -z $distance ] && echo "distance=$distance"
[ ! -z $proximity ] && echo "proximity=$proximity"

[ ! -z $results ] && echo "results=$results"

[ ! -z $asr_eval_model ] && echo "asr_eval_model=$asr_eval_model"
[ ! -z $asv_eval_model ] && echo "asv_eval_model=$asv_eval_model"
[ ! -z $plda_dir ] && echo "plda_dir=$plda_dir"


echo Done