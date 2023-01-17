# Recipe for VoicePrivacy Challenge 2022


Please visit the [challenge website](https://www.voiceprivacychallenge.org/) for more information about the Challenge.


## Install

1. `git clone --recurse-submodules https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022.git`
2. ./install.sh

## Running the recipe

The recipe uses the pre-trained models of anonymization. To run the baseline system with evaluation:

1. `cd baseline`
2. run `./run.sh`. In run.sh, to download models and data the user will be requested the password which is provided during the Challenge registration.

## General information

For more details about the baseline and data, please see [The VoicePrivacy 2022 Challenge Evaluation Plan](https://www.voiceprivacychallenge.org/vp2020/docs/VoicePrivacy_2022_Eval_Plan_v1.0.pdf)

For the latest updates in the baseline and evaluation scripts, please visit [News and updates page](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020/wiki/News-and-Updates)

The **VoicePrivacy 2022 Challenge** is over. To get access to evaluation datasets and models, please send an email to organisers@lists.voiceprivacychallenge.org with “VoicePrivacy-2022 registration" as the subject line. The mail body should include: 

* (i) the name of the team; 
* (ii) the name of the contact person; 
* (iii) their affiliation;
* (iv) their country; 
* (v) their status (academic/nonacademic).

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


##  Baselines

### Baseline B1.a: Anonymization  using x-vectors and neural waveform models

This is the same baseline as the primary baseline for the VoicePrivacy-2020.
In [config.sh](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/config.sh) parameters: 
`baseline_type=baseline-1` ` tts_type=am_nsf_old`

#### Models

The baseline B1.b system uses several independent models:
1. ASR acoustic model to extract BN features (`1_asr_am`) - trained on LibriSpeech-train-clean-100 and LibriSpeech-train-other-500
2. X-vector extractor (`2_xvect_extr`) - trained on VoxCeleb 1 & 2.
3. Speech synthesis (SS) acoustic model (`3_ss_am`) - trained on LibriTTS-train-clean-100.
4. Neural source filter (NSF) model (`4_nsf`) - trained on LibriTTS-train-clean-100.

<img src="https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/fig/B1a.jpg" width="60%" height="60%">

All the pretrained models are provided as part of this baseline (downloaded by ./baseline/local/download_models.sh)

### Baseline B1.b: Anonymization using x-vectors and neural waveform models (HiFi-GAN + NSF)
The main difference wrt to B1.a is in the speech synthesis component of the anonymization system, B1.b directly converts BN features, F0, and x-vector using an NSF model. 

#### Models
The baseline B1.b system uses several independent models:
1. ASR acoustic model to extract BN features (`1_asr_am`) - trained on LibriSpeech-train-clean-100 and LibriSpeech-train-other-500
2. X-vector extractor (`2_xvect_extr`) - trained on VoxCeleb 1 & 2.
3. Speech synthesis model HiFi-GAN + NSF (`5_joint_tts_nsf_hifigan`) - trained on LibriTTS-train-clean-100.


In [config.sh](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/config.sh) parameters:
`baseline_type=baseline-1` ` tts_type=joint_nsf_hifigan`

<img src="https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/fig/B1b.jpg" width="60%" height="60%">

###  Baseline B2: Anonymization using McAdams coefficient (randomized version)

This ia a randomized version of the McAdams algorithm, where the McAdams coefficient is sampled for each source speaker in the evaluation set from a uniform
distribution in the interval `[mc_coeff_min, mc_coeff_max]`

In [config.sh](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/config.sh) parameters:  
`baseline_type=baseline-2` ` mc_coeff_min=0.5` ` mc_coeff_max=0.9`

It does not require any training data and is based upon simple signal processing techniques using the McAdams coefficient.



## Results

The result file with all the metrics and all datasets for submission will be generated in:
* Summary results: `  ./baseline/exp/results-<date>-<time>/results_summary.txt`
* Additional metrics obtained using `ASR_eval` and `ASV_eval` trained on original data:  `  ./baseline/exp/results-<date>-<time>.orig/results_summary.txt`
* Additional metrics obtained using `ASR_eval^anon` and `ASV_eval^anon` trained on anonymized data:  `  ./baseline/exp/results-<date>-<time>/results_summary.txt`

Please see 
* Summary [RESULTS B1.a](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/results/RESULTS_summary_tts_old_c)
* Summary [RESULTS B1.b](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/results/RESULTS_summary_tts_joint_nsf_hifigan)
* Summary [RESULTS B2](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/results/RESULTS_summary_mcadams)

  **other anonymization systems**:
* [RESULTS for Baseline TTS-pytorch](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/results/RESULTS_summary_tts_pytorch)
* [RESULTS for Baseline TTS-pytorch, HIFI-GAN](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2022/blob/master/baseline/results/RESULTS_summary_tts_joint_hifigan)

for the evalation and development data sets.


## Organizers (in alphabetical order)

- **Jean-François Bonastre** - University of Avignon - LIA, France
- **Nicholas Evans** - EURECOM, France
- **Pierre Champion** - Inria, France
- **Xiaoxiao Miao** - NII, Japan
- **Hubert Nourtel** - Inria, France
- **Natalia Tomashenko** - University of Avignon - LIA, France
- **Massimiliano Todisco** - EURECOM, France
- **Emmanuel Vincent** - Inria, France
- **Xin Wang** - NII, Japan
- **Junichi Yamagishi** - NII, Japan and University of Edinburgh, UK

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
article{vpc2022,
  title={The {VoicePrivacy} 2022 {Challenge} Evaluation Plan},
  author={Tomashenko, Natalia and Wang, Xin and Miao, Xiaoxiao and Nourtel, Hubert and Champion, Pierre and Todisco, Massimiliano and Vincent, Emmanuel and Evans, Nicholas and Yamagishi, Junichi and Bonastre, Jean-François
},
  url={https://www.voiceprivacychallenge.org/docs/VoicePrivacy_2022_Eval_Plan_v1.0.pdf},
  year={2022}
}
```

## Anonymization metrics

#### VoicePrivacy 2022 primary privacy metric:
- Equal error rate (EER)

#### Other metrics:
- Log-likelihood-ratio cost function (Cllr and Cllr-min)
- [The Privacy ZEBRA: Zero Evidence Biometric Recognition Assessment (expected privacy disclosure (population) and worst case privacy disclosure (individual))](https://www.isca-speech.org/archive_v0/Interspeech_2020/pdfs/1815.pdf)
- [Speech Pseudonymisation Assessment Using Voice Similarity Matrices (de-identification and voice distinctiveness preservation)](https://www.isca-speech.org/archive_v0/Interspeech_2020/pdfs/2720.pdf)
- Linkability
