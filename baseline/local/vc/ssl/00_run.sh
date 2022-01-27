#!/bin/bash

# 1 choose xvect_type --- kaldi or sidekit 
# 2 please open 'ssl_scripts/configs/w2v2_768_context_ft_100h_**.json' and specify:
  ## wav_dir
  ## xv_dir
  ## f0_dir
# 3 go back to the directory baseline/ and run "bash local/vc/ssl/00_run.sh"

xvect_type='kaldi'
#xvect_type='sidekit'

proj_dir=ssl_scripts/

cd ${proj_dir}

if [ "$xvect_type" == "kaldi" ]; then
    python train.py \
	--checkpoint_path checkpoints/vc_w2v2_768_context_ft_100h_kaldi_xv \
	--config configs/w2v2_768_context_ft_100h_kaldi_xv.json
fi

if [ "$xvect_type" == "sidekit" ]; then
     python train.py \
	--checkpoint_path checkpoints/vc_w2v2_768_context_ft_100h_sidekit_xv \
	--config configs/w2v2_768_context_ft_100h_sidekit_xv.json
fi


