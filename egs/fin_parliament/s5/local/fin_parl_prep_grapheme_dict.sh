#!/bin/bash

dir=data/local/dict
mkdir -p "$dir"

cat data/train_all/text | cut -f2- -d" " | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' | sort -u > "$dir/vocab"

python3 -c "[print(' '.join(line.strip())) for line in open('$dir/vocab', encoding='utf-8')]" > "$dir/tmp.$$"

echo "<UNK>	SPN" > "$dir/lexicon.txt"
paste "$dir/vocab" "$dir/tmp.$$" >> "$dir/lexicon.txt"

echo SIL > "$dir/silence_phones.txt"
echo SPN >> "$dir/silence_phones.txt"
echo SIL > "$dir/optional_silence.txt"

cat "$dir/tmp.$$" | tr -s ' ' '\n' | sort -u | grep -v ^$ > $dir/nonsilence_phones.txt
rm "$dir/tmp.$$"
