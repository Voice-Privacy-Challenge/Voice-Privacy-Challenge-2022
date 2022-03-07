#!/usr/bin/env python
"""
config.py

To merge different corpora (or just one corpus), 

*_set_name are lists
*_list are lists of lists
*_dirs are lists of lists

"""
import os

__author__ = "Xin Wang"
__email__ = "wangxin@nii.ac.jp"
__copyright__ = "Copyright 2020, Xin Wang"

#########################################################
## Configuration for training stage
#########################################################

# Name of datasets
#  1. after data preparation, trn/val_set_name are used to save statistics 
#  about the data sets
#  2. multiple datasets can be specified in the list. They will be loaded
#  and concatenated as the final training/validation set
trn_set_name = [os.getenv('TEMP_TRNSET_NAME')]
val_set_name = [os.getenv('TEMP_DEVSET_NAME')]

# File lists (text file, one data name per line, without name extension)
#  len(trn_list) should be equal to len(trn_set_name)
#  len(val_list) should be equal to len(val_set_name)
#
# trin_file_list: lists of file names for each training set
# File lists (text file, one data name per line, without name extension)
# trin_file_list: list of files for training set
trn_list = [os.getenv('TEMP_TRNSET_LIST')]
# val_file_list: for each validation set
val_list = [os.getenv('TEMP_DEVSET_LIST')]

# Directories for input features
# input_dirs = [[path_of_feature_1, path_of_feature_2, ..., ]]
#  1. we assume that train and validation data are put in the same sub-directory
#  2. len(input_dirs) should be equal to len(trn_set_name)
#  3. input_dirs[n] is for data set trn_set_name[n] and val_set_name[n]
input_dirs = [[os.getenv('TEMP_TRNDEV_MEL'),
               os.getenv('TEMP_TRNDEV_XVEC'),
               os.getenv('TEMP_TRNDEV_F0')]]

# Dimensions of input features
#  input_dims = [dimension_of_feature_1, dimension_of_feature_2, ...]
#  len(input_dims) should be equal to input_dirs[n]
#
#  Here, it means that ppg is 256 in dimension, xvector is 512 in dimension,
#  and F0 has one dimension
input_dims = [80, 256, 1]

# File name extension for input features
# input_exts = [name_extention_of_feature_1, ...]
# Please put ".f0" as the last feature
input_exts = ['.mel', '.xvector', '.f0']

# Temporal resolution for input features
# input_reso = [reso_feature_1, reso_feature_2, ...]
#  for waveform modeling, temporal resolution of input acoustic features
#  may be = waveform_sampling_rate * frame_shift_of_acoustic_features
#  for example, 160 = 16000 Hz * 10 ms 
input_reso = [160, 160, 160]

# Whether input features should be z-normalized
# input_norm = [normalize_feature_1, normalize_feature_2]
input_norm = [True, True, True]
    
# Similar configurations for output features
output_dirs = [[os.getenv('TEMP_TRNDEV_WAV')]]
output_dims = [1]
output_exts = ['.wav']
output_reso = [1]
output_norm = [False]

# Waveform sampling rate
#  wav_samp_rate can be None if no waveform data is used
wav_samp_rate = 16000

# Truncating input sequences so that the maximum length = truncate_seq
#  When truncate_seq is larger, more GPU mem required
# If you don't want truncating, please truncate_seq = None
truncate_seq = 16000 * 3

# Minimum sequence length
#  If sequence length < minimum_len, this sequence is not used for training
#  minimum_len can be None
minimum_len = 160 * 50
    
# Optional argument
#  Just a buffer for convenience
#  It can contain anything
optional_argument = ['']

# Data transformation function, you can import here
#  these functions are applied before casting np.array data into tensor arrays
#  
#input_trans_fns = [[func_for_mel, fun_for_f0]]
#output_trans_fns = [[func_for_wav]]


#########################################################
## Configuration for inference stage
#########################################################
# similar options to training stage

test_set_name = [os.getenv('TEMP_TESTSET_NAME')]

# List of test set data
# for convenience, you may directly load test_set list here
test_list = [os.getenv('TEMP_TESTSET_LST')]

# Directories for input features
# input_dirs = [path_of_feature_1, path_of_feature_2, ..., ]
#  we assume train and validation data are put in the same sub-directory
test_input_dirs = [[os.getenv('TEMP_TESTSET_MEL'), 
                    os.getenv('TEMP_TESTSET_XVEC'),
                    os.getenv('TEMP_TESTSET_F0')]]

input_exts = ['.mel', 'xvector', '.f0']

# Directories for output features, which must be [[]]. 
# Note that this is for debugging use, for example, in teach-forcing based
# mode of inference (in normal cases, not needed. )
#
# The folder to store the actually generated features from the model should 
# be specified by --output-dir 
test_output_dirs = [[]]


# Data transformation function, you can import here
#  these functions are applied before casting np.array data into tensor arrays
#
#test_input_trans_fns = [[func_for_mel, fun_for_f0]]
#test_output_trans_fns = [[func_for_wav]]
