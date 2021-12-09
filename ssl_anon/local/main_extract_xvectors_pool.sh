#!/bin/bash

set -e

. ./config.sh

local/featex/01_extract_xvectors.sh --nj $nj data/${anoni_pool} ${xvec_nnet_dir} ${anon_xvec_out_dir} || exit 1

echo '  Done'
