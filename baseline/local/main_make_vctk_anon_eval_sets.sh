#!/bin/bash

set -e

. ./path.sh
. ./config.sh

temp=$(mktemp)
for suff in $eval_subsets; do
  dset=data/vctk_$suff
  for name in ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_m_all$anon_data_suffix; do
    [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
  done

  cut -d' ' -f2 ${dset}_trials_f/trials | sort | uniq > $temp
  utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_f${anon_data_suffix} || exit 1
  cp ${dset}_trials_f/trials ${dset}_trials_f${anon_data_suffix} || exit 1

  cut -d' ' -f2 ${dset}_trials_f_common/trials | sort | uniq > $temp
  utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_f_common${anon_data_suffix} || exit 1
  cp ${dset}_trials_f_common/trials ${dset}_trials_f_common${anon_data_suffix} || exit 1

  cut -d' ' -f2 ${dset}_trials_m/trials | sort | uniq > $temp
  utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_m_all$anon_data_suffix ${dset}_trials_m${anon_data_suffix} || exit 1
  cp ${dset}_trials_m/trials ${dset}_trials_m${anon_data_suffix} || exit 1

  cut -d' ' -f2 ${dset}_trials_m_common/trials | sort | uniq > $temp
  utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_m_all$anon_data_suffix ${dset}_trials_m_common${anon_data_suffix} || exit 1
  cp ${dset}_trials_m_common/trials ${dset}_trials_m_common${anon_data_suffix} || exit 1
done
rm $temp

echo '  Done'
