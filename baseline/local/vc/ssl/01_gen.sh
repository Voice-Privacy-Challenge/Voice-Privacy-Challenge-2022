. path.sh
. config.sh
proj_dir=ssl_scripts/
test_data_dir=$1

test_wav_dir=$PWD

export TEMP_TESTSET_NAME=`basename ${test_data_dir}`
export TEMP_TESTSET_LST=${test_data_dir}/scp/data_ssl.lst
export TEMP_TESTSET_XVEC=${test_data_dir}/xvector
export TEMP_TESTSET_F0=${test_data_dir}/f0

output_dir=$PWD/$2/${TEMP_TESTSET_NAME}
export TEMP_MODEL_DIRECTORY=$PWD/exp/models/ssl_models

time_start=`date +%s`
#echo "$time_start"

if [ "$xvect_type" == "kaldi" ]; then
   hifigan_model_dir=$TEMP_MODEL_DIRECTORY/vc_w2v2_768_context_ft_100h_kaldi_xv/
fi

if [ "$xvect_type" == "sidekit" ]; then
   hifigan_model_dir=$TEMP_MODEL_DIRECTORY/vc_w2v2_768_context_ft_100h_sidekit/
fi

cd ${proj_dir}

python inference_vc.py --input_test_file ${TEMP_TESTSET_LST} --test_wav_dir $test_wav_dir \
	--checkpoint_file $hifigan_model_dir --f0_dir ${TEMP_TESTSET_F0} \
	--xv_dir ${TEMP_TESTSET_XVEC} --output_dir $output_dir

time_end=`date +%s`
#echo "$time_end"
echo $test_data_dir "generation time:" $((time_end-$time_start))


cd -

