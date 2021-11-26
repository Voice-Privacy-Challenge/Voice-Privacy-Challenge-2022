# Config for the 2022 VoicePrivacy Challenge

##########################################################
# Common settings

nj=$(nproc)


baseline_type=baseline-1  # x-vector-kaldi + TTS
#baseline_type=baseline-2 # mcadams
#baseline_type=baseline-3 # x-vector-sidekit + TTS
#baseline_type=baseline-4 # ...

# if [ $baseline_type = 'baseline-1' ]; then


# elif [ $baseline_type = 'baseline-2' ]; then


# elif [ $baseline_type = 'baseline-3' ]; then


# elif [ $baseline_type = 'baseline-4' ]; then


# fi

##########################################################
# Download settings

download_full=false  # If download_full=true all the data that can be used in the training/development will be dowloaded (except for Voxceleb-1,2 corpus); otherwise - only those subsets that are used in the current baseline (with the pretrained models)
data_url_librispeech=www.openslr.org/resources/12  # Link to download LibriSpeech corpus
data_url_libritts=www.openslr.org/resources/60     # Link to download LibriTTS corpus
corpora=corpora
anoni_pool="libritts_train_other_500"

eval_sets='libri vctk'
eval_subsets='dev test'


##########################################################
# Extract x-vectors

if [ $baseline_type != 'baseline-2' ]; then
	xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a # x-vector extraction
	anon_xvec_out_dir=${xvec_nnet_dir}/anon # x-vector extraction
fi


##########################################################
# Anonymization

anon_level_trials="spk"                # spk (speaker-level anonymization) or utt (utterance-level anonymization)
anon_level_enroll="spk"                # spk (speaker-level anonymization) or utt (utterance-level anonymization)
anon_data_suffix=_anon

if [ $baseline_type = 'baseline-2' ]; then
	#McAdams anonymisation configs
	n_lpc=20
	mc_coeff_enroll=0.8                    # mc_coeff for enrollment 
	mc_coeff_trials=0.8                    # mc_coeff for trials
elif [ $baseline_type = 'baseline-1' ] || [ $baseline_type = 'baseline-3' ]; then
	ppg_model=exp/models/1_asr_am/exp # Chain model for BN extraction
	ppg_dir=${ppg_model}/nnet3_cleaned # Chain model for BN extraction
	cross_gender="false"                   # false (same gender xvectors will be selected) or true (other gender xvectors)
	distance="plda"                        # cosine or plda
	proximity="farthest"                   # nearest or farthest speaker to be selected for anonymization
fi


##########################################################
# Evaluation settings (common)
printf -v results '%(%Y-%m-%d-%H-%M-%S)T' -1
results=exp/results-$results
#results=exp/results-$(printf -v results '%(%Y-%m-%d-%H-%M-%S)T' -1)

##########################################################
# ASR evaluation settings

asr_eval_model=exp/models/asr_eval # Chain model for ASR evaluation

##########################################################
# ASV evaluation settings

asv_eval_model=exp/models/asv_eval/xvect_01709_1 # ASV_eval model
plda_dir=${asv_eval_model}/xvect_train_clean_360 # ASV_eval model (plda)





