#!/bin/bash
#ASR_eval training on LibriSpeech train_clean_360 corpus

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

stage=0
nj=10

. utils/parse_options.sh || exit 1

train=$data_to_train_eval_models
dev=libri_dev_asr
test=libri_test_asr

if [ $stage -le 0 ]; then
  printf "${GREEN}\nStage 0: Download and prepare data for training evaluation models...${NC}\n"
  local/get_train_data.sh || exit 1
fi


if [ $stage -le 6 ]; then
  for part in $dev $test $train; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/$part exp/make_mfcc/$part $mfccdir
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done
fi

if [ $stage -le 7 ]; then
  utils/subset_data_dir.sh --shortest data/$train 5000 data/train_5k
fi

if [ $stage -le 8 ]; then
  steps/train_mono.sh \
    --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_5k data/lang_nosp exp/mono
  (
    utils/mkgraph.sh data/lang_nosp_test_tgsmall exp/mono exp/mono/graph_nosp_tgsmall
    for test in $dev $test; do
      steps/decode.sh \
        --nj $nj --cmd "$decode_cmd" \
        exp/mono/graph_nosp_tgsmall \
        data/$test exp/mono/decode_nosp_tgsmall_$test
    done
  )&
fi

if [ $stage -le 9 ]; then
  steps/align_si.sh \
    --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/$train data/lang_nosp exp/mono exp/mono_ali
  steps/train_deltas.sh \
    --boost-silence 1.25 --cmd "$train_cmd" \
    2000 20000 data/$train data/lang_nosp \
    exp/mono_ali exp/tri1
  (
    utils/mkgraph.sh \
      data/lang_nosp_test_tgsmall \
      exp/tri1 exp/tri1/graph_nosp_tgsmall
    for test in $dev $test; do
      steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp_tgsmall \
                      data/$test exp/tri1/decode_nosp_tgsmall_$test
      steps/lmrescore.sh --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tgmed} \
                         data/$test exp/tri1/decode_nosp_{tgsmall,tgmed}_$test
      steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tglarge} \
        data/$test exp/tri1/decode_nosp_{tgsmall,tglarge}_$test
    done
  )&
fi

if [ $stage -le 10 ]; then
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
                    data/$train data/lang_nosp exp/tri1 exp/tri1_ali
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
                          --splice-opts "--left-context=3 --right-context=3" 2500 25000 \
                          data/$train data/lang_nosp exp/tri1_ali exp/tri2b
  (
    utils/mkgraph.sh data/lang_nosp_test_tgsmall \
                     exp/tri2b exp/tri2b/graph_nosp_tgsmall
    for test in $dev $test; do
      steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri2b/graph_nosp_tgsmall \
                      data/$test exp/tri2b/decode_nosp_tgsmall_$test
      steps/lmrescore.sh --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tgmed} \
                         data/$test exp/tri2b/decode_nosp_{tgsmall,tgmed}_$test
      steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tglarge} \
        data/$test exp/tri2b/decode_nosp_{tgsmall,tglarge}_$test
    done
  )&
fi

if [ $stage -le 11 ]; then
  steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true \
                     data/$train data/lang_nosp exp/tri2b exp/tri2b_ali
  steps/train_sat.sh --cmd "$train_cmd" 3000 45000 \
                     data/$train data/lang_nosp exp/tri2b_ali exp/tri3b
  (
    utils/mkgraph.sh data/lang_nosp_test_tgsmall \
                     exp/tri3b exp/tri3b/graph_nosp_tgsmall
    for test in $dev $test; do
      steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
                            exp/tri3b/graph_nosp_tgsmall data/$test \
                            exp/tri3b/decode_nosp_tgsmall_$test
      steps/lmrescore.sh --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tgmed} \
                         data/$test exp/tri3b/decode_nosp_{tgsmall,tgmed}_$test
      steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tglarge} \
        data/$test exp/tri3b/decode_nosp_{tgsmall,tglarge}_$test
    done
  )&
fi

if [ $stage -le 19 ]; then
  # this does some data-cleaning. The cleaned data should be useful when we add
  # the neural net and chain systems.  (although actually it was pretty clean already.)
  local/run_cleanup_segmentation.sh --data "data/$train"
fi

if [ $stage -le 20 ]; then 
  local/chain/run_tdnn_1d__360.sh
#    --stage 3 --train_stage -10
fi

# The nnet3 TDNN recipe:
# local/nnet3/run_tdnn.sh # set "--stage 11" if you have already run local/chain/run_tdnn.sh

# # train models on cleaned-up data
# # we've found that this isn't helpful-- see the comments in local/run_data_cleaning.sh
# local/run_data_cleaning.sh

# Wait for decodings in the background
wait
echo Done
