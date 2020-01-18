#!/bin/bash

set -e

#export CUDA_VISIBLE_DEVICES=1,2,3,4,5,6,7

. cmd.sh
. path.sh

# nnet3-am-copy --raw=true --prepare-for-test=true --nnet-config='echo output-node name=output input=prefinal-l |' --edits='remove-orphans' final.mdl prefinal-l.raw

nj=1
cmd=run.pl
use_gpu=yes
iv_root=exp/nnet3_cleaned
model_dir=exp/chain_cleaned/tdnn_1d_sp
md_name=prefinal-l.raw
cmvn_op='--norm-means=false --norm-vars=false'

. parse_options.sh

dsets="$1"
ppg_dir="$2"

for dset in $dsets; do
  ivect=scp:$iv_root/ivector_online.scp
  expo=$ppg_dir
  mark=$expo/.done
  if [ ! -f $mark ]; then
    data=data/${dset}_hires
    for name in $data/feats.scp $model_dir/$md_name; do
      [ ! -f $name ] && echo "File $name does not exist" && exit 1
    done
    sdata=$data/split$nj
    [[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;
    feats="ark:apply-cmvn $cmvn_op --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- |"
    [ -d $expo ] && rm -r $expo
    mkdir -p $expo/log
    mkdir -p $expo/data
    $cmd JOB=1:$nj $expo/log/ppg256_${dset}.JOB.log \
      nnet3-compute \
        --extra-left-context=0 --extra-right-context=0 \
        --extra-left-context-initial=-1 --extra-right-context-final=-1 \
        --frames-per-chunk=50 --use-gpu=$use_gpu --online-ivector-period=10 \
        --online-ivectors=$ivect $model_dir/$md_name "$feats" ark:- \| \
        copy-feats --compress=true ark:- \
            ark,scp:$expo/data/feats.JOB.ark,$expo/data/feats.JOB.scp || exit 1
    cat $expo/data/feats.*.scp | sort > $expo/phone_post.scp
    rm $expo/data/feats.*.scp
    touch $mark
  fi
done

echo Done
