#!/bin/bash

#
# Extract PPGs using chain model
# This script extract word position dependent phonemes (346) posteriors
#
. path.sh
. cmd.sh

nj=32
stage=0

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <srcdir> <model-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  echo "   --stage=0     # Extraction stage"
  exit 1;
fi

data=$1
model_dir=$2

original_data_dir=data/${data}

data_dir=data/${data}_hires

ivec_extractor=${model_dir}/extractor
ivec_data_dir=${model_dir}/ivectors_${data}_hires

graph_dir=${model_dir}/graph_tgsmall
large_lang_dir=${model_dir}/lang_test_tglarge
small_lang_dir=${model_dir}/lang_test_tgsmall

export LC_ALL=C
if [ $stage -le 0 ]; then
  utils/copy_data_dir.sh ${original_data_dir} ${data_dir}
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
	--cmd "$train_cmd" ${data_dir}
  steps/compute_cmvn_stats.sh ${data_dir} || exit 1;
  utils/fix_data_dir.sh ${data_dir}

  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
       	${data_dir} ${ivec_extractor} ${ivec_data_dir} 
fi

if [ $stage -le 1 ]; then
  steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
    --nj $nj --cmd "$decode_cmd" \
    --online-ivector-dir ${ivec_data_dir} \
    $graph_dir ${data_dir} ${model_dir}/decode_${data}_tgsmall || exit 1
  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" ${small_lang_dir} ${large_lang_dir} \
    ${data_dir} ${model_dir}/decode_${data}_{tgsmall,tglarge} || exit 1

  grep WER ${model_dir}/decode_${data}_tglarge/wer* | utils/best_wer.sh;
  grep WER ${model_dir}/decode_${data}_tgsmall/wer* | utils/best_wer.sh;
fi
