#!/bin/bash

set -e

. ./config.sh


collect_orig () {
  for name in `find $res -type d -name "ASV-*_?" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
    for label in 'EER:'; do
      value=$(grep "$label" $name/EER)
      echo "  $value" | tee -a $expo
    done
  done
}

collect_anon () {
  for name in `find $res -type d -name "ASV-*anon*anon" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
    for label in 'EER:'; do
      value=$(grep "$label" $name/EER)
      echo "  $value" | tee -a $expo
    done
    done
    for name in `find $results -type f -name "ASR-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    while read line; do
      if grep -q "tglarge" <<< "$line"; then
        echo "  $line" | tee -a $expo
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

echo '  Done'
