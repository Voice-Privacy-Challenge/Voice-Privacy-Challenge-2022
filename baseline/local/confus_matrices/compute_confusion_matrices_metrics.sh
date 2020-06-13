#!/bin/bash 

. ./cmd.sh
. ./path.sh

set -e

set_test=$1
results=$2

anon_data_suffix=_anon
asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=$asv_eval_model/xvect_train_clean_360
osp_set_folder=$asv_eval_model/xvect_$set_test
asp_set_folder=${osp_set_folder}$anon_data_suffix
utt2spk=data/$set_test/utt2spk

exp_files_dir=$results/confusion_matrices_de-id_vu/$set_test/exp_files

if [ ! -d "$exp_files_dir" ]; then
	mkdir -p $exp_files_dir
fi

cat $osp_set_folder/xvector.scp | cut -d' ' -f1 > $exp_files_dir/segments_osp_set.scp &
cat $asp_set_folder/xvector.scp | cut -d' ' -f1 > $exp_files_dir/segments_asp_set.scp

python3 local/confus_matrices/create_trial.py $exp_files_dir/segments_osp_set.scp $exp_files_dir/segments_osp_set.scp osp_osp $exp_files_dir/ $utt2spk &
python3 local/confus_matrices/create_trial.py $exp_files_dir/segments_osp_set.scp $exp_files_dir/segments_asp_set.scp osp_asp $exp_files_dir/ $utt2spk &
python3 local/confus_matrices/create_trial.py $exp_files_dir/segments_asp_set.scp $exp_files_dir/segments_asp_set.scp asp_asp $exp_files_dir/ $utt2spk &
wait

#Compute scores Osp-Osp
$train_cmd $exp_files_dir/scores/log/test_scoring.log \
  ivector-plda-scoring --normalize-length=true \
  "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$osp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$osp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "cat $exp_files_dir/segments_osp_osp_trial.txt | cut -d\  --fields=1,2 |" $exp_files_dir/scores_output_osp_osp || exit 1;


#Compute scores Osp-Asp
$train_cmd $exp_files_dir/scores/log/test_scoring.log \
  ivector-plda-scoring --normalize-length=true \
  "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$osp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$asp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "cat $exp_files_dir/segments_osp_asp_trial.txt | cut -d\  --fields=1,2 |" $exp_files_dir/scores_output_osp_asp || exit 1;


#Compute scores Asp-Asp
$train_cmd $exp_files_dir/scores/log/test_scoring.log \
  ivector-plda-scoring --normalize-length=true \
  "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$asp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:$asp_set_folder/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
  "cat $exp_files_dir/segments_asp_asp_trial.txt | cut -d\  --fields=1,2 |" $exp_files_dir/scores_output_asp_asp || exit 1;


python3 local/confus_matrices/scores_calibration.py $exp_files_dir/scores_output_osp_osp $exp_files_dir/spk_osp_osp_trial.txt &
python3 local/confus_matrices/scores_calibration.py $exp_files_dir/scores_output_osp_asp $exp_files_dir/spk_osp_asp_trial.txt &
python3 local/confus_matrices/scores_calibration.py $exp_files_dir/scores_output_asp_asp $exp_files_dir/spk_asp_asp_trial.txt &
wait

python3 local/confus_matrices/compute_confusion_matrix.py $exp_files_dir/scores_output_osp_osp.calibrated $exp_files_dir/spk_osp_osp_trial.txt.calibrated $results/confusion_matrices_de-id_vu/$set_test osp_osp &
python3 local/confus_matrices/compute_confusion_matrix.py $exp_files_dir/scores_output_osp_asp.calibrated $exp_files_dir/spk_osp_asp_trial.txt.calibrated $results/confusion_matrices_de-id_vu/${set_test} osp_asp &
python3 local/confus_matrices/compute_confusion_matrix.py $exp_files_dir/scores_output_asp_asp.calibrated $exp_files_dir/spk_asp_asp_trial.txt.calibrated $results/confusion_matrices_de-id_vu/${set_test} asp_asp &
wait

de_id=$(python3 local/confus_matrices/compute_deid.py $results/confusion_matrices_de-id_vu/${set_test}/confusion_matrix_osp_osp.npy $results/confusion_matrices_de-id_vu/${set_test}/confusion_matrix_osp_asp.npy)
vu=$(python3 local/confus_matrices/compute_vu.py $results/confusion_matrices_de-id_vu/${set_test}/confusion_matrix_osp_osp.npy $results/confusion_matrices_de-id_vu/${set_test}/confusion_matrix_asp_asp.npy)

echo "Set : $set_test"
echo "  De-Identification effect : $de_id"
echo "  VU effect : $vu"

echo "De-Identification : $de_id" > $results/confusion_matrices_de-id_vu/$set_test/de-identification
echo "Gain of voice uniqueness : $vu" > $results/confusion_matrices_de-id_vu/$set_test/gain_of_voice_uniqueness

