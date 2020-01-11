# Recipe for voice privacy challenge 2020

## First steps

Clone this recipe inside the `egs` directory of you Kaldi installation. Then download the pretrained models from the challenge website and extract them in `v1/exp` directory.

## More details

To successfully run the recipe, you must configure some variables in the scripts, particularly in the main script: `run.sh`. VPC uses several datasets and modules to evaluate generalized anonymization techniques. Visit the [challenge website](https://www.voiceprivacychallenge.org/) for detailed information.

Some of the datasets we use are:
* [LibriSpeech](http://www.openslr.org/12/)
* [LibriTTS](http://www.openslr.org/60/)
* [VCTK](https://homepages.inf.ed.ac.uk/jyamagis/page3/page58/page58.html)
* [VoxCeleb 1 & 2](http://www.robots.ox.ac.uk/~vgg/data/voxceleb/)

The architecture of VPC is composed of several independent modules:
* Phonetic posteriorgram (PPG) extractor
* x-vector extractor
* Voice conversion using acoustic and neural source filter models
* Anonymization using PLDA distance

Some of these modules are pretrained and must be downloaded and put in appropriate directories for the recipe to work successfully.

## Dataset

- `librispeech_corpus`: change this variable to point at your extracted LibriSpeech corpus.
- `anoni_pool`: change this variable to the data directory in `data/` folder which will be used as anonymization pool of speakers. Please note that this directiry must be in Kaldi data format.

## Modules

### PPG extractor

This is a chain ASR model trained using 600 hours (train-clean-100 and train-other-500) of LibriSpeech. It produces 346 dimentional PPGs. This must include:

- `ivec_extractor`: i-vector extractor trained during training the chain model.
- `tree_dir`: Tree directory created during traininig the chain model.
- `lang_dir`: Lang directory for chain model
- `model_dir`: Directory where pretrained chain model is stored


### x-vector extractor

This is a pretrained xvector model trained over VoxCeleb 1 & 2, it can easily downloaded using the following [link](http://kaldi-asr.org/models/7/0007_voxceleb_v2_1a.tar.gz). It should be extracted in the `exp` directory of this recipe.

- `xvec_nnet_dir`: Directory where trained xvector network is stored
- `pseudo_xvec_rand_level`: anonymized x-vectors will be produced at this level, e.g. `spk` or `utt`
- `cross_gender`: should anonymization be done within same gender or across gender, e.g. `true` or `false`.


## External modules for voice converison

For voice conversion we utilize the Neural source-filter model provided by NII, Japan. You must clone and install it at your desired location. These locations will be needed to configure the recipe.

### Installation

NII provides two repositories:
- [CURRENNT base code](https://github.com/nii-yamagishilab/project-CURRENNT-public)
- [AM and NSF scripts](https://github.com/nii-yamagishilab/project-CURRENNT-scripts)

Install these two based on the instructions at their respective github READMEs. After installation follow below instructions for configuring the recipe.

### Acoustic model for voice conversion

This module will take 3 inputs: 
- PPGs
- x-vectors
- F0

The pretrained model will be provided as part of this baseline. It has been trained over 100 hour subset (train-clean-100) of LibriTTS dataset. Following configs are needed:

  1. Open `local/vc/am/init.sh` and change the variables `TEMP_CURRENNT_PROJECT_PYTOOLS_PATH` and `TEMP_CURRENNT_PROJECT_CURRENNT_PATH` to appropriate paths based on above installation.
  2. Open `local/vc/am/01_gen.sh` and change `proj_dir` to the directory where `project-DAR-continuous` is present in your installation. Possibly also change `TEMP_ACOUSTIC_MODEL_DIRECTORY` here to the place where your pretrained AM is stored. This directory must contain `trained_network.jsn` which will have parameters for your pretrained acoustic model. This model will be provided during the challenge.

### Neural source-filter model for voice conversion

This module will take 3 inputs: 
- Mel filterbanks extracted by AM
- x-vectors
- F0

The pretrained model will be provided as part of this baseline. It has been trained over 100 hour subset (train-clean-100) of LibriTTS dataset. Following configs are needed:

  1. Open `local/vc/nsf/init.sh` and change the variables `TEMP_CURRENNT_PROJECT_PYTOOLS_PATH` and `TEMP_CURRENNT_PROJECT_CURRENNT_PATH` to appropriate paths based on above installation.
  2. Open `local/vc/nsf/01_gen.sh` and change `proj_dir` to the directory where `project-NSF` is present in your installation. Possibly also change `TEMP_WAVEFORM_MODEL_DIRECTORY` and `TEMP_WAVEFORM_MODEL_NETWORK_PATH` here to the place where your pretrained NSF is stored. Note that `TEMP_WAVEFORM_MODEL_NETWORK_PATH` is a `.jsn` file which will have parameters for your pretrained NSF model. This model will be provided during the challenge.

