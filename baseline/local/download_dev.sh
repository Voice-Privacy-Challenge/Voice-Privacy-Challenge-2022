#!/bin/sh

set -e

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-set> <subsets>"
  exit 1;
fi

data_set=$1
subsets="$2"

expo_dir=data/${data_set}_dev

dir=$expo_dir
if [ ! -f $dir/wav.scp ]; then
  [ -d $dir ] && rm -r $dir
  if [ ! -f ${data_set}_dev.tar.gz ]; then
    echo "  You will be prompted to enter password for getdata@voiceprivacychallenge.univ-avignon.fr"
    sftp getdata@voiceprivacychallenge.univ-avignon.fr <<EOF
cd /challengedata/corpora
get ${data_set}_dev.tar.gz
bye
EOF
  fi
  echo "  Unpacking ${data_set} dev set..."
  tar -xf ${data_set}_dev.tar.gz || exit 1
  [ ! -f $dir/text ] && echo "File $dir/text does not exist" && exit 1
  cut -d' ' -f1 $dir/text > $dir/text1
  cut -d' ' -f2- $dir/text | sed -r 's/,|!|\?|\./ /g' | sed -r 's/ +/ /g' | awk '{print toupper($0)}' > $dir/text2
  paste -d' ' $dir/text1 $dir/text2 > $dir/text
  rm $dir/text1 $dir/text2
  utils/fix_data_dir.sh $dir || exit 1
  utils/validate_data_dir.sh --no-feats $dir || exit 1
fi

echo "  Making ${data_set} trials subsets for ASR evaluation"
dirs=''
for subset in $subsets; do
  dir=${expo_dir}_asr${subset}
  if [ ! -f $dir/wav.scp ]; then
    echo "    $dir"
    trials=$expo_dir/trials$subset
    [ ! -f $trials ] && echo "File $trials does not exist" && exit 1
    [ -d $dir ] && rm -r $dir
    mkdir -p $dir
    cut -d' ' -f2 $trials | sort | uniq > $dir/utt-list
    utils/subset_data_dir.sh --utt-list $dir/utt-list $expo_dir $dir || exit 1
  fi
  dirs="$dirs $dir"
done

dir=${expo_dir}_asr
if [ ! -f $dir/wav.scp ]; then
  echo "  Combining ${data_set} trials subsets for ASR evaluation"
  [ -d $dir ] && rm -r $dir
  utils/combine_data.sh $dir $dirs || exit 1
  utils/validate_data_dir.sh --no-feats $dir || exit 1
fi

echo '  Done'
