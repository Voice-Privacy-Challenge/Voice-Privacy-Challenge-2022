#!/bin/bash

. path.sh
. cmd.sh

nj=20

. utils/parse_options.sh

if [ $# != 1 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  exit 1;
fi

data_dir=$1
pitch_dir=${data_dir}/pitch

local/featex/make_pitch.sh --nj $nj --cmd "$train_cmd" ${data_dir} \
	exp/make_pitch ${pitch_dir}
