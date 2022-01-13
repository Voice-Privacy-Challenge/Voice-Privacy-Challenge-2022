#!/bin/sh
# -------
# input feature directories
#  here, we use features in ../TESTDATA/vctk_vctk_anonymize for demonstration
# 
. path.sh
#. local/vc/am/init.sh

model_name=joint_tts_nsf_hifigan
proj_dir=${nii_pt_scripts}/projects/${model_name}
test_data_dir=$1

output_dir=${test_data_dir}/$3
inf_trunc_option=$4
batch_size=$5

export TEMP_TESTSET_NAME=`basename ${test_data_dir}`
export TEMP_TESTSET_LST=${test_data_dir}/scp/data.lst
export TEMP_TESTSET_PPG=${test_data_dir}/ppg
export TEMP_TESTSET_XVEC=${test_data_dir}/xvector
export TEMP_TESTSET_F0=${test_data_dir}/f0

# where is the directory of the trained model
export TEMP_MODEL_DIRECTORY=$PWD/exp/models/5_${model_name}

# where is the trained model?
#  here, we use network.jsn for demonstration.
#  of course, it will generate random noise only
export TEMP_NETWORK_PATH=${TEMP_MODEL_DIRECTORY}/trained_network_G.pt

# 
cd ${proj_dir}
python ${proj_dir}/main.py --inference --module-config config \
       --batch-size ${batch_size} \
       --num-workers ${batch_size} \
       --sampler block_shuffle_by_length \
       --cudnn-deterministic-toggle  \
       --cudnn-benchmark-toggle \
       --ignore-cached-file-infor \
       --output-dir ${output_dir} \
       --trunc-input-length-for-inference ${inf_trunc_option} \
       --trained-model ${TEMP_NETWORK_PATH} || exit 1
cd -

