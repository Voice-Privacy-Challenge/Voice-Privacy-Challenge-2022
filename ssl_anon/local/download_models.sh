#!/bin/sh

set -e

home=$PWD
expo=exp
check=$expo/models/asv_eval/xvect_01709_1/final.raw

if [ ! -f $check ]; then
  mkdir -p $expo
  cd $expo
  if [ ! -f models.tar.gz ]; then
    echo "  You will be prompted to enter password for getdata@voiceprivacychallenge.univ-avignon.fr"
    sftp getdata@voiceprivacychallenge.univ-avignon.fr <<EOF
cd challengedata/baseline
get models.tar.gz
bye
EOF
  fi
  echo '  Unpacking models...'
  tar -xf models.tar.gz || exit 1
  cd $home
fi

check=$expo/models/ssl_models
if [ ! -e $check ]; then
    cd $expo/models
    if [ -f ssl_models.tar.gz ];
    then
        rm ssl_models.tar.gz
    fi
    wget --quiet https://www.dropbox.com/sh/bua2vks8clnl2ha/AAAbMqgoGBUmxNF-6AeJhjtQa/ssl_models.tar.gz
    tar -xzvf ssl_models.tar.gz
    cd $home
fi


echo '  Done'
