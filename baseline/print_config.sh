#!/bin/bash

. ./config.sh

export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

print_var()
{
	[ ! -z "$1" ] && echo "$2='$1'"
}

echo -e "\n${GREEN}\nCommon settings:${NC}"
print_var "$nj" nj
print_var "$baseline_type" baseline_type

echo -e "\n${GREEN}Download settings:${NC}"
print_var "$download_full" download_full
print_var "$data_url_librispeech" data_url_librispeech
print_var "$data_url_libritts" data_url_libritts
print_var "$corpora" corpora
print_var "$anoni_pool" anoni_pool
print_var "$libri_train_clean_100" libri_train_clean_100
print_var "$libri_train_other_500" libri_train_other_500
print_var "$libri_train_sets" libri_train_sets
print_var "$libritts_train_clean_100" libritts_train_clean_100
print_var "$libritts_train_clean_500" libritts_train_clean_500
print_var "$libritts_train_sets" libritts_train_sets

echo -e "\n${GREEN}Evaluation data sets:${NC}"
print_var "$eval_sets" eval_sets
print_var "$eval_subsets" eval_subsets

if [ $baseline_type != 'baseline-2' ]; then
  echo -e "\n${GREEN}Extract x-vectors for anonymization pool:${NC}"
  print_var "$xvec_nnet_dir" xvec_nnet_dir
  print_var "$anon_xvec_out_dir" anon_xvec_out_dir
  echo -e "${BLUE}Import:${NC}"
  echo "    Path to the x-vector extractor: $xvec_nnet_dir"
  echo -e "${BLUE}Export:${NC}"
  echo "    Path to the output directory to save x-vectors: $anon_xvec_out_dir"
fi
  
echo -e "\n${GREEN}Anonymization:${NC}"
print_var "$rand_seed_start" rand_seed_start
print_var "$anon_level_trials" anon_level_trials
print_var "$anon_level_enroll" anon_level_enroll
print_var "$anon_data_suffix" anon_data_suffix


print_var "$mc_coeff_enroll" mc_coeff_enroll
print_var "$mc_coeff_trials" mc_coeff_trials
print_var "$ppg_model" ppg_model
print_var "$ppg_dir" ppg_dir
print_var "$cross_gender" cross_gender
print_var "$distance" distance
print_var "$proximity" proximity

echo -e "\n${GREEN}Common evaluation settings:${NC}"
print_var "$results" results

echo -e "\n${GREEN}ASR evaluation settings:${NC}"
print_var "$asr_eval_model" asr_eval_model
echo -e "${BLUE}Import:${NC}"
echo "    Path to the ASR_eval model: $asr_eval_model"

echo -e "\n${GREEN}ASV evaluation settings:${NC}"
print_var "$asv_eval_model" asv_eval_model
print_var "$plda_dir" plda_dir
echo -e "${BLUE}Import:${NC}"
echo "    Path to the ASV_eval model: $asv_eval_model"
echo "    Path to the PLDA dir: $plda_dir"


echo Done