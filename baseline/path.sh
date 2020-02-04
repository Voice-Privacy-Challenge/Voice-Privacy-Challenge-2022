export KALDI_ROOT=$(realpath ../kaldi)
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

. ../env.sh

# based on https://stackoverflow.com/a/5947802/12499892
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color
