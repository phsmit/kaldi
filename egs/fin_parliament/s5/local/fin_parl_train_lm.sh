#!/bin/bash

set -euo pipefail
stage=0
morfessor_weight=0.1

echo "$0 $@"  # Print the command line for logging
. utils/parse_options.sh || exit 1;

dir=data/local/local_lm
lm_dir=${dir}/data

mkdir -p $dir
. ./path.sh || exit 1; # for KALDI_ROOT


type morfessor-train >/dev/null 2>&1 || echo "$0: Please install morfessor, see http://morfessor.readthedocs.io" 
type varigram_kn >/dev/null 2>&1 || echo << EOM
  $0: Please install VariKN with: \n 
    cd ../../../tools; extras/install_varikn.sh; cd -
EOM

num_dev_sentences=10000

if [ $stage -le 0 ]; then
  mkdir -p $dir/data
  mkdir -p $dir/data/text

  echo "$0: Getting training text"
  tmp=$(mktemp)
  < data/train_all/text cut -f2- -d" " > $tmp
  local/split_text_train_dev.py $tmp 10000 $dir/data/text/train.txt.gz $dir/data/text/dev.txt.gz
  rm $tmp
fi

morf_model=$dir/data/morfessor_a${morfessor_weight}
if [ $stage -le 1 ]; then
  echo "$0: Train subword segmentation with morfessor"
  morfessor-train -S $morf_model -d none -w $morfessor_weight $dir/data/text/train.txt.gz $dir/data/text/dev.txt.gz
fi

vdir=$dir/data/varikn_a${morfessor_weight}
if [ $stage -le 2 ]; then
  echo "$0: Prepare varikn files"
  mkdir -p $vdir
  for s in train dev; do
          export PYTHONIOENCODING=UTF-8

    morfessor-segment -L $morf_model --encoding=utf-8 --output-newlines --output-format "{analysis} " --output-format-separator="+ +" $dir/data/text/${s}.txt.gz | sed "s/^/<s> /" | sed "s/$/<\/s>/" > $vdir/$s
  done
fi


if [ $stage -le 3 ]; then
  echo "$0: Train VariKN model"
  varigram_kn -o $vdir/dev -n 10 -C -O "0 0 1" -3 -a -D 0.005 -E 0.01 $vdir/train $vdir/arpa
fi
