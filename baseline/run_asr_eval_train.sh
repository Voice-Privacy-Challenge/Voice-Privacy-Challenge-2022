#!/bin/bash
#ASR_eval training on LibriSpeech train_clean_360 corpus

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

stage=20
nj=$(nproc)
[ $nj -gt 40 ] && nj=40

. utils/parse_options.sh || exit 1

train=$data_to_train_eval_models
dev=libri_dev_asr
test=libri_test_asr
lang=exp/models/asr_eval/lang_nosp #data/lang_nosp
lang_test_tgsmall=exp/models/asr_eval/lang_test_tgsmall #data/lang_nosp_test_tgsmall
#model=$asr_eval_model_trained #directory to save the trained model


if [ $stage -le 0 ]; then
  for part in $dev $test $train; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/$part exp/make_mfcc/$part $mfccdir
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done
fi

if [ $stage -le 1 ]; then
  utils/subset_data_dir.sh --shortest data/$train 5000 data/train_5k
fi

if [ $stage -le 2 ]; then
  steps/train_mono.sh \
    --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_5k $lang exp/mono
fi

if [ $stage -le 3 ]; then
  steps/align_si.sh \
    --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/$train $lang exp/mono exp/mono_ali
  steps/train_deltas.sh \
    --boost-silence 1.25 --cmd "$train_cmd" \
    2000 20000 data/$train $lang \
    exp/mono_ali exp/tri1
    utils/mkgraph.sh \
      $lang_test_tgsmall \
      exp/tri1 exp/tri1/graph_nosp_tgsmall
	#for test in $dev $test; do
	for test in $dev; do
      steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp_tgsmall \
                      data/$test exp/tri1/decode_nosp_tgsmall_$test
    done
fi

if [ $stage -le 4 ]; then
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
                    data/$train $lang exp/tri1 exp/tri1_ali
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
                          --splice-opts "--left-context=3 --right-context=3" 2500 25000 \
                          data/$train $lang exp/tri1_ali exp/tri2b
fi

if [ $stage -le 5 ]; then
  steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true \
                     data/$train $lang exp/tri2b exp/tri2b_ali
  steps/train_sat.sh --cmd "$train_cmd" 3000 45000 \
                     data/$train $lang exp/tri2b_ali exp/tri3b
fi

if [ $stage -le 6 ]; then
  # this does some data-cleaning. The cleaned data should be useful when we add
  local/run_cleanup_segmentation.sh --data "data/$train"
fi

if [ $stage -le 7 ]; then 
  local/chain/run_tdnn_1d__360.sh --stage 15 --train_stage 36
#    --stage 3 --train_stage -10
fi


echo Done
