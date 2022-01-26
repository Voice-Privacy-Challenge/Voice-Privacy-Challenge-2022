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
trn_list = [os.getenv('TEMP_TRNSET_LIST')]
# val_file_list: for each validation set
val_list = [os.getenv('TEMP_DEVSET_LIST')]

# Directories for input features
# input_dirs = [[path_of_feature_1, path_of_feature_2, ..., ]]
#  1. we assume that train and validation data are put in the same sub-directory
#  2. len(input_dirs) should be equal to len(trn_set_name)
#  3. input_dirs[n] is for data set trn_set_name[n] and val_set_name[n]
input_dirs = [[os.getenv('TEMP_TRNDEV_PPG'),
               os.getenv('TEMP_TRNDEV_XVEC'),
               os.getenv('TEMP_TRNDEV_F0')]]

# Dimensions of input features
#  input_dims = [dimension_of_feature_1, dimension_of_feature_2, ...]
#  len(input_dims) should be equal to input_dirs[n]
#
#  Here, it means that ppg is 256 in dimension, xvector is 512 in dimension,
#  and F0 has one dimension
input_dims = [256, 512, 1]

# File name extension for input features
#  input_exts = [name_extention_of_feature_1, ...]
#  len(input_dims) should be equal to len(input_exts)
#  This tells the script that FILENAME.ppg is the feature file for ppg ...
input_exts = ['.ppg', '.xvector', '.f0']

# Temporal resolution for input features
#  len(input_reso) should be equal to len(input_dims)
#  Because input and output in this project have the same length, 
#  the input resolution can be simply 1
input_reso = [1, 1, 1]

# Whether input features should be z-normalized
#  input_norm = [normalize_feature_1, normalize_feature_2]
#  len(input_norm) should be equal to len(input_dims)
input_norm = [True, True, True]
    


# Similar configurations for output features
output_dirs = [[os.getenv('TEMP_TRNDEV_MEL')]]
output_dims = [80]
output_exts = ['.mel']
output_reso = [1]
output_norm = [True]

# Waveform sampling rate
#  wav_samp_rate can be None if no waveform data is used
wav_samp_rate = None

# Truncating input sequences so that the maximum length = truncate_seq
#  When truncate_seq is larger, more GPU mem required
# If you don't want truncating, please truncate_seq = None
truncate_seq = None

# Minimum sequence length
#  If sequence length < minimum_len, this sequence is not used for training
#  minimum_len can be None
minimum_len = None
    
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
test_input_dirs = [[os.getenv('TEMP_TESTSET_PPG'), 
                    os.getenv('TEMP_TESTSET_XVEC'),
                    os.getenv('TEMP_TESTSET_F0')]]

# Directories from which the script load output features, which must be [[]]
# for this model. (but it is used, for example, in auto-encoders)
#
# The directory to store the generated features should 
# be specified by python main.py --inference --output-dir
test_output_dirs = [[]]

# Data transformation function, you can import here
#  these functions are applied before casting np.array data into tensor arrays
#
#test_input_trans_fns = [[func_for_mel, fun_for_f0]]
#test_output_trans_fns = [[func_for_wav]]
