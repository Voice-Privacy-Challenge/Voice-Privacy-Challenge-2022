#!/bin/sh
# Copied from init.sh

. path.sh
. local/vc/nsf/init.sh

# ----- Method 1 
# For generation, you can configure config.py and run
#python ../SCRIPTS/02_genwaveform.py config

# ----- Method 2
# Equivalently, you can set the environment variables below
#  rather than manually changing config.py

# Directories of the input features, which are separated by ','
#test_mel=/home/bsrivast/asr_data/LibriTTS/am_nsf_data/libritts/test/mel

test_data_dir=$1

proj_dir=${nii_scripts}/waveform-modeling/project-NSF

test_mel=${test_data_dir}/am_out_mel
test_xvector=${test_data_dir}/xvector
test_f0=${test_data_dir}/f0
export TEMP_WAVEFORM_MODEL_INPUT_DIRS=${test_mel},${test_xvector},${test_f0}

# Path to the model directory
export TEMP_WAVEFORM_MODEL_DIRECTORY=${proj_dir}/MODELS/h-sinc-NSF

# Path to the directory that will save the generated waveforms
export TEMP_WAVEFORM_OUTPUT_DIRECTORY="${test_data_dir}/nsf_output_wav"

# Path to the trained_network.jsn (or epoch*.autosave)
export TEMP_WAVEFORM_MODEL_NETWORK_PATH=exp/models/4_nsf/trained_network.jsn

# Path to a temporary directory to save intermediate files (which will be deleted after generation)
export TEMP_WAVEFORM_TEMP_OUTPUT_DIRECTORY="${test_data_dir}/output_tmp"

# generating
python ${proj_dir}/../SCRIPTS/02_genwaveform.py config_libri_nsf

rm -r ${TEMP_WAVEFORM_TEMP_OUTPUT_DIRECTORY}


