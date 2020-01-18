# Recipe for VoicePrivacy Challenge 2020

Please visit the [challenge website](https://www.voiceprivacychallenge.org/) for more information about the Challenge.


## First steps

1. `git clone --recurse-submodules https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020.git`
2. Download the pretrained models from the challenge website and extract them in `baseline/exp` directory.
3. Create Python virtual environment for dependencies using `virtualenv venv && . venv/bin/activate`. Then install requirements in this `venv` using `pip install -r baseline/requirements.txt`.
4. Install external dependecies as described below.
5. Configure appropriate paths in `baseline/path.sh` as described below.

## More details

To successfully run the recipe, you must configure some variables in the scripts, particularly in the main script: `run.sh`. VPC uses several datasets and modules to evaluate generalized anonymization techniques. 


### Datasets

The datasets for traing/development/evaluation consists of subsets from the following corpora:
* [LibriSpeech](http://www.openslr.org/12/)
* [LibriTTS](http://www.openslr.org/60/)
* [VCTK](https://datashare.is.ed.ac.uk/handle/10283/3443)
* [VoxCeleb 1 & 2](http://www.robots.ox.ac.uk/~vgg/data/voxceleb/)

- `librispeech_corpus`: change this variable to point at your extracted LibriSpeech corpus.
- `libritts_corpus`: change this variable to the directory where you have extracted `train-other-500` subset of LibriTTS corpus.

### Models

The baseline system uses several independent models:
1. ASR acoustic model to extract BN features (1_asr_am)
2. X-vector extractor (2_xvect_extr)
3. Speech synthesis (SS) acoustic model (3_ss_am)
4. Neural source filter (NSF) model (4_nsf)

These models optionally can be:
*  trained with the provided scripts;
or
* downloaded ... and put in appropriate directories.





=========================================================

    * TO CORRECT // Anonymization using PLDA distance

**NOTE**: These variables will be pre-configured if you have downloaded the 4 pre-trained models (`am_model.tar.gz`, `nsf_model.tar.gz`, `asr_ppg_model.tar.gz` and `asr_eval_model.tar.gz`) and extracted in the `exp` directory of your recipe.


## Modules

### BN extractor

This is a chain ASR model trained using 600 hours (train-clean-100 and train-other-500) of LibriSpeech for BN feature extraction

- `ivec_extractor`: i-vector extractor trained during training the chain model.
- `model_dir`: Directory where pretrained chain model is stored


### PPG extractor (optional or will be removed later) 

This is a chain ASR model trained using 600 hours (train-clean-100 and train-other-500) of LibriSpeech. It produces 346 dimentional PPGs. This must include:

- `ivec_extractor`: i-vector extractor trained during training the chain model.
- `tree_dir`: Tree directory created during traininig the chain model.
- `lang_dir`: Lang directory for chain model
- `model_dir`: Directory where pretrained chain model is stored

### x-vector extractor

This is a pretrained xvector model trained over VoxCeleb 1 & 2. It should be extracted in the `exp` directory of this recipe.

- `xvec_nnet_dir`: Directory where trained xvector network is stored
- `pseudo_xvec_rand_level`: anonymized x-vectors will be produced at this level, e.g. `spk` or `utt`
- `cross_gender`: should anonymization be done within same gender or across gender, e.g. `true` or `false`.

**NOTE**: This model will be downloaded and extracted using `step -1` of the recipe.

## External modules for voice converison

For voice conversion we utilize the Neural source-filter model provided by NII, Japan. You must clone and install it at your desired location. These locations will be needed to configure the recipe.

### Installation

NII provides two repositories:
- [CURRENNT base code](https://github.com/nii-yamagishilab/project-CURRENNT-public)
- [AM and NSF scripts](https://github.com/nii-yamagishilab/project-CURRENNT-scripts)

Install these two based on the instructions at their respective github READMEs. After installation follow below instructions for configuring the recipe.

### Acoustic model for voice conversion

This module will take 3 inputs: 
- BN
- x-vector
- F0

The pretrained model will be provided as part of this baseline. It has been trained over 100 hour subset (train-clean-100) of LibriTTS dataset. Following configs are needed:

  1. Open `baseline/path.sh` and change the variables `CURRENT_PUBLIC` and `CURRENNT_SCRIPTS` to directory where you cloned [CURRENNT base code](https://github.com/nii-yamagishilab/project-CURRENNT-public) and [AM and NSF scripts](https://github.com/nii-yamagishilab/project-CURRENNT-scripts) respectively.

### Neural source-filter model for voice conversion

This module will take 3 inputs: 
- Mel filterbanks extracted by SS AM
- x-vector
- F0

The pretrained model will be provided as part of this baseline. It has been trained over 100 hour subset (train-clean-100) of LibriTTS dataset. Following configs are needed:

**NO changes required if acoustic model setup is done**, otherwise:

  1. Open `baseline/path.sh` and change the variables `CURRENT_PUBLIC` and `CURRENNT_SCRIPTS` to directory where you cloned [CURRENNT base code](https://github.com/nii-yamagishilab/project-CURRENNT-public) and [AM and NSF scripts](https://github.com/nii-yamagishilab/project-CURRENNT-scripts) respectively.


## License

Copyright (C) 2020

Multispeech, INRIA France; 

LIA, University of Avignon, France;

NII, Japan.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

Authors : Brij Mohan Lal Srivastava (INRIA France), Natalia Tomashenko (LIA, France), Xin Wang (NII Japan), ...

Date : 2020

Contact : voice.privacy.challenge@gmail.com

---------------------------------------------------------------------------
