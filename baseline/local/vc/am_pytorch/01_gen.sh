#!/bin/sh
# -------
# input feature directories
#  here, we use features in ../TESTDATA/vctk_vctk_anonymize for demonstration
# 
. path.sh
#. local/vc/am/init.sh

proj_dir=${nii_pt_scripts}/projects/am
test_data_dir=$1

output_dir=${test_data_dir}/$2
batch_size=$3
xvect_type=$4

# export varianbles used by config
export TEMP_TESTSET_NAME=`basename ${test_data_dir}`
export TEMP_TESTSET_LST=${test_data_dir}/scp/data.lst
export TEMP_TESTSET_PPG=${test_data_dir}/ppg
export TEMP_TESTSET_F0=${test_data_dir}/f0

if [ $xvect_type = "sidekit" ];
then
    # if xvector is based on sidekit, we need to change config
    config_file=config_sidekit
    # xvectors
    export TEMP_TESTSET_XVEC=${test_data_dir}/xvector
    # where is the directory of the trained model
    export TEMP_ACOUSTIC_MODEL_DIRECTORY=$PWD/exp/models/3_ss_am_pt_sidekit
else
    # default use KALDI xvectors
    config_file=config
    export TEMP_TESTSET_XVEC=${test_data_dir}/xvector
    export TEMP_ACOUSTIC_MODEL_DIRECTORY=$PWD/exp/models/3_ss_am_pt
fi

# Path to the pre-trained model
export TEMP_ACOUSTIC_NETWORK_PATH=${TEMP_ACOUSTIC_MODEL_DIRECTORY}/trained_network.pt

# 
cd ${proj_dir}
python ${proj_dir}/main.py --inference --module-config ${config_file} \
       --cudnn-deterministic-toggle  \
       --batch-size ${batch_size} \
       --num-workers ${batch_size} \
       --sampler block_shuffle_by_length \
       --cudnn-benchmark-toggle \
       --ignore-cached-file-infor \
       --output-dir ${output_dir} \
       --trained-model ${TEMP_ACOUSTIC_NETWORK_PATH} || exit 1
cd -

