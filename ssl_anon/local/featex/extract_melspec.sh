#!/bin/bash

. path.sh
. cmd.sh

mspec_config=conf/mspec.conf
nj=32

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <srcdir> <mspec-destdir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  echo "   --mspec-config=config/mspec.conf  # Melspectrogram config"
  exit 1;
fi

odata_dir=$1
data_dir=$2
mspec_dir=${data_dir}/mspec


utils/copy_data_dir.sh ${odata_dir} ${data_dir}

steps/make_fbank.sh --cmd "$train_cmd" --nj $nj \
       	--fbank-config ${mspec_config} ${data_dir} \
       	exp/make_fbank/${data_dir} $mspec_dir
