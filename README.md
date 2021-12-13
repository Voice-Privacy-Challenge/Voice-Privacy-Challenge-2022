# Recipe for VoicePrivacy Challenge 2022

## Under construction...

Please visit the [challenge website](https://www.voiceprivacychallenge.org/) for more information about the Challenge.


## Install

1. `git clone --recurse-submodules https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022.git`
2. ./install.sh

## Running the recipe

The recipe uses the pre-trained models of anonymization. To run the baseline system with evaluation:

1. `cd baseline`
2. run `./run.sh`. In run.sh, to download models and data the user will be requested the password which is provided during the Challenge registration.

## General information

For more details about the baseline and data, please see [The VoicePrivacy 2020 Challenge Evaluation Plan](https://www.voiceprivacychallenge.org/docs/VoicePrivacy_2020_Eval_Plan_v1_3.pdf)

For the latest updates in the baseline and evaluation scripts, please visit [News and updates page](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020/wiki/News-and-Updates)

To participate in the **VoicePrivacy 2022 Challenge** and get access to evaluation datasets and models, please send an email to organisers@lists.voiceprivacychallenge.org with “VoicePrivacy-2022" as the subject line. The mail body should include: (i) the name of the contact person; (ii) country; (iii) status (academic/nonacademic).


## Data

#### Training data
The dataset for anonymization system traing consists of subsets from the following corpora*:
* [LibriSpeech](http://www.openslr.org/12/) - train-clean-100, train-other-500
* [LibriTTS](http://www.openslr.org/60/) - train-clean-100, train-other-500
* [VoxCeleb 1 & 2](http://www.robots.ox.ac.uk/~vgg/data/voxceleb/) - all

*only specified subsets of these corpora can be used for training.

#### Development and evaluation data
* [VCTK](https://datashare.is.ed.ac.uk/handle/10283/3443) - subsets vctk_dev and vctk_test are download from server in run.sh
* [LibriSpeech](http://www.openslr.org/12/) - subsets libri_dev and libri_test are download from server in run.sh


##  Baseline-1: Anonymization  using x-vectors and neural waveform models 

This is the primary (default) baseline.

### Models

The baseline system uses several independent models:
1. ASR acoustic model to extract BN features (`1_asr_am`) - trained on LibriSpeech-train-clean-100 and LibriSpeech-train-other-500
2. X-vector extractor (`2_xvect_extr`) - trained on VoxCeleb 1 & 2.
3. Speech synthesis (SS) acoustic model (`3_ss_am`) - trained on LibriTTS-train-clean-100.
4. Neural source filter (NSF) model (`4_nsf`) - trained on LibriTTS-train-clean-100.

<img src="https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020/blob/master/baseline/fig/baseline_git.jpg" width="60%" height="60%">

All the pretrained models are provided as part of this baseline (downloaded by ./baseline/local/download_models.sh)


##  Baseline-2: Anonymization using McAdams coefficient

This is an additional baseline.

To run: `./run.sh --mcadams true`

It does not require any training data and is based upon simple signal processing techniques using the McAdams coefficient.



## Results

The result file with all the metrics and all datasets for submission will be generated in: ./baseline/exp/results-`date`-`time`/results.txt

Please see 
* [RESULTS for Baseline-1](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020/blob/master/baseline/RESULTS_baseline) 
* [RESULTS for Baseline-2](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020/blob/master/baseline/RESULTS_mcadams) 

  **new baselies 2022**:
* [RESULTS_for Baseline TTS-pytorch](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/RESULTS_baseline_tts_pytorch)
* [RESULTS_for Baseline TTS-pytorch, HIFI-GAN](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/RESULTS_baseline_tts_joint_hifigan)
* [RESULTS_for Baseline TTS-pytorch, NSF+HIFI-GAN](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/RESULTS_baseline_tts_joint_nsf_hifigan)

for the evalation and development data sets.


## Organizers (in alphabetical order)

- Jean-François Bonastre - University of Avignon - LIA, France
- Nicholas Evans - EURECOM, France
- Pierre Champion - Inria, France
- Xiaoxiao Miao - NII, Japan
- Hubert Nourtel - Inria, France
- Natalia Tomashenko - University of Avignon - LIA, France
- Massimiliano Todisco - EURECOM, France
- Emmanuel Vincent - Inria, France
- Xin Wang - NII, Japan
- Junichi Yamagishi - NII, Japan and University of Edinburgh, UK

Contact: organisers@lists.voiceprivacychallenge.org


## Acknowledgements

This work was supported in part by the French National Research Agency under project DEEP-PRIVACY (ANR-18-
CE23-0018) and by the European Union’s Horizon 2020 Research and Innovation Program under Grant Agreement No. 825081 COMPRISE (https://www.compriseh2020.eu/), and jointly by the French National Research Agency and the Japan Science and Technology Agency under project VoicePersonae. 

## License

Copyright (C) 2021

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

## References

```
@inproceedings{tomashenko2020introducing,
  author={N. Tomashenko and Brij Mohan Lal Srivastava and Xin Wang and Emmanuel Vincent and Andreas Nautsch and Junichi Yamagishi and Nicholas Evans and Jose Patino and Jean-François Bonastre and Paul-Gauthier Noé and Massimiliano Todisco},
  title={{Introducing the VoicePrivacy Initiative}},
  year=2020,
  booktitle={Proc. Interspeech 2020},
  pages={1693--1697},
  doi={10.21437/Interspeech.2020-1333},
  url={http://dx.doi.org/10.21437/Interspeech.2020-1333}
}
```

```
article{tomashenkovoiceprivacy,
  title={The {VoicePrivacy} 2020 {Challenge} Evaluation Plan},
  author={Tomashenko, Natalia and Srivastava, Brij Mohan Lal and Wang, Xin and Vincent, Emmanuel and Nautsch, Andreas and Yamagishi, Junichi and Evans, Nicholas and Patino, Jose and Bonastre, Jean-Fran{\c{c}}ois and No{\'e}, Paul-Gauthier and Todisco, Massimiliano},
  url={https://www.voiceprivacychallenge.org/docs/VoicePrivacy_2020_Eval_Plan_v1_3.pdf},
  year={2020}
}
```

## Anonymization metrics

- Equal error rate (EER)
- Log-likelihood-ratio cost function (Cllr and Cllr-min)
- [The Privacy ZEBRA: Zero Evidence Biometric Recognition Assessment (expected privacy disclosure (population) and worst case privacy disclosure (individual))](https://www.isca-speech.org/archive_v0/Interspeech_2020/pdfs/1815.pdf)
- [Speech Pseudonymisation Assessment Using Voice Similarity Matrices (de-identification and voice distinctiveness preservation)](https://www.isca-speech.org/archive_v0/Interspeech_2020/pdfs/2720.pdf)
- Linkability
