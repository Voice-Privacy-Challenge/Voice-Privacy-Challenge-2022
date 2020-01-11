#!/usr/bin/python
###########################################################################
##  Scripts for Acoustic model                                            #
##                                                                        #
## ---------------------------------------------------------------------  #
##                                                                        #
##  Copyright (c) 2018  National Institute of Informatics                 #
##                                                                        #
##  THE NATIONAL INSTITUTE OF INFORMATICS AND THE CONTRIBUTORS TO THIS    #
##  WORK DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING  #
##  ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT    #
##  SHALL THE NATIONAL INSTITUTE OF INFORMATICS NOR THE CONTRIBUTORS      #
##  BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY   #
##  DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,       #
##  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS        #
##  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE   #
##  OF THIS SOFTWARE.                                                     #
###########################################################################
##                         Author: Xin Wang                               #
##                         Date:   31 Oct. 2018                           #
##                         Contact: wangxin at nii.ac.jp                  #
###########################################################################

import os
import sys
prjdir = '/home/bsrivast/vc_tools/eurecom_nii_paper/project-CURRENNT-scripts/acoustic-modeling/project-DAR-continuous'

# -------------------------------------------------
# --------------- Configuration start --------------

# ------------- Swith -------------
# step01: preparing data for CURRENNT
step01 = True
#  fine controls on each step (by default, conduct all steps)
#  step01.1 creat symbolic link to the input/output files
step01Prepare_LINK = step01
#  step01.2 create frame index 
step01Prepare_IDX  = step01
#  step01.3 package the data.nc
step01Prepare_PACK = step01
#  step01.4 calculate mean and std
step01Prepare_MV   = step01


# step02. create config.cfg for training
step02 = True
#  fine controls on each step (by default, conduct all steps)
#  step02.1 create configuration.cfg and networks.jsn
step02train_CFG    = step02
#  step02.2 train network
step02train_TRAIN  = step02


# step03. generate from network
step03 = True
#  fine controls on each step
#  step03.1: prepare test data 
step03Prepare_DATA = step03
#  step03.2: generate from network
step03NNGen = step03
#  step03.3: waveform generation
#     step03.3 is no longer supported here because we don't use
#     STRAIGHT / WORLD vocodoers for experiments
step03WaveFormGen = False


# ------------ Data configuration ------------
# list of data for train and validation sets
# if dataLists[n] = None, data in inputDirs[n] and outputDirs[n] will be used
# if dataLists[n] = PATH_TO_DATA_LIST, only data on the list will be used
#  here, we use data in ../DATA/vctk_anonymize/scp/train.lst as train set
#        we use data in ../DATA/vctk_anonymize/scp/val.lst as validation set
#tmpDir  = os.path.join(prjdir, '../DATA/vctk_anonymize')
tmpDir  = '/home/bsrivast/asr_data/LibriTTS/am_nsf_data/libritts/train_100'
dataLists = [tmpDir + '/scp/train.lst',
             tmpDir + '/scp/dev.lst']

# -- input feature configuration
# inputDirs: absolute path of directories of input features.
#   Input features may have multiple types of features, e.g., label-vector, speaker-id.
#   Please specify the features directories in this way:

#            [[training_set-input-feature-1,   training_set-input-feature-2, ..., ]
#             [validation_set-input-feature-1, valiadtion_set-input-feature-2, ..., ]]

#   Note: for one utterance, its input and output features should have the roughtly the
#   same number of frames. For example, if one utterance has N frames, the speaker-id
#   feature file should also contain N frames, where every frame has the same speaker-id.

#tmpDir  = os.path.join(prjdir, '../DATA/vctk_anonymize')
inputDirs = [[tmpDir + '/ppg/', tmpDir + '/xvector', tmpDir + '/f0'],
             [tmpDir + '/ppg/', tmpDir + '/xvector', tmpDir + '/f0']]

# inputDim: dimensions of each type of input features
#   len(inputDim) should be equal to len(inputDirs[0])
inputDim  = [346, 512, 1]

# inputExt: file name extension of input features
#   len(inputExt) should be equal to len(inputDirs[0])
inputExt  = ['.ppg', '.xvector', '.f0']

# normMask: which dimension should NOT be normalized?
#  len(inputNormMask) should be = len(inputDim)
#  for each inputNormMask[n]:
#    [start_dim, end_dim]: don't norm the dimensions from start_dim to end_dim
#    ['not_norm']: don't norm all dimensions
#    []: default (norm all the dimensions)
#  here, we normalize all the input features
inputNormMask = [[], [], []]


# -- output feature configuration
#  similar to input feature configurations

# outputDirs: specify the output feature directories.
#             Here, we have mgc, lf0, vuv, and bap as output features
#tmpDir  = os.path.join(prjdir, '../DATA/vctk_anonymize')
outputDirs= [[tmpDir + '/mel'],
             [tmpDir + '/mel']]

