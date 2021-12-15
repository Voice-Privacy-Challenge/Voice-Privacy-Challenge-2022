#!/bin/bash

. ./config.sh

python3 ../sidekit/egs/libri360_train/dataprep.py --save-path data --augment-conf-file conf/augment.txt --download-augment

echo '  Done'
