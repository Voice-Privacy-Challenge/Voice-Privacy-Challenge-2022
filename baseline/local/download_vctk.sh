#!/bin/sh

set -e

home=$PWD
expo=./
check=$expo/data/vctk_dev/wav.scp

if [ ! -f $check ]; then
  mkdir -p $expo
  cd $expo
  if [ ! -f vctk_dev.tar.gz ]; then
    echo "  You will be prompted to enter password for getdata@voiceprivacychallenge.univ-avignon.fr"
    sftp getdata@voiceprivacychallenge.univ-avignon.fr <<EOF
cd /challengedata/corpora
get vctk_dev.tar.gz
bye
EOF
  fi
  echo '  Unpacking VCTK dev set...'
  tar -xf vctk_dev.tar.gz || exit 1
  cd $home
fi

echo '  Done'