# outputDim: dimension of output features
outputDim = [80]

# outputExt: name extention of the output features
outputExt = ['.mel']

# normalize all the output features
outputNormMask = [[]]

#  Whether each output feature has delta / delta-delta component(s):
#   3: has static, delta-delta and delta
#   2: has static, delta
#   1: has static
#  Here, [1] means the output feature Mel doesn't contain delta features
outputDelta = [1]

# -- when output features contain F0
#  If F0 is not in the output features, set lf0UV = False, lf02f0 = False
#  
#  Whether conver generated interpolated 'F0' into un-interpolated 'F0'?
lf0UV = False
#  extension of log-liear f0
lf0ext = None
#  extension of vuv
vuvext = None

# Whether Convert generated F0 to linear domain?
lf02f0 = False
#  extension of linear f0
f0ext = None


# ---- data division
# dataDivision: name of each data division
#               inputDirs[0] + outputDirs[0] will be called the 'train' set
#               inputDirs[1] + outputDirs[1] will be called the 'val' set
dataDivision = ['train', 'dev']

# trainSet: which data division is used as the training set?
trainSet        = dataDivision[0]
# valSet:   which data division is used as the validation set?
valSet          = dataDivision[1]

# computMeanStdOn: on which data division the mean and std of input/output features are calculated?
#  By default, mean/std will be computed over the trainining set
computMeanStdOn = trainSet


# ------------ Model  configuration ------------
# path to the model directory
#   here, we will use MODELS/DAR_001/ as the model directory
# 
model_dir = os.path.join(prjdir, 'MODELS', 'DAR_001')

# path to the network file
#   here, we will use MODELS/RNN_001/network.jsn as the prototype network configuration
network = os.path.join(model_dir, 'network.jsn')

# path to the network training configuration file
#  Please configure it in advance if necessary
#  It is not necessary to change the default configuration
trainCfg = os.path.join(prjdir, 'train_config.cfg')

# configuration for the MDN layer (not needed for RNN model here)
mdnConfig    = []
initialModel = None
initialModelWhichLayers = None

# -------------------------------------------------
# --------------- Configuration start done --------------
# -------------------------------------------------
# Reserved configuration (no need to modify) 


# ------------ Generation configuration -----------
# Note: these generation configurations have been moved to ./01_gen.sh as environment variables
# test_inputDirs: directories of the test data files
if os.getenv('TEMP_ACOUSTIC_MODEL_INPUT_DIRS') is None:
    # specify here if you don't want to use getenv
    tmpDir  = os.path.join(prjdir, '../TESTDATA')
    test_inputDirs = [[tmpDir + '/lab_test', tmpDir + '/spk_test']]
else:
    tmp_inpput_path = os.getenv('TEMP_ACOUSTIC_MODEL_INPUT_DIRS')
    test_inputDirs = [tmp_inpput_path.split(',')]
    if len(test_inputDirs[0]) != len(inputDim):
        raise Exception("Error: invalid path TEMP_ACOUSTIC_MODEL_INPUT_DIRS=%s" % (tmp_inpput_path))
    
# test_modelDir: directory of the trained model
if os.getenv('TEMP_ACOUSTIC_MODEL_DIRECTORY') is None:
    test_modelDir = model_dir
else:
    test_modelDir = os.getenv('TEMP_ACOUSTIC_MODEL_DIRECTORY')
    
# test_network: path of the trained network.
#  You can also use *.autosave from any epoch rather than the final trained_network.jsn
if os.getenv('TEMP_ACOUSTIC_NETWORK_PATH') is None:
    test_network = os.path.join(test_modelDir, 'trained_network.jsn')
else:
    test_network = os.getenv('TEMP_ACOUSTIC_NETWORK_PATH')

# outputDir: directory to store generated acoustic features
if os.getenv('TEMP_ACOUSTIC_OUTPUT_DIRECTORY') is None:
    outputDir = os.path.join(test_modelDir, 'output_trained')
else:
    outputDir = os.getenv('TEMP_ACOUSTIC_OUTPUT_DIRECTORY')


# test_dataDivision: a temporary name to the test set
test_dataDivision = ['test']

# outputUttNum: how many utterances in test_inputDirs should be synthesized?
#  This is used for quick generation and debugging
#  By default -1, all the test files in test_inputDirs will be synthesized
outputUttNum = -1


# If MDN is used, choose the standard deviation of the noise for random sampling
#  0.0  -> mean-based generation
#  >0.0 -> sampling with the std of the noise distribution
#  -1.0 -> output the parameter set of the distribution
mdnSamplingNoiceStd = 0.00000

# nnCurrenntGenCommand: any other CURRENNT arguments for generation
#  If none, comment this out
# nnCurrenntGenCommand = None

