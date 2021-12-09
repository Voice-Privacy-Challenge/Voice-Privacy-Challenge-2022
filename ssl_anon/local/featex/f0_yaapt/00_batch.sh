#!/bin/sh
# ---- batch script to extract F0
# Usage:
#   1. config INPUT_WAV_DIR and OUTPUT_F0_DIR
#   2. run sh 00_batch.sh
# No dependency required

# Directory of input waveform
INPUT_WAV_DIR=$PWD/../../../test_sample/
# Directory to store output F0
OUTPUT_F0_DIR=$PWD/../../../test_sample/

mkdir ${OUTPUT_F0_DIR}
ls ${INPUT_WAV_DIR} | grep wav > file.lst
cat file.lst | parallel python3 get_f0.py ${INPUT_WAV_DIR}/{/.}.wav ${OUTPUT_F0_DIR}/{/.}.f0
rm file.lst
