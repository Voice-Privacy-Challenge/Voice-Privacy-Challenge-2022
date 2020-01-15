#!/bin/bash

. ./cmd.sh
. ./path.sh

set -e

#Compute x-vectors using x-vector extractor (trained on VoxCeleb-1,2 data)

nj_mfcc=20
nj_xvec=20
use_gpu=false

model=exp/xvector_nnet_1as
#dsets='train_clean_100'
#dsets='train_other_500'
#dsets='librispeech_dev_clean'
#dsets='librispeech_dev_clean_uniq'
#dsets='vctk_dev'
#dsets='vctk_test'
#dsets='vctk_dev_mic1'
#dsets='vctk_dev_mic2'
dsets='librispeech_train_clean_360_uniq'



for dset in $dsets; do
  data=data/${dset}_mfcc
  mark=$data/.done
  if [ ! -f $mark ]; then
    [ -d $data ] && rm -r $data
	utils/copy_data_dir.sh data/$dset $data
    steps/make_mfcc.sh \
	  --nj $nj_mfcc \
	  --cmd "$train_cmd" \
	  --write-utt2num-frames true \
	  --mfcc-config conf/mfcc.conf \
      $data
    utils/fix_data_dir.sh $data
    sid/compute_vad_decision.sh \
	  --nj $nj_mfcc \
	  --cmd "$train_cmd" \
      $data
    utils/fix_data_dir.sh $data
	touch $mark
  fi
  expo=$model/xvectors_$dset
  mark=$expo/.done
  if [ ! -f $mark ]; then
     [ -d $expo ] && rm -r $expo
    sid/nnet3/xvector/extract_xvectors.sh \
	  --nj $nj_xvec \
	  --cmd "$train_cmd --mem 4G" \
	  --use_gpu $use_gpu \
      $model $data $expo
	touch $mark
  fi
done

echo Done
