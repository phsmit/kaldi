export KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
. $KALDI_ROOT/tools/env.sh

export LC_ALL=C
module load GCC/5.4.0-2.25 CUDA/8.0.61 anaconda3 anaconda2
source activate morfessor
