# Recipe for VoicePrivacy Challenge 2020

Please visit the [challenge website](https://www.voiceprivacychallenge.org/) for more information about the Challenge.


## Install

1. `git clone --recurse-submodules https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020.git`
2. ./install.sh

## Running the recipe

The recipe uses the pre-trained models of anonymization. To run the baseline system with evaluation:

1. `cd baseline` 
2. (optionally) change the following variables in `run.sh`:
- `librispeech_corpus`: The directory for LibriSpeech corpus (will contain `dev-clean`, `train-clean-360`, `train-clean-100`,`train-other-500` subsets).
- `libritts_corpus`: The directory for LibriTTS corpus (will contain `train-other-500` subset).
- `data_netcdf`: Directory where anonymized files and features will be stored (it requires at least 20Gb).
3. run `./run.sh`.


## General information

### Datasets

The datasets for traing/development/evaluation consists of subsets from the following corpora*:
* [LibriSpeech](http://www.openslr.org/12/)
* [LibriTTS](http://www.openslr.org/60/)
* [VCTK](https://datashare.is.ed.ac.uk/handle/10283/3443)
* [VoxCeleb 1 & 2](http://www.robots.ox.ac.uk/~vgg/data/voxceleb/)

*only specified subsets of these corpora can be used to train/develop an anonymization system.


### Models

The baseline system uses several independent models:
1. ASR acoustic model to extract BN features (asr_am)
2. X-vector extractor (xvect_extr)
3. Speech synthesis (SS) acoustic model (ss_am)
4. Neural source filter (NSF) model (nsf)

These models optionally can be:
*  trained with the provided scripts;
or
* downloaded (done by ./baseline/local/download_models.sh)



    
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


## Organizers (in alphabetical order)

Jean-François Bonastre - University of Avignon - LIA, France
Nicholas Evans - EURECOM, France
Fuming Fang - NII, Japan
Andreas Nautsch - EURECOM, France
Paul-Gauthier Noé - University of Avignon - LIA, France
Jose Patino - EURECOM, France
Md Sahidullah - Inria, France
Brij Mohan Lal Srivastava - Inria, France
Natalia Tomashenko - University of Avignon - LIA, France
Massimiliano Todisco - EURECOM, France
Emmanuel Vincent - Inria, France
Xin Wang - NII, Japan
Junichi Yamagishi - NII, Japan and University of Edinburgh, UK

Contact : voice.privacy.challenge@gmail.com


## Acknowledgements

This work was supported in part by the French National Research Agency under projects HARPOCRATES (ANR-19-DATA-0008) and DEEP-PRIVACY (ANR-18-
CE23-0018), by the European Union’s Horizon 2020 Research and Innovation Program under Grant Agreement No. 825081 COMPRISE (https://www.compriseh2020.eu/), and jointly by the French National Research Agency and the Japan Science and Technology Agency under project VoicePersonae. 

## License

Copyright (C) 2020

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

---------------------------------------------------------------------------
