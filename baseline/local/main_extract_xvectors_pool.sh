#!/bin/bash

set -e

. ./config.sh

if [ $xvect_type = "kaldi" ]; then
    local/featex/01_extract_xvectors_kaldi.sh --nj $nj data/${anoni_pool} ${xvec_nnet_dir} ${anon_xvec_out_dir} || exit 1
elif [ $xvect_type = "sidekit" ]; then
  local/featex/01_extract_xvectors_sidekit.sh data/${anoni_pool} ${xvec_nnet_dir} ${anon_xvec_out_dir} || exit 1
fi

echo '  Done'
