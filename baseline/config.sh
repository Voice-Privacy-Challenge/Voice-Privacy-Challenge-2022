# Config for the 2022 VoicePrivacy Challenge

##########################################################
# Common settings

nj=$(nproc)

#tts_type=am_nsf_old          #TTS: SS AM + NSF model (c++)m baseline-1 from VPC-2020
tts_type=am_nsf_pytorch     #TTS: SS AM + NSF model (pytorch)
#tts_type=joint_hifigan      #TTS: Single joint TTS model based on HiFi GAN
#tts_type=joint_nsf_hifigan  #TTS: Single joint TTS model bsaed on NSF with GAN

#tts_type=ssl        #TTS: Self-supervised learning features: wav2vec2 (...); hubert; hubert_kmeans

xvect_type=kaldi     
#xvect_type=sidekit

baseline_type=baseline-1  # x-vect + tts
#baseline_type=baseline-2 # mcadams 

#name of this experiment
exp_name_suffix=trial1-2021-12-08


##########################################################
# Evaluation data sets
eval_sets='libri vctk'
eval_subsets='dev test'

##########################################################
# Download settings

download_full=true  # If download_full=true all the data that can be used in the training/development will be dowloaded (except for Voxceleb-1,2 corpus); otherwise - only those subsets that are used in the current baseline (with the pretrained models)
data_url_librispeech=www.openslr.org/resources/12  # Link to download LibriSpeech corpus
data_url_libritts=www.openslr.org/resources/60     # Link to download LibriTTS corpus
corpora=corpora
libri_train_clean_100=train-clean-100
libri_train_other_500=train-other-500
libri_train_sets="$libri_train_clean_100 $libri_train_other_500"
libritts_train_clean_100=train-clean-100
libritts_train_other_500=train-other-500
libritts_train_sets="$libritts_train_clean_100 $libritts_train_other_500"


##########################################################
# Directory to save prepared data for anonymization pool: data/${anoni_pool} 
anoni_pool=libritts_train_other_500

##########################################################
# Extract x-vectors for anonymization pool

if [ $baseline_type != 'baseline-2' ]; then
  xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a # x-vector extractor
  anon_xvec_out_dir=${xvec_nnet_dir}/anon # x-vector extraction output dir
fi


##########################################################
# Anonymization

rand_seed_start=0
anon_level_trials=spk                # spk (speaker-level anonymization) or utt (utterance-level anonymization)
anon_level_enroll=spk                # spk (speaker-level anonymization) or utt (utterance-level anonymization)
anon_data_suffix=_anon

if [ $baseline_type = 'baseline-2' ]; then
	#McAdams anonymisation config
	n_lpc=20
	mc_coeff_enroll=0.8                  # mc_coeff for enrollment 
	mc_coeff_trials=0.8                  # mc_coeff for trials
elif [ $baseline_type = 'baseline-1' ]; then
	ppg_model=exp/models/1_asr_am/exp    # ASR model for BN extraction
	cross_gender=false                   # false (same gender xvectors will be selected) or true (other gender xvectors)
	distance=plda                        # cosine or plda
	proximity=farthest                   # nearest or farthest speaker to be selected for anonymization
	anonym_data=exp/am_nsf_data          # directory where features for voice anonymization will be stored 
fi


##########################################################
# Evaluation settings (common)

results=exp/results-${exp_name_suffix}

##########################################################
# ASR evaluation settings

asr_eval_model=exp/models/asr_eval # Model for ASR evaluation

##########################################################
# ASV evaluation settings

asv_eval_model=exp/models/asv_eval/xvect_01709_1 # Model for ASV evaluation

##########################################################
# Settings for training of evaluation (original or anonymized) models 

train_data=train-clean-360                      # training dataset for evaluation models
asr_eval_model_train=exp/models/asr_eval_anon   # directory to save the ASR evaluation model 
data_proc=orig                                  # anonymized (anon) or original(orig)  
