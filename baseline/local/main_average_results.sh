#!/bin/bash
#Compute pitch/prosody correlation metric for data

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

. utils/parse_options.sh


python local/average_results.py --results=$results/results_summary.txt

echo "$results"

echo '  Done'
