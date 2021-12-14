#!/bin/bash

set -e

. ./path.sh
. ./cmd.sh
. ./config.sh

nj=$(nproc)
dset=vctk_dev_trials_f_all
model=exp/models/asr_eval


. utils/parse_options.sh

ivec_extr=$model/extractor
graph_dir=$model/graph_tgsmall
large_lang=$model/lang_test_tglarge
small_lang=$model/lang_test_tgsmall
data=data/${dset}_hires
ivect=$ivec_extr/ivect_$dset

spk2utt=data/$dset/spk2utt
[ ! -f $spk2utt ] && echo "File $spk2utt does not exist" && exit 1
num_spk=$(wc -l < $spk2utt)
[ $nj -gt $num_spk ] && nj=$num_spk

if [ ! -f $data/.done_mfcc ]; then
  printf "${RED}  compute MFCC: $dset${NC}\n"
  utils/copy_data_dir.sh data/$dset $data || exit 1
  steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" --mfcc-config conf/mfcc_hires.conf $data || exit 1
  steps/compute_cmvn_stats.sh $data || exit 1
  utils/fix_data_dir.sh $data || exit 1
  touch $data/.done_mfcc
fi

if [ ! -f $ivect/.done ]; then
  printf "${RED}  compute i-vect: $dset${NC}\n"
  steps/online/nnet2/extract_ivectors_online.sh --nj $nj --cmd "$train_cmd" \
    $data ${ivec_extr} $ivect || exit 1
  touch $ivect/.done
fi

expo=$model/decode_${dset}_tgsmall
if [ ! -f $expo/.done ]; then
  printf "${RED}  decoding: $dset${NC}\n"
  steps/nnet3/decode.sh \
    --nj $nj --cmd "$decode_cmd" \
    --acwt 1.0 --post-decode-acwt 10.0 \
    --online-ivector-dir $ivect \
    $graph_dir $data $expo || exit 1
  mkdir -p $results
  grep WER $expo/wer* | utils/best_wer.sh | tee -a $results/ASR-$dset
  touch $expo/.done
fi

expo=$model/decode_${dset}_tglarge
if [ ! -f $expo/.done ]; then
  printf "${RED}  rescoring: $dset${NC}\n"
  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" $small_lang $large_lang \
    $data $model/decode_${dset}_tgsmall $expo || exit 1
  mkdir -p $results
  grep WER $expo/wer* | utils/best_wer.sh | tee -a $results/ASR-$dset
  touch $expo/.done
fi
