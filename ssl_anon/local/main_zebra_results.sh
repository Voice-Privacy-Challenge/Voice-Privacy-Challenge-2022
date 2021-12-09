#!/bin/bash
# ZEBRA plots for all experiments
# TODO: correct zebra dir 
set -e

. ./config.sh

mkdir -p voiceprivacy-challenge-2020
PYTHONPATH=$(realpath ../zebra) python ../zebra/voiceprivacy_challenge_plots.py || exit 1

echo '  Done'
