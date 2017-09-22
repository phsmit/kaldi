#!/bin/bash

# To be run from one directory above this script.

set -euo pipefail

. path.sh

if [ $# != 1 ]; then
  echo "Usage: fin_parl_data_prep.sh /path/to/fin_parl"
  exit 1;
fi

PARL_DIR=$1

if [ ! -d "$PARL_DIR" ]; then
  echo "Error: Directory required as argument"
  exit 1;
fi

# Fix a small mistake in the corpus
sed "s#/scratch/elec/puhec/eduskunta/filtered_data/##g" < "$PARL_DIR/parl-seen.eval.list" > "$PARL_DIR/../../parl-seen.eval.fixed.list"

declare -A real_sets=( [train_all]=parl-all.train
                       [dev_seen]=parl-seen.dev
                       [dev_unseen]=parl-unseen.dev
                       [eval_seen]=../../parl-seen.eval.fixed
                       [eval_unseen]=parl-unseen.eval )

declare -A sub_sets=( [train_30m]=parl-30min.train
                      [train_60m]=parl-60min.train
                      [train_clean]=parl-400.train )

for s in "${!real_sets[@]}"; do
  echo "Gathering dataset $s"
  list="$PARL_DIR/${real_sets[$s]}.list"
  if [ ! -f "$list" ]; then
     echo "Error: Expected file $list to exist"
     exit 1;
  fi

  mkdir -p "data/$s/tmp"

  awk -vT="$PARL_DIR/" '{print T $0 }' < "$list" > "data/$s/tmp/wav"
  sed "s#/#-#" < "$list" | sed "s/.wav//" > "data/$s/tmp/id"
  cut -c1-4 < "$list" > "data/$s/tmp/spk"
  #for line in $(cat "$list"); do
  while read line; do
    cat "$PARL_DIR/${line//.wav/.trn}"
  done < "$list" > "data/$s/tmp/text"


  paste -d" " "data/$s/tmp/id" "data/$s/tmp/wav" > "data/$s/wav.scp"
  paste -d" " "data/$s/tmp/id" "data/$s/tmp/spk" > "data/$s/utt2spk"
  paste -d" " "data/$s/tmp/id" "data/$s/tmp/text" > "data/$s/text"

  rm -r "data/$s/tmp"
  utils/fix_data_dir.sh "data/$s"
done

mkdir -p data/local/subsets
for s in "${!sub_sets[@]}"; do
  list="$PARL_DIR/${sub_sets[$s]}.list"
  if [ ! -f "$list" ]; then
     echo "Error: Expected file $list to exist"
     exit 1;
  fi
  sed "s#/#-#" < "$list" | sed "s/.wav//" > "data/local/subsets/$s" 
done

#utils/combine_data.sh data/dev data/dev_seen data/dev_unseen
#utils/combine_data.sh data/eval data/eval_seen data/eval_unseen
