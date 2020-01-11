#!/bin/bash

voxceleb_model_tar="0007_voxceleb_v2_1a.tar.gz"
voxceleb_model_url="http://kaldi-asr.org/models/7"

# Download Voxceleb model
mkdir -p exp data
pushd ./exp 

wget --no-check-certificate ${voxceleb_model_url}/${voxceleb_model_tar}
tar -zxvf ${voxceleb_model_tar}

# Download LibriSpeech chain model - not available currently

popd >&/dev/null
