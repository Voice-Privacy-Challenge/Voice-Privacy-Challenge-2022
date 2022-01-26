#!/bin/bash
# Collecting results for re-indentification and the voice-distinctiveness preservation
set -e

. ./config.sh

expo=$results/results.txt
echo expo=$expo
dir="similarity_matrices_DeID_Gvd"
for suff in $eval_subsets; do
   for name in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
     echo "$name" | tee -a $expo
     echo $results/$dir/$name/DeIDentification
     [ ! -f $results/$dir/$name/DeIDentification ] && echo "File $results/$dir/$name/DeIDentification does not exist" && exit 1
     label='De-Identification :'
     value=$(grep "$label" $results/$dir/$name/DeIDentification)
     value=$(echo $value)
     echo "  $value" | tee -a $expo
     [ ! -f $results/$dir/$name/gain_of_voice_distinctiveness ] && echo "File $name/gain_of_voice_distinctiveness does not exist" && exit 1
     label='Gain of voice distinctiveness :'
     value=$(grep "$label" $results/$dir/$name/gain_of_voice_distinctiveness)
     value=$(echo $value)
     echo "  $value" | tee -a $expo
   done
done

echo '  Done'


# Summary
expo=$results/results_summary.txt
for suff in $eval_subsets; do
   for name in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
     echo "$name" | tee -a $expo
     [ ! -f $results/$dir/$name/gain_of_voice_distinctiveness ] && echo "File $name/gain_of_voice_distinctiveness does not exist" && exit 1
     label='Gain of voice distinctiveness :'
     value=$(grep "$label" $results/$dir/$name/gain_of_voice_distinctiveness)
     value=$(echo $value)
     echo "  $value" | tee -a $expo
   done
done

echo '  Done'