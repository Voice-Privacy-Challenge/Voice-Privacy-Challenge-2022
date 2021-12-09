#!/bin/bash

. path.sh
. cmd.sh

dev_spks=20
test_spks=20

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <srcdir> <split-destdir>"
  echo "Options"
  echo "   --dev-spks=40     # Number of speakers in dev dataset"
  echo "   --test-spks=40  # Number of speakers in test dataset"
  exit 1;
fi

in_dir=$1
out_dir=$2
mkdir -p ${out_dir}

python local/featex/split_am_nsf_data.py ${in_dir} ${out_dir} ${dev_spks} ${test_spks}

# sort each file
train_dir=$out_dir/$(basename $in_dir)_train
dev_dir=$out_dir/$(basename $in_dir)_dev
test_dir=$out_dir/$(basename $in_dir)_test

echo "Sorting : ${train_dir}, ${dev_dir} and ${test_dir}" 

for f in `ls ${train_dir}`; do
  echo "Sorting $f"
  sort -u ${train_dir}/$f > ${train_dir}/${f%.*}
  rm ${train_dir}/$f
done

for f in `ls ${dev_dir}`; do
  echo "Sorting $f"
  sort -u ${dev_dir}/$f > ${dev_dir}/${f%.*}
  rm ${dev_dir}/$f
done

for f in `ls ${test_dir}`; do
  echo "Sorting $f"
  sort -u ${test_dir}/$f > ${test_dir}/${f%.*}
  rm ${test_dir}/$f
done
