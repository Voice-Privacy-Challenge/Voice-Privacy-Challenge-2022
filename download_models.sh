#!/bin/sh

set -e

home=$PWD

mark=.done-models
if [ ! -f $mark ]; then
  expo=baseline/exp
  mkdir -p $expo
  cd $expo
  if [ ! -f models.tar.gz ]; then
    echo "You will be prompted to enter password for getdata@voiceprivacychallenge.univ-avignon.fr"
    sftp getdata@voiceprivacychallenge.univ-avignon.fr <<EOF
cd challengedata/baseline
get models.tar.gz
bye
EOF
  fi
  echo 'Unpacking models'
  tar -xf models.tar.gz || exit 1
  cd $home
  touch $mark
fi

echo Done
