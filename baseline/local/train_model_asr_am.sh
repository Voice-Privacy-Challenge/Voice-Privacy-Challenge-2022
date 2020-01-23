#!/bin/bash
#NT 
# Training ASR AM to extract BN features (see the trained model in /baseline/exp/models/1_asr_am/) on LibriSpeech-train-clean-100 + LibriSpeech-train-other-500
set -e



stage=1

. ./cmd.sh
. ./path.sh

nj=40

# Set this to somewhere where you want to put your data, or where
# someone else has already put it.  You'll want to change this
# if you're not on the CLSP grid.
data=$PWD/LibriSpeech

mkdir -p $data

# base url for downloads.
data_url=www.openslr.org/resources/12
lm_url=www.openslr.org/resources/11
mfccdir=mfcc   #TO CORRECT

stage=19 #TO CORRECT

nj=40

. parse_options.sh


#ln -s ../../../../kaldi/egs/librispeech/s5/local local_librispeech

if [ $stage -le 1 ]; then
  # download the data.  Note: we're using the 100 hour setup for
  # now; later in the script we'll download more and use it to train neural
  # nets.
  for part in dev-clean test-clean train-clean-100 train-other-500; do
    local_librispeech/download_and_untar.sh $data $data_url $part
  done


  # download the LM resources
  local_librispeech/download_lm.sh $lm_url data/local_librispeech/lm
fi

if [ $stage -le 2 ]; then
  # format the data as Kaldi data directories
  for part in dev-clean test-clean train-clean-100 train-other-500; do
    # use underscore-separated names in data directories.
    local_librispeech/data_prep.sh $data/LibriSpeech/$part data/$(echo $part | sed s/-/_/g)
  done
fi

## Optional text corpus normalization and LM training
## These scripts are here primarily as a documentation of the process that has been
## used to build the LM. Most users of this recipe will NOT need/want to run
## this step. The pre-built language models and the pronunciation lexicon, as
## well as some intermediate data(e.g. the normalized text used for LM training),
## are available for download at http://www.openslr.org/11/
#local_librispeech/lm/train_lm.sh $LM_CORPUS_ROOT \
#  data/local_librispeech/lm/norm/tmp data/local_librispeech/lm/norm/norm_texts data/local_librispeech/lm

## Optional G2P training scripts.
## As the LM training scripts above, this script is intended primarily to
## document our G2P model creation process
#local_librispeech/g2p/train_g2p.sh data/local_librispeech/dict/cmudict data/local_librispeech/lm

if [ $stage -le 3 ]; then
  # when the "--stage 3" option is used below we skip the G2P steps, and use the
  # lexicon we have already downloaded from openslr.org/11/
  local_librispeech/prepare_dict.sh --stage 3 --nj $nj --cmd "$train_cmd" \
   data/local_librispeech/lm data/local_librispeech/lm data/local_librispeech/dict_nosp

  utils/prepare_lang.sh data/local_librispeech/dict_nosp \
   "<UNK>" data/local_librispeech/lang_tmp_nosp data/lang_nosp

  local_librispeech/format_lms.sh --src-dir data/lang_nosp data/local_librispeech/lm
fi

if [ $stage -le 4 ]; then
  # Create ConstArpaLm format language model for full 3-gram and 4-gram LMs
  utils/build_const_arpa_lm.sh data/local_librispeech/lm/lm_tglarge.arpa.gz \
    data/lang_nosp data/lang_nosp_test_tglarge
  #utils/build_const_arpa_lm.sh data/local_librispeech/lm/lm_fglarge.arpa.gz \
  #  data/lang_nosp data/lang_nosp_test_fglarge
fi

#combine train_100 and train_500
if [ $stage -le 5 ]; then
  utils/data/combine_data.sh data/train_600 data/train_clean_100 data/train_other_500 || exit 1
fi


if [ $stage -le 6 ]; then
  for part in dev_clean test_clean train_600; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/$part exp/make_mfcc/$part $mfccdir
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done
fi

if [ $stage -le 7 ]; then
  utils/subset_data_dir.sh --shortest data/train_600 5000 data/train_5k
fi

