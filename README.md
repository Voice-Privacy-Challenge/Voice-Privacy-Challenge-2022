# Recipe for VoicePrivacy Challenge 2020

Please visit the [challenge website](https://www.voiceprivacychallenge.org/) for more information about the Challenge.


## Install

1. `git clone --recurse-submodules https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020.git`
2. ./install.sh
3. ./download_models.sh

## Running the recipe

The recipe comes with pre-trained models of anonymization. To replicate the baseline numbers, `cd baseline` and change the following variables:

1. `librispeech_corpus`: The directory for LibriSpeech corpus. It must have `dev-clean`, `test-clean` and `train-clean-360` subsets.
2. `libritts_corpus`: The directory for LibriTTS corpus. It must have `train-other-500` subset.
3. `data_netcdf`: This is where anonymized files and features will be stored. Make sure you have enough space (at least 20Gb) on this disk.

After these changes simply `./run.sh`.


## General information

### Datasets

The datasets for traing/development/evaluation consists of subsets from the following corpora:
* [LibriSpeech](http://www.openslr.org/12/)
* [LibriTTS](http://www.openslr.org/60/)
* [VCTK](https://datashare.is.ed.ac.uk/handle/10283/3443)
* [VoxCeleb 1 & 2](http://www.robots.ox.ac.uk/~vgg/data/voxceleb/)


### Models

The baseline system uses several independent models:
1. ASR acoustic model to extract BN features (asr_am)
2. X-vector extractor (xvect_extr)
3. Speech synthesis (SS) acoustic model (ss_am)
4. Neural source filter (NSF) model (nsf)

These models optionally can be:
*  trained with the provided scripts;
or
* downloaded (done by ./download_models.sh)



    
### Models info

#### BN extractor

This is a chain ASR model trained using LibriSpeech-train-clean-100 and LibriSpeech-train-other-500 for BN feature extraction

- `ivec_extractor`: i-vector extractor trained during training the chain model.
- `model_dir`: Directory where pretrained chain model is stored


#### x-vector extractor

This is a xvector model trained over VoxCeleb 1 & 2.

- `xvec_nnet_dir`: Directory where trained xvector network is stored
- `pseudo_xvec_rand_level`: anonymized x-vectors will be produced at this level, e.g. `spk` or `utt`
- `cross_gender`: anonymization is done within same gender or across gender, e.g. `true` or `false`.


#### Acoustic model for voice conversion

This module takes 3 inputs: 
- BN
- x-vector
- F0

The pretrained model is provided as part of this baseline. It is trained on LibriTTS-train-clean-100.


#### Neural source-filter model for voice conversion

This module will take 3 inputs: 
- Mel filterbanks extracted by SS AM
- x-vector
- F0

The pretrained model will be provided as part of this baseline. It is trained on LibriTTS-train-clean-100.


 

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
