#!/usr/bin/env python3

import gzip
import random
import argparse

parser = argparse.ArgumentParser(description="""Read plain text from file and (semi-)random split into gzipped train and dev set. Size of dev set given
                in number of lines. Needs real file as input as input is read twice.""") 
parser.add_argument("input", type=argparse.FileType('r', encoding="utf-8"), help="Input file. Must be seekable as input is read twice.")
parser.add_argument("num_dev_lines", type=int, help="Number of lines in dev file (rest in train file)")
parser.add_argument("output_train", type=argparse.FileType('wb'), help="Ouput train file (gzipped)")
parser.add_argument("output_dev", type=argparse.FileType('wb'), help="Ouput dev file (gzipped)")

parser.add_argument("--seed", type=int, help="Random seed", default=0)

args = parser.parse_args()

num_lines = sum(1 for _ in args.input)
if num_lines == 0:
    exit("Error split_text_train_dev.py: Input file is empty")

args.input.seek(0)

# Increase the probability to select a line with 2%. This creates a small bias for earlier lines in the file, but makes
# sure that more often the actual number of dev lines is correct.
p = args.num_dev_lines / num_lines * 1.02

random.seed(args.seed)

# Number of lines actually written to d
d=0
with gzip.open(args.output_dev, 'wt', encoding='utf-8') as dev, gzip.open(args.output_train, 'wt', encoding='utf-8') as train:
    for line in args.input:
        line = line.strip()
        if random.random() < p and d < args.num_dev_lines:
            print(line, file=dev)
            d += 1
        else:
            print(line, file=train)