if [ $stage -le 8 ]; then
  steps/train_mono.sh \
    --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_5k data/lang_nosp exp/mono
  (
    utils/mkgraph.sh \
	  data/lang_nosp_test_tgsmall \
      exp/mono exp/mono/graph_nosp_tgsmall
    for test in test_clean dev_clean; do
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
    data/train_600 data/lang_nosp exp/mono exp/mono_ali
  steps/train_deltas.sh \
    --boost-silence 1.25 --cmd "$train_cmd" \
    2000 20000 data/train_600 data/lang_nosp \
	exp/mono_ali exp/tri1
  (
    utils/mkgraph.sh \
	  data/lang_nosp_test_tgsmall \
      exp/tri1 exp/tri1/graph_nosp_tgsmall
    for test in test_clean dev_clean; do
      steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp_tgsmall \
                      data/$test exp/tri1/decode_nosp_tgsmall_$test
#      steps/lmrescore.sh --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tgmed} \
#                         data/$test exp/tri1/decode_nosp_{tgsmall,tgmed}_$test
#      steps/lmrescore_const_arpa.sh \
#        --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tglarge} \
#        data/$test exp/tri1/decode_nosp_{tgsmall,tglarge}_$test
    done
  )&
fi

if [ $stage -le 10 ]; then
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
                    data/train_600 data/lang_nosp exp/tri1 exp/tri1_ali
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
                          --splice-opts "--left-context=3 --right-context=3" 2500 25000 \
                          data/train_600 data/lang_nosp exp/tri1_ali exp/tri2b
  (
    utils/mkgraph.sh data/lang_nosp_test_tgsmall \
                     exp/tri2b exp/tri2b/graph_nosp_tgsmall
    for test in test_clean dev_clean; do
      steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri2b/graph_nosp_tgsmall \
                      data/$test exp/tri2b/decode_nosp_tgsmall_$test
#      steps/lmrescore.sh --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tgmed} \
#                         data/$test exp/tri2b/decode_nosp_{tgsmall,tgmed}_$test
#      steps/lmrescore_const_arpa.sh \
#        --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tglarge} \
#        data/$test exp/tri2b/decode_nosp_{tgsmall,tglarge}_$test
    done
  )&
fi

if [ $stage -le 11 ]; then
  steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true \
                     data/train_600 data/lang_nosp exp/tri2b exp/tri2b_ali
  steps/train_sat.sh --cmd "$train_cmd" 3000 45000 \
                     data/train_600 data/lang_nosp exp/tri2b_ali exp/tri3b
  (
    utils/mkgraph.sh data/lang_nosp_test_tgsmall \
                     exp/tri3b exp/tri3b/graph_nosp_tgsmall
    for test in test_clean dev_clean; do
      steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
                            exp/tri3b/graph_nosp_tgsmall data/$test \
                            exp/tri3b/decode_nosp_tgsmall_$test
#      steps/lmrescore.sh --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tgmed} \
#                         data/$test exp/tri3b/decode_nosp_{tgsmall,tgmed}_$test
#      steps/lmrescore_const_arpa.sh \
#        --cmd "$decode_cmd" data/lang_nosp_test_{tgsmall,tglarge} \
#        data/$test exp/tri3b/decode_nosp_{tgsmall,tglarge}_$test
    done
  )&
fi

if [ $stage -le 19 ]; then
  # this does some data-cleaning. The cleaned data should be useful when we add
  # the neural net and chain systems.  (although actually it was pretty clean already.)
  local_librispeech/run_cleanup_segmentation.sh
fi

if [ $stage -le 20 ]; then
  # train and test nnet3 tdnn models on the entire data with data-cleaning.
  # set "--stage 11" if you have already run local_librispeech/nnet3/run_tdnn.sh
  local_librispeech/chain/run_tdnn.sh \
    --stage 3 \
	--train_stage -10
fi

# The nnet3 TDNN recipe:
# local_librispeech/nnet3/run_tdnn.sh # set "--stage 11" if you have already run local_librispeech/chain/run_tdnn.sh

# # train models on cleaned-up data
# # we've found that this isn't helpful-- see the comments in local_librispeech/run_data_cleaning.sh
# local_librispeech/run_data_cleaning.sh

# Wait for decodings in the background
wait
echo Done
