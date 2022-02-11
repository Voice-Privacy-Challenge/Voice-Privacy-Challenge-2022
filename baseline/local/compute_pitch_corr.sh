#!/bin/bash
#Compute pitch/prosody correlation metric for data

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#===== begin config =======

data=libri_test_trials_f

#=========== end config ===========

. utils/parse_options.sh

list_name=data/$data/wav.scp 
list_name_anon=data/$data$anon_data_suffix/wav.scp

python local/pitch_correlation.py \
      --data=$data --list_name=$list_name --list_name_anon=$list_name_anon --results=$results/results.txt

echo "$list_name, $list_name_anon"

echo '  Done'
