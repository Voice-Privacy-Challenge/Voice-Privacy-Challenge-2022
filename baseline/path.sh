export KALDI_ROOT=`pwd`/../kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

. ../env.sh

# TO CORRECT
bin=~/work/Challenge/Baseline-N/bin/flac
export PATH=$bin:$PATH

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color


