#!/bin/bash

set -e

. ./config.sh


collect_orig () {
  for dset in dev test; do
    for name in `find $res -type d -name "ASV-*$dset*_?" | sort` `find $res -type d -name "ASV-*$dset*_common" | sort`; do
      # echo "$(basename $name)" | tee -a $expo
      [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
      for label in 'EER:'; do
        value=$(grep "$label" $name/EER)
        echo "$(basename $name)  $value" | tee -a $expo
      done
    done
  done
}

collect_anon () {
  for dset in dev test; do
    for name in `find $res -type d -name "ASV-*anon*$dset*anon" | sort`; do
      # echo "$(basename $name)" | tee -a $expo
      [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
      for label in 'EER:'; do
        value=$(grep "$label" $name/EER)
        echo "$(basename $name)  $value" | tee -a $expo
      done
    done
  done
}

collect_asr () {
  for name in `find $results.orig -type f -name "ASR-*asr" | sort`; do
    # echo "$(basename $name)" | tee -a $expo
    while read line; do
      if grep -q "tglarge" <<< "$line"; then
        echo "$(basename $name)  $line" | tee -a $expo
      fi
    done < $name
  done
  for name in `find $results -type f -name "ASR-*anon" | sort`; do
    # echo "$(basename $name)" | tee -a $expo
    while read line; do
      if grep -q "tglarge" <<< "$line"; then
        echo "$(basename $name)  $line" | tee -a $expo
      fi
    done < $name
  done
}


res=$results
expo=$results/results_summary.txt
res=$results.orig
collect_orig || exit 1
res=$results
collect_anon || exit 1
collect_asr || exit 1


echo '  Done'
