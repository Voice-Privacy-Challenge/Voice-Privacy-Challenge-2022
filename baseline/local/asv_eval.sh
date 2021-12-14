#!/bin/bash

set -e

. ./cmd.sh
. ./path.sh
. ./config.sh

nj=$(nproc)
asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=$asv_eval_model/xvect_train_clean_360

#enrolls=vctk_dev_enrolls
#trials=vctk_dev_trials_f_common

enrolls=libri_dev_enrolls
trials=libri_dev_trials_f


. ./utils/parse_options.sh

for name in $asv_eval_model/final.raw $plda_dir/plda $plda_dir/mean.vec \
    $plda_dir/transform.mat data/$enrolls/enrolls data/$trials/trials ; do
  [ ! -f $name ] && echo "File $name does not exist" && exit 1
done

for dset in $enrolls $trials; do
  data=data/$dset
  spk2utt=$data/spk2utt
  [ ! -f $spk2utt ] && echo "File $spk2utt does not exist" && exit 1
  num_spk=$(wc -l < $spk2utt)
  njobs=$([ $num_spk -le $nj ] && echo $num_spk || echo $nj)
  if [ ! -f $data/.done_mfcc ]; then
    printf "${RED}  compute MFCC: $dset${NC}\n"
    steps/make_mfcc.sh --nj $njobs --cmd "$train_cmd" \
      --write-utt2num-frames true $data || exit 1
    utils/fix_data_dir.sh $data || exit 1
    touch $data/.done_mfcc
  fi
  if [ ! -f $data/.done_vad ]; then
    printf "${RED}  compute VAD: $dset${NC}\n"
    sid/compute_vad_decision.sh --nj $njobs --cmd "$train_cmd" $data || exit 1
    utils/fix_data_dir.sh $data || exit 1
    touch $data/.done_vad
  fi
done

for dset in $enrolls $trials; do
  data=data/$dset
  spk2utt=$data/spk2utt
  [ ! -f $spk2utt ] && echo "File $spk2utt does not exist" && exit 1
  num_spk=$(wc -l < $spk2utt)
  njobs=$([ $num_spk -le $nj ] && echo $num_spk || echo $nj)
  expo=$asv_eval_model/xvect_$dset
  if [ ! -f $expo/.done ]; then
    printf "${RED}  compute x-vect: $dset${NC}\n"
    sid/nnet3/xvector/extract_xvectors.sh --nj $njobs --cmd "$train_cmd" \
      $asv_eval_model $data $expo || exit 1
    touch $expo/.done
  fi
done

expo=$results/ASV-$enrolls-$trials
if [ ! -f $expo/.done ]; then
  printf "${RED}  ASV scoring: $expo${NC}\n"
  mkdir -p $expo
  xvect_enrolls=$asv_eval_model/xvect_$enrolls/xvector.scp
  xvect_trials=$asv_eval_model/xvect_$trials/xvector.scp
  for name in $xvect_enrolls $xvect_trials; do
    [ ! -f $name ] && echo "File $name does not exist" && exit 1
  done
  $train_cmd $expo/log/ivector-plda-scoring.log \
    sed -r 's/_|-/ /g' data/$enrolls/enrolls \| awk '{split($1, val, "_"); ++num[val[1]]}END{for (spk in num) print spk, num[spk]}' \| \
      ivector-plda-scoring --normalize-length=true --num-utts=ark:- \
        "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
        "ark:cut -d' ' -f1 data/$enrolls/enrolls | grep -Ff - $xvect_enrolls | ivector-mean ark:data/$enrolls/spk2utt scp:- ark:- | ivector-subtract-global-mean $plda_dir/mean.vec ark:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "ark:cut -d' ' -f2 data/$trials/trials | sort | uniq | grep -Ff - $xvect_trials | ivector-subtract-global-mean $plda_dir/mean.vec scp:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "cat data/$trials/trials | cut -d' ' --fields=1,2 |" $expo/scores || exit 1
  eer=`compute-eer <(local/prepare_for_eer.py data/$trials/trials $expo/scores) 2> /dev/null`
  mindcf1=`sid/compute_min_dcf.py --p-target 0.01 $expo/scores data/$trials/trials 2> /dev/null`
  mindcf2=`sid/compute_min_dcf.py --p-target 0.001 $expo/scores data/$trials/trials 2> /dev/null`
  echo "EER: $eer%" | tee $expo/EER
  echo "minDCF(p-target=0.01): $mindcf1" | tee -a $expo/EER
  echo "minDCF(p-target=0.001): $mindcf2" | tee -a $expo/EER
  PYTHONPATH=$(realpath ../cllr) python ../cllr/compute_cllr.py \
    -k data/$trials/trials -s $expo/scores -e | tee $expo/Cllr || exit 1

  # Compute linkability
  PYTHONPATH=$(realpath ../anonymization_metrics) python local/scoring/linkability/compute_linkability.py \
    -k data/$trials/trials -s $expo/scores \
    -d -o $expo/linkability | tee $expo/linkability_log || exit 1

  # Zebra
  label=$enrolls-$trials
  PYTHONPATH=$(realpath ../zebra) python ../zebra/zero_evidence.py \
    -k data/$trials/trials -s $expo/scores -l $label | tee $expo/zebra || exit 1
    #-k data/$trials/trials -s $expo/scores -l $label -e png | tee $expo/zebra || exit 1

  touch $expo/.done
fi
