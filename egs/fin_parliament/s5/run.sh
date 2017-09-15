#!/bin/bash

. cmd.sh

set -euo pipefail

local/fin_parl_data_prep.sh $1
local/fin_parl_prep_grapheme_dict.sh

utils/prepare_lang.sh data/local/dict "<UNK>"  data/local/lang data/lang

mfccdir=mfcc
for x in train_30m train_60m train_clean train_all dev eval; do
  steps/make_mfcc.sh --nj 50 --cmd "$train_cmd" \
    data/$x exp/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
  utils/fix_data_dir.sh data/$x
done

utils/subset_data_dir.sh --shortest data/train_30m 10000 data/train_10kshort

steps/train_mono.sh --nj 30 --cmd "$train_cmd" \
  data/train_10kshort data/lang exp/mono

steps/align_si.sh --nj 30 --cmd "$train_cmd" \
  data/train_30m data/lang_nosp exp/mono exp/mono_ali

steps/train_deltas.sh --cmd "$train_cmd" \
  2500 30000 data/train_30m data/lang exp/mono_ali exp/tri1

steps/align_si.sh --nj 30 --cmd "$train_cmd" \
  data/train_60m data/lang exp/tri1 exp/tri1_ali

steps/train_lda_mllt.sh --cmd "$train_cmd" \
  4000 40000 data/train_60m data/lang exp/tri1_ali exp/tri2

steps/align_si.sh --nj 30 --cmd "$train_cmd" \
  data/train_clean data/lang exp/tri2 exp/tri2_ali

steps/train_sat.sh --cmd "$train_cmd" \
  5000 80000 data/train_clean data/lang exp/tri2_ali exp/tri3

steps/cleanup/clean_and_segment_data.sh --nj 150 --cmd "$train_cmd" \
  data/train_all data/lang exp/tri3 exp/tri3_cleaned_work data/train_cleaned

steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  data/train_cleaned data/lang exp/tri3 exp/tri3_ali_cleaned

steps/train_sat.sh --cmd "$train_cmd" \
  8000 120000 data/train_cleaned data/lang exp/tri3_ali_cleaned exp/tri3_cleaned