# ----------- Waveform generation configuration ---------
# Other options for waveform generations.
#  Set step03WaveFormGen=False, if you use your own script for waveform generation
# 
# mlpgFlag: flags to use MLPG on each output features
#  len(mlpgFlag) should = len(outputDim)
#  MLPG can only be used on output features who outputDelta is 3
mlpgFlag = [1, 1, 0, 1]

# if mlpgFlag is 1, please specify the window and std for mlpg (HTS/data/var)
mlpgVar  = '/work/smg/wang/PROJ/PROJS/VCTK/VCTK68/HMM/HTS-NN-training/scripts/nndata'

# wavPostFilter: parameter to enhance formant through post-filtering
wavPostFilter = 0.8

# which waveform generator to be used? 'WORLD' or 'STRAIGHT'?
wavformGenerator = 'WORLD'


# --------------- Configuration start done --------------
# -------------------------------------------------

# Reserved configuration (no need to modify) 
debug = False

# path of pyTools
path_pyTools = os.getenv('TEMP_CURRENNT_PROJECT_PYTOOLS_PATH')
# path of CURRENNT
path_currennt = os.getenv('TEMP_CURRENNT_PROJECT_CURRENNT_PATH')
if path_currennt is None or path_pyTools is None:
    raise Exception("Please initialize the tool paths by source ../../init.sh")
# path of project scripts
path_scripts = prjdir + '/../SCRIPTS'
path_pyTools_scripts = path_pyTools + '/scripts/utilities-new'

#

nnDataDirName  = os.path.join(prjdir,'DATATEMP')
nnDataDirNameTrain = nnDataDirName

if os.getenv('TEMP_ACOUSTIC_TEMP_OUTPUT_DIRECTORY') is None:
    nnDataDirNameTest  = nnDataDirName + '_test'
else:
    # In case multiple processes are running simultaneously, the intermediate
    # files should be separated saved
    nnDataDirNameTest = os.getenv('TEMP_ACOUSTIC_TEMP_OUTPUT_DIRECTORY')

if os.getenv('TEMP_ADDITIONAL_COMMAND') is None:             
    # specify here if you don't want to use getenv           
    nnCurrenntGenCommand = None                                 
else:                                                        
    nnCurrenntGenCommand = os.getenv('TEMP_ADDITIONAL_COMMAND')
    

    
idxDirName    = 'idxFiles'
idxFileName   = 'idx'
nnDataNcPreFix= 'data.nc'
linkDirname   = 'link'
linkDirname_input  = 'link_input'
linkDirname_output = 'link_output'

nnDataInputMV='input_meanstd.bin'
nnDataOutputMV='output_meanstd.bin'
nnModelCfgname= 'config.cfg'
nnMDNConfigName='mdn.config'
#
fileNumInEachNCPack = 60000
tmp_network_trn_log = 'log_train'
tmp_network_trn_err = 'log_err'

wavGenWorldRequire    = ['mgc', 'bap', 'lf0']
wavGenStraightRequire = ['mgc', 'bap', 'lf0']


# External U/V data can be used if lf0UV = 1
#   directory of the external U/V data 
lf0UVExternalDir = None
#  extension of output vuv (for example, vuv)
lf0UVExternalExt = None
#  F0[t] is unvoiced if filename.lf0UVExternalExt[t] < lf0UVExternalThreshold
lf0UVExternalThre = None

#
test_outputDirs  = [[] for x in test_inputDirs]

synCfg = path_scripts + '/commonConfig/syn.cfg'
splitConfig  = 'data_split.py'

assert len(inputDirs) == len(dataDivision), "len(inputDirs != len(dataDivision))"
assert len(outputDirs)== len(dataDivision), "len(outputDirs != len(dataDivision))"
assert len(test_inputDirs)== len(test_dataDivision), "len(test_inputDirs != len(test_dataDivision))"
assert len(inputDim) == len(inputExt), "len(inputDim) != len(inputExt)"
assert len(inputDim) == len(inputNormMask), "len(inputDim) != len(inputNormMask)"
assert len(outputDim) == len(outputExt), "len(outputDim) != len(outputExt)"
assert len(outputDim) == len(outputNormMask), "len(outputputDim) != len(outputNormMask)"
assert len(outputDim) == len(outputDelta), "len(outputputDim) != len(outputDelta)"

#
inputExt = [x.lstrip('.') for x in inputExt if x.startswith('.')]
outputExt = [x.lstrip('.') for x in outputExt if x.startswith('.')]


if not len(list(set(outputExt))) == len(outputExt):
    print("Error: some output features use the same name extensions.")
    print("Error: please modify file name extensions and outputExt in config")
    raise Exception("Configure error")

if not len(list(set(inputExt))) == len(inputExt):
    print("Error: some output features use the same name extensions.")
    print("Error: please modify file name extensions and outputExt in config")
    raise Exception("Configure error")
