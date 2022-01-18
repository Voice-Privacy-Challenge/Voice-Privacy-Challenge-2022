#!/bin/bash

set -e

. ./config.sh


collect () {
  for name in `find $results -type d -name "ASV-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
    #for label in 'EER:' 'minDCF(p-target=0.01):' 'minDCF(p-target=0.001):'; do
    for label in 'EER:'; do
      value=$(grep "$label" $name/EER)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/Cllr ] && echo "Directory $name/Cllr does not exist" && exit 1
    for label in 'Cllr (min/act):' 'ROCCH-EER:'; do
      value=$(grep "$label" $name/Cllr)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/linkability_log ] && echo "Directory $name/linkability_log does not exist" && exit 1
    for label in 'linkability:'; do
      value=$(grep "$label" $name/linkability_log)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/zebra ] && echo "Directory $name/zebra does not exist" && exit 1
    for label in 'Population:' 'Individual:'; do
      value=$(grep "$label" $name/zebra)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    done
    for name in `find $results -type f -name "ASR-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    while read line; do
      echo "  $line" | tee -a $expo
    done < $name
  done
}

expo=$results/results.txt
collect || exit 1
expo=$results.orig/results.txt
collect || exit 1

echo '  Done'
