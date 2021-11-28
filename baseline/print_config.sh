#!/bin/bash

. ./config.sh

export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export RED='\033[0;31m'
export C='\033[0;36m'
export NC='\033[0m' # No Color

print_var()
{
	[ ! -z "$1" ] && echo "$2='$1'"
}

echo -e "\n${GREEN}\nCommon settings:${NC}"
print_var "$nj" nj
print_var "$baseline_type" baseline_type

echo -e "\n${GREEN}Evaluation data sets:${NC}"
print_var "$eval_sets" eval_sets
print_var "$eval_subsets" eval_subsets

echo -e "\n${GREEN}Download settings:${NC}"
print_var "$download_full" download_full

if [ $download_full = 'true' ]; then
  print_var "$data_url_librispeech" data_url_librispeech
  print_var "$data_url_libritts" data_url_libritts
  print_var "$corpora" corpora
  print_var "$libri_train_clean_100" libri_train_clean_100
  print_var "$libri_train_other_500" libri_train_other_500
  print_var "$libri_train_sets" libri_train_sets
  print_var "$libritts_train_clean_100" libritts_train_clean_100
  print_var "$libritts_train_other_500" libritts_train_other_500
  print_var "$libritts_train_sets" libritts_train_sets
  echo -e "${BLUE}Output:${NC}"
  echo "    Directory to save downloaded corpora: $corpora"
  echo "    Directory to save downloaded LibriSpeech datasets ($libri_train_clean_100, $libri_train_other_500): $corpora\LibriSpeech"
  echo "    Directory to save downloaded LibriTTS datasets ($libritts_train_clean_100, $libritts_train_other_500): $corpora\LibriTTS"
fi


if [ $baseline_type != 'baseline-2' ]; then
  
  echo -e "\n${GREEN}Prepare data for anonymization pool:${NC}"
  print_var "$anoni_pool" anoni_pool
  echo -e "${BLUE}Input:${NC}"
  echo "    Corpus for anonymization pool: $corpora/LibriTTS/${libritts_train_other_500}"
  echo -e "${BLUE}Output:${NC}"
  echo "    Directory to save prepared data for anonymization pool: data/$anoni_pool"

  echo -e "\n${GREEN}Extract x-vectors for anonymization pool:${NC}"
  print_var "$xvec_nnet_dir" xvec_nnet_dir
  print_var "$anon_xvec_out_dir" anon_xvec_out_dir
  echo -e "${BLUE}Input:${NC}"
  echo "    Path to the x-vector extractor: $xvec_nnet_dir"
  echo "    Path to the prepared data for anonymization pool: data/$anoni_pool"
  echo -e "${BLUE}Output:${NC}"
  echo "    Path to the output directory to save x-vectors: $anon_xvec_out_dir"
fi
  
echo -e "\n${GREEN}Make evaluation data:${NC}"
echo -e "${BLUE}Input:${NC}"
echo "    Paths to the input data directories:"
echo "                                                 data/libri_dev"
echo "                                                 data/libri_test"
echo "                                                 data/vctk_dev"
echo "                                                 data/vctk_test"
echo -e "${BLUE}Output:${NC}"
echo "    Evaluation datasets with original data:"
echo "                                                 data/libri_dev_{enrolls,trials_f,trials_m}"
echo "                                                 data/vctk_dev_{enrolls,trials_f_all,trials_m_all}"
echo "                                                 data/libri_test_{enrolls,trials_f,trials_m}"
echo "                                                 data/vctk_test_{enrolls,trials_f_all,trials_m_all}"

echo -e "\n${GREEN}Anonymization:${NC}"
print_var "$rand_seed_start" rand_seed_start
print_var "$anon_level_trials" anon_level_trials
print_var "$anon_level_enroll" anon_level_enroll
print_var "$anon_data_suffix" anon_data_suffix

echo -e "\n${C}Parameters for $baseline_type${NC}"
echo -e "${C}-----------------------${NC}"
if [ $baseline_type == 'baseline-2' ]; then
  print_var "$n_lpc" n_lpc
  print_var "$mc_coeff_enroll" mc_coeff_enroll
  print_var "$mc_coeff_trials" mc_coeff_trials
