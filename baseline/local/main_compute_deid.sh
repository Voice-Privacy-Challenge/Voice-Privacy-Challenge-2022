#!/bin/bash
#Compute the de-indentification and the voice-distinctiveness preservation with the similarity matrices
set -e

. ./config.sh

plda_dir=${asv_eval_model} # ASV_eval model (plda)
for suff in $eval_subsets; do
  for data in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
    printf "${BLUE}\n Compute the de-indentification and the voice-distinctiveness for $data${NC}\n"
    local/similarity_matrices/compute_similarity_matrices_metrics.sh --asv_eval_model $asv_eval_model --plda_dir $plda_dir --data $data --results $results || exit 1;
  done
done

echo '  Done'
