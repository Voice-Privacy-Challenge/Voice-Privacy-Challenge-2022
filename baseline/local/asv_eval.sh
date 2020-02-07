#!/bin/bash

set -e

. ./cmd.sh
. ./path.sh

asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=${asv_eval_model}/xvect_train_clean_360
asv_eval_sets=vctk_dev
subset=
channel=

. ./utils/parse_options.sh

for name in $plda_dir/plda $plda_dir/mean.vec $plda_dir/transform.mat; do
  [ ! -f $name ] && echo "File $name does not exist" && exit 1
done
for dset in $asv_eval_sets; do
  data=data/$dset
  xvect_dset=$asv_eval_model/xvectors_$dset
  for name in $data/spk2utt $xvect_dset/xvector.scp; do
    [ ! -f $name ] && echo "File $name does not exist" && exit 1
  done
  enrolls=$data/enrolls$channel
  utt2num=$data/utt2num$channel.ark
  for name in $enrolls $utt2num; do
    [ ! -f $name ] && echo "File $name does not exist" && exit 1
  done
  trials=$data/trials$subset$channel
  [ ! -f $trials ] && echo "File $trials does not exist" && exit 1
  expo=$asv_eval_model/scores_$dset$subset$channel
  echo "  dset: $dset  subset: $subset  channel: $channel"
  $train_cmd $expo/log/ivector-plda-scoring.log \
    ivector-plda-scoring --normalize-length=true \
      --num-utts=ark:$utt2num \
      "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
      "ark:cut -d' ' -f1 $enrolls | grep -Ff - $xvect_dset/xvector.scp | ivector-mean ark:$data/spk2utt scp:- ark:- | ivector-subtract-global-mean $plda_dir/mean.vec ark:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
      "ark:cut -d' ' -f2 $trials | sort | uniq | grep -Ff - $xvect_dset/xvector.scp | ivector-subtract-global-mean $plda_dir/mean.vec scp:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
      "cat $trials | cut -d' ' --fields=1,2 |" $expo/scores || exit 1
  eer=`compute-eer <(local/prepare_for_eer.py $trials $expo/scores) 2> /dev/null`
  mindcf1=`sid/compute_min_dcf.py --p-target 0.01 $expo/scores $trials 2> /dev/null`
  mindcf2=`sid/compute_min_dcf.py --p-target 0.001 $expo/scores $trials 2> /dev/null`
  echo "    EER: $eer%" | tee $expo/EER
  echo "    minDCF(p-target=0.01): $mindcf1" | tee -a $expo/EER
  echo "    minDCF(p-target=0.001): $mindcf2" | tee -a $expo/EER
  PYTHONPATH=$(realpath ../cllr) python ../cllr/compute_cllr.py -k $trials -s $expo/scores -e
done

echo '  Done'
