#!/bin/sh
# -------
# input feature directories
#  here, we use features in ../TESTDATA/vctk_vctk_anonymize for demonstration
# 
. path.sh
#. local/vc/am/init.sh

proj_dir=${nii_pt_scripts}/projects/nsf
test_data_dir=$1

output_dir=${test_data_dir}/$3
inf_trunc_option=$4

export TEMP_TESTSET_NAME=`basename ${test_data_dir}`
export TEMP_TESTSET_LST=${test_data_dir}/scp/data.lst
export TEMP_TESTSET_MEL=${test_data_dir}/$2
export TEMP_TESTSET_XVEC=${test_data_dir}/xvector
export TEMP_TESTSET_F0=${test_data_dir}/f0

# where is the directory of the trained model
export TEMP_NSF_MODEL_DIRECTORY=$PWD/exp/models/4_nsf_pt

# where is the trained model?
#  here, we use network.jsn for demonstration.
#  of course, it will generate random noise only
export TEMP_NSF_NETWORK_PATH=${TEMP_NSF_MODEL_DIRECTORY}/trained_network.pt

# 
cd ${proj_dir}
python ${proj_dir}/main.py --inference --module-config config \
       --ignore-cached-file-infor \
       --cudnn-deterministic-toggle  \
       --cudnn-benchmark-toggle \
       --output-dir ${output_dir} \
       --trunc-input-length-for-inference ${inf_trunc_option} \
       --trained-model ${TEMP_NSF_NETWORK_PATH} || exit 1
cd -

