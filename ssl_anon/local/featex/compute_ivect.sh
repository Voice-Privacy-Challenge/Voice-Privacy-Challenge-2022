#!/bin/bash

set -e

#export CUDA_VISIBLE_DEVICES=1,2,3,4,5,6,7

. ./cmd.sh
. ./path.sh

nj=20
model=exp/nnet3_cleaned
dsets=

. parse_options.sh

for dset in $dsets; do
  expo=$model/ivectors_${dset}_hires
  mark=$expo/.done
  if [ ! -f $mark ]; then
    [ -d $expo ] && rm -r $expo
    steps/online/nnet2/extract_ivectors_online.sh \
	  --cmd "$train_cmd" --nj $nj data/${dset}_hires \
	  $model/extractor $expo || exit 1
	touch $mark
  fi
done

echo Done
