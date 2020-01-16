#!/bin/bash

voxceleb_model_tar="0007_voxceleb_v2_1a.tar.gz"
voxceleb_model_url="http://kaldi-asr.org/models/7"

# Download Voxceleb model
mkdir -p exp data
pushd ./exp 

wget --no-check-certificate ${voxceleb_model_url}/${voxceleb_model_tar}
tar -zxvf ${voxceleb_model_tar}

# Install expect for downloading files using sftp
sudo apt install expect

# Download LibriSpeech chain model - not available currently
PASSWD="" # Enter your sftp password here
expect -c 'spawn sftp -P 28500 voiceprivacy@gitlia.univ-avignon.fr; 
expect "*password: ";
send "$env(PASSWD)\r";
expect "sftp>";
send "cd /voiceprivacy/pretrained_models \r";
expect "sftp>";
send "get am_model.tar.gz \r";
expect "sftp>";
send "get nsf_model.tar.gz \r";
expect "sftp>";
send "get asr_ppg_model.tar.gz \r";
expect "sftp>";
send "get asr_eval_model.tar.gz \r";
expect "sftp>";
send "bye \r"'

# Extract all pretrained models
tar -zxvf am_model.tar.gz
tar -zxvf nsf_model.tar.gz
tar -zxvf asr_ppg_model.tar.gz
tar -zxvf asr_eval_model.tar.gz

popd >&/dev/null
