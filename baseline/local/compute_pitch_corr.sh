#!/bin/bash
#Compute pitch/prosody correlation metric for data

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

#===== begin config =======

data=libri_test_trials_f 

#=========== end config ===========

. utils/parse_options.sh

echo "data=$data"


echo '  Done'
