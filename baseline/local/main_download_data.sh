#!/bin/bash
# Download development and evaluation datasets

set -e

. ./config.sh

for dset in $eval_sets ; do
  for suff in $eval_subsets; do
    printf "${GREEN}\n Downloading ${dset}_${suff} set...${NC}\n"
    local/download_data.sh ${dset}_${suff} || exit 1
  done
done

printf "${GREEN}\n Downloading train-clean-360-spk...${NC}\n"
home=$PWD
expo=data/train-clean-360-spk
check=$expo/utt2spk
if [ ! -f $check ]; then
  mkdir -p $expo
  cd $expo
  if [ ! -f train-clean-360-spk.tar.gz ]; then
    echo "  You will be prompted to enter password for getdata@voiceprivacychallenge.univ-avignon.fr"
    sftp getdata@voiceprivacychallenge.univ-avignon.fr <<EOF
cd challengedata/corpora
get train-clean-360-spk.tar.gz
bye
EOF
  fi
  echo '  Unpacking data...'
  tar -xf train-clean-360-spk.tar.gz || exit 1
  cd $home
fi

if [[ $f0_download == 'true' ]] && [[ $baseline_type = 'baseline-1' ]]; then
    printf "${GREEN}\n Downloading F0 for train-clean-360-asv...${NC}\n"
    home=$PWD
    expo=exp/am_nsf_data
    check=$expo/train-clean-360-asv.tar.gz
    if [ ! -f $check ]; then
      mkdir -p $expo
      cd $expo
      if [ ! -f train-clean-360-asv.tar.gz ]; then
        echo "  You will be prompted to enter password for getdata@voiceprivacychallenge.univ-avignon.fr"
        sftp getdata@voiceprivacychallenge.univ-avignon.fr <<EOF
cd challengedata/corpora
get train-clean-360-asv.tar.gz
bye
EOF
      fi
      echo '  Unpacking data...'
      tar -xf train-clean-360-asv.tar.gz || exit 1
      cd $home
    fi
fi

echo '  Done'
