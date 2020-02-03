#!/bin/sh

set -e

vctk_dir=data/vctk_dev
subsets='_f_mic2 _f_common_mic2 _m_mic2 _m_common_mic2'

dir=$vctk_dir
if [ ! -f $dir/wav.scp ]; then
  [ -d $dir ] && rm -r $dir
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
  utils/fix_data_dir.sh $dir || exit 1
  utils/validate_data_dir.sh --no-feats $dir || exit 1
fi

echo '  Making VCTK trials subsets for ASR evaluation'
dirs=''
for subset in $subsets; do
  dir=${vctk_dir}_asr${subset}
  if [ ! -f $dir/wav.scp ]; then
    echo "    $dir"
    trials=$vctk_dir/trials$subset
    [ ! -f $trials ] && echo "File $trials does not exist" && exit 1
    [ -d $dir ] && rm -r $dir
    mkdir -p $dir
    cut -d' ' -f2 $trials | sort | uniq > $dir/utt-list
    utils/subset_data_dir.sh --utt-list $dir/utt-list $vctk_dir $dir || exit 1
  fi
  dirs="$dirs $dir"
done

dir=${vctk_dir}_asr
if [ ! -f $dir/wav.scp ]; then
  echo '  Combining VCTK trials subsets for ASR evaluation'
  [ -d $dir ] && rm -r $dir
  utils/combine_data.sh $dir $dirs || exit 1
  utils/validate_data_dir.sh --no-feats $dir || exit 1
fi

echo '  Done'
