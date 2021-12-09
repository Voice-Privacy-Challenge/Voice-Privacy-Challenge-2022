#!/bin/bash

set -e

#export CUDA_VISIBLE_DEVICES=1,2,3,4,5,6,7

. ./cmd.sh
. ./path.sh

nj=20
dsets=
. parse_options.sh

for dset in $dsets; do
  expo=data/${dset}_hires
  mark=$expo/.done
  if [ ! -f $mark ]; then
    [ -d $expo ] && rm -r $expo
	utils/copy_data_dir.sh data/$dset $expo || exit 1
    steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
      --cmd "$train_cmd" $expo || exit 1
    steps/compute_cmvn_stats.sh $expo || exit 1
    utils/fix_data_dir.sh $expo || exit 1
	touch $mark
  fi
done

echo Done
