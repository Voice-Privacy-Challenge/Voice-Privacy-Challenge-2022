#!/bin/sh

. path.sh
. local/vc/nsf/init.sh

export AM_NSF_FEAT_OUT="$1"

proj_dir=${nii_scripts}/waveform-modeling/project-NSF

# preparing data
python ${proj_dir}/../SCRIPTS/00_prepare_data.py config_libri_nsf

# model training
python ${proj_dir}/../SCRIPTS/01_train_network.py config_libri_nsf
