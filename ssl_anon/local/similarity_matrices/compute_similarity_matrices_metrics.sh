#!/bin/bash 

. ./cmd.sh
. ./path.sh

set -e

#===== begin config =======

set_test=libri_test_trials_f 
results=

asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=$asv_eval_model/xvect_train_clean_360

#=========== end config ===========

. utils/parse_options.sh

anon_data_suffix=_anon
osp_set_folder=$asv_eval_model/xvect_$set_test
psp_set_folder=${osp_set_folder}$anon_data_suffix
utt2spk=data/$set_test/utt2spk

printf "asv_eval_model = $asv_eval_model\n"
printf "set_test = $set_test\n"
printf "plda_dir = $plda_dir\n"
printf "results = $results\n"

exp_files_dir=$results/similarity_matrices_DeID_Gvd/$set_test/exp_files

if [ ! -d "$exp_files_dir" ]; then
	mkdir -p $exp_files_dir
fi

cat $osp_set_folder/xvector.scp | cut -d' ' -f1 > $exp_files_dir/segments_osp_set.scp 
cat $psp_set_folder/xvector.scp | cut -d' ' -f1 > $exp_files_dir/segments_psp_set.scp

python3 local/similarity_matrices/create_trial.py $exp_files_dir/segments_osp_set.scp $exp_files_dir/segments_osp_set.scp osp_osp $exp_files_dir/ $utt2spk 
python3 local/similarity_matrices/create_trial.py $exp_files_dir/segments_osp_set.scp $exp_files_dir/segments_psp_set.scp osp_psp $exp_files_dir/ $utt2spk 
python3 local/similarity_matrices/create_trial.py $exp_files_dir/segments_psp_set.scp $exp_files_dir/segments_psp_set.scp psp_psp $exp_files_dir/ $utt2spk 
wait

#Compute scores Osp-Osp
$train_cmd $exp_files_dir/scores/log/test_scoring.log \
  ivector-plda-scoring --normalize-length=true \
  "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$osp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$osp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "cat $exp_files_dir/segments_osp_osp_trial.txt | cut -d\  --fields=1,2 |" $exp_files_dir/scores_output_osp_osp || exit 1;


#Compute scores Osp-Psp
$train_cmd $exp_files_dir/scores/log/test_scoring.log \
  ivector-plda-scoring --normalize-length=true \
  "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$osp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$psp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "cat $exp_files_dir/segments_osp_psp_trial.txt | cut -d\  --fields=1,2 |" $exp_files_dir/scores_output_osp_psp || exit 1;


#Compute scores Psp-Psp
$train_cmd $exp_files_dir/scores/log/test_scoring.log \
  ivector-plda-scoring --normalize-length=true \
  "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$psp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$psp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "cat $exp_files_dir/segments_psp_psp_trial.txt | cut -d\  --fields=1,2 |" $exp_files_dir/scores_output_psp_psp || exit 1;


python3 local/similarity_matrices/scores_calibration.py $exp_files_dir/scores_output_osp_osp $exp_files_dir/spk_osp_osp_trial.txt 
python3 local/similarity_matrices/scores_calibration.py $exp_files_dir/scores_output_osp_psp $exp_files_dir/spk_osp_psp_trial.txt 
python3 local/similarity_matrices/scores_calibration.py $exp_files_dir/scores_output_psp_psp $exp_files_dir/spk_psp_psp_trial.txt 
wait

python3 local/similarity_matrices/compute_similarity_matrix.py $exp_files_dir/scores_output_osp_osp.calibrated $exp_files_dir/spk_osp_osp_trial.txt.calibrated $results/similarity_matrices_DeID_Gvd/$set_test osp_osp 
python3 local/similarity_matrices/compute_similarity_matrix.py $exp_files_dir/scores_output_osp_psp.calibrated $exp_files_dir/spk_osp_psp_trial.txt.calibrated $results/similarity_matrices_DeID_Gvd/${set_test} osp_psp 
python3 local/similarity_matrices/compute_similarity_matrix.py $exp_files_dir/scores_output_psp_psp.calibrated $exp_files_dir/spk_psp_psp_trial.txt.calibrated $results/similarity_matrices_DeID_Gvd/${set_test} psp_psp 
wait

DeID=$(python3 local/similarity_matrices/compute_DeID.py $results/similarity_matrices_DeID_Gvd/${set_test}/similarity_matrix_osp_osp.npy $results/similarity_matrices_DeID_Gvd/${set_test}/similarity_matrix_osp_psp.npy)
Gvd=$(python3 local/similarity_matrices/compute_Gvd.py $results/similarity_matrices_DeID_Gvd/${set_test}/similarity_matrix_osp_osp.npy $results/similarity_matrices_DeID_Gvd/${set_test}/similarity_matrix_psp_psp.npy)

echo "Set : $set_test"
echo "  De-Identification : $DeID"
echo "  Gain of voice distinctiveness : $Gvd"

echo "De-Identification : $DeID" > $results/similarity_matrices_DeID_Gvd/$set_test/DeIDentification
echo "Gain of voice distinctiveness : $Gvd" > $results/similarity_matrices_DeID_Gvd/$set_test/gain_of_voice_distinctiveness

