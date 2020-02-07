#!/bin/sh

. path.sh
. local/vc/am/init.sh

export AM_NSF_FEAT_OUT="$1"

proj_dir=${nii_scripts}/acoustic-modeling/project-DAR-continuous


# preparing the training data
python ${proj_dir}/../SCRIPTS/01_prepare.py config_libri_am

# training the RNN model
python ${proj_dir}/../SCRIPTS/02_train.py config_libri_am

