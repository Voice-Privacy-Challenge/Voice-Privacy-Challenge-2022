#!/bin/bash

. path.sh

proto_dir="$1"
librispeech_corpus="$2"
enroll_data="$3"
trial_data="$4"

local/data_prep_adv.sh ${librispeech_corpus}/dev-clean data/${enroll_data}
local/data_prep_adv.sh ${librispeech_corpus}/dev-clean data/${trial_data}

rm data/${enroll_data}/spk2utt
rm data/${trial_data}/spk2utt

python local/fix_eval2.py ${proto_dir} data/${enroll_data} data/${trial_data} || exit 1;

utils/utt2spk_to_spk2utt.pl < data/${enroll_data}/utt2spk > data/${enroll_data}/spk2utt || exit 1
utils/utt2spk_to_spk2utt.pl < data/${trial_data}/utt2spk > data/${trial_data}/spk2utt || exit 1

utils/fix_data_dir.sh data/${enroll_data}
utils/fix_data_dir.sh data/${trial_data}

utils/validate_data_dir.sh --no-text --no-feats data/${enroll_data}
utils/validate_data_dir.sh --no-text --no-feats data/${trial_data}
