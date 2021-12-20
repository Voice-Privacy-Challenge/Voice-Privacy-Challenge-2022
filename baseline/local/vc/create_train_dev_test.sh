#!/bin/bash
# Creating the train dev and test division lists for TTS training

. ./cmd.sh
. ./path.sh
. ./config.sh

set -e

nj=20
stage=0

#Directory with the prepared data (x-vectors, BN, pitch, ...) for training TTS model 
data_dir=

. ./utils/parse_options.sh


if [ $stage -le 0 ]; then

    # get the pre-defined training, development, and test division
    if [ ${tts_use_predefined_trn_dev} == "True" ];
    then
	
	if [ ${data_train_tts} != "train-clean-100" ];
	then
	    printf "Pre-defined train/dev split is only available for train-clean-100\n"
	    printf "Please set tts_use_predefined_trn_dev to False\n"
	    exit 1
	fi

	# use prepared train/dev/test division for TTS models
	wget -q https://www.dropbox.com/sh/bua2vks8clnl2ha/AAAz-cEvBzNxsnoGNRYdKnDIa/scp.tar.gz
	tar -xzf scp.tar.gz
	rm scp.tar.gz
	if [ -d ${data_dir}/scp ];
	then
	    # if ${data_dir}/scp exists, cp new lists to ${data_dir}/scp
	    cp scp/*.lst ${data_dir}/scp
	    rm -r scp
	else
	    # move scp directly to ${data_dir}/scp
	    mv scp ${data_dir}/scp
	fi
    else

	cd ${data_dir}/scp
	if [ ${data_train_tts} != "train-clean-100" ];
	then
	    printf "Random split of train/dev for ${data_train_tts} is not defined\n"
	    printf "Please revise local/vc/create_train_dev_test.sh"
	    exit 1
	else
	    # generate randomly splitted
	    cat data.lst | sort -R > tmp.lst
	    head -n 28400 tmp.lst > train.lst
	    head -n 31016 tmp.lst | tail -n 2616 > dev.lst
	    tail -n 2220 tmp.lst > test.lst
	    rm tmp.lst
	fi
	cd -
    fi
fi