elif [ $baseline_type = 'baseline-1' ] || [ $baseline_type = 'baseline-3' ]; then 
  print_var "$ppg_model" ppg_model
  print_var "$cross_gender" cross_gender
  print_var "$distance" distance
  print_var "$proximity" proximity
  print_var "$anonym_data" anonym_data
  echo -e "${BLUE}Input (for $baseline_type):${NC}"
  echo "    Path to the x-vector extractor: $xvec_nnet_dir"
  echo "    Path to the BN-feature extractor: $ppg_model"
echo -e "${C}-----------------------${NC}"
fi
echo -e "${BLUE}Input (for any baseline):${NC}"
echo "    Path to the original evaluation data sets for anonymization:"
echo "                                                 data/libri_dev_{enrolls,trials_f,trials_m}"
echo "                                                 data/vctk_dev_{enrolls,trials_f_all,trials_m_all}"
echo "                                                 data/libri_test_{enrolls,trials_f,trials_m}"
echo "                                                 data/vctk_test_{enrolls,trials_f_all,trials_m_all}"
echo -e "${BLUE}Output:${NC}"
echo "    Path to the output directory to save anonymized data and intermediate results: $anonym_data"
echo "    Path to the anonymized evaluation data sets:"
echo "                                                 data/libri_dev_{enrolls,trials_f,trials_m}$anon_data_suffix"
echo "                                                 data/vctk_dev_{enrolls,trials_f_all,trials_m_all}$anon_data_suffix"
echo "                                                 data/libri_test_{enrolls,trials_f,trials_m}$anon_data_suffix"
echo "                                                 data/vctk_test_{enrolls,trials_f_all,trials_m_all}$anon_data_suffix"


echo -e "\n${GREEN}Common evaluation settings:${NC}"
print_var "$results" results

echo -e "\n${GREEN}ASR evaluation settings:${NC}"
print_var "$asr_eval_model" asr_eval_model
echo -e "${BLUE}Input:${NC}"
echo "    Path to the ASR_eval model: $asr_eval_model"
echo "    Path to the original evaluation data sets:"
echo "                                                 data/libri_dev_asr"
echo "                                                 data/vctk_dev_asr"
echo "                                                 data/libri_test_asr"
echo "                                                 data/vctk_test_asr"
echo "    Path to the anonymized evaluation data sets:"
echo "                                                 data/libri_dev_asr$anon_data_suffix"
echo "                                                 data/vctk_dev_asr$anon_data_suffix"
echo "                                                 data/libri_test_asr$anon_data_suffix"
echo "                                                 data/vctk_test_asr$anon_data_suffix"
echo -e "${BLUE}Output:${NC}"
echo "    Path to the directory to save ASR results: $results"

echo -e "\n${GREEN}ASV evaluation settings:${NC}"
print_var "$asv_eval_model" asv_eval_model
print_var "$plda_dir" plda_dir
echo -e "${BLUE}Input:${NC}"
echo "    Path to the ASV_eval model: $asv_eval_model"
echo "    Path to the original evaluation data sets:"
echo "                                                 data/libri_dev_{enrolls,trials_f,trials_m}"
echo "                                                 data/vctk_dev_{enrolls,trials_f_all,trials_m_all}"
echo "                                                 data/libri_test_{enrolls,trials_f,trials_m}"
echo "                                                 data/vctk_test_{enrolls,trials_f_all,trials_m_all}"
echo "    Path to the anonymized evaluation data sets:"
echo "                                                 data/libri_dev_{enrolls,trials_f,trials_m}$anon_data_suffix"
echo "                                                 data/vctk_dev_{enrolls,trials_f_all,trials_m_all}$anon_data_suffix"
echo "                                                 data/libri_test_{enrolls,trials_f,trials_m}$anon_data_suffix"
echo "                                                 data/vctk_test_{enrolls,trials_f_all,trials_m_all}$anon_data_suffix"
echo -e "${BLUE}Output:${NC}"
echo "    Path to the directory to save ASV results: $results"


echo Done