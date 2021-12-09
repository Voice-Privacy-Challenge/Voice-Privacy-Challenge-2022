. path.sh
. config.sh
proj_dir=ssl_scripts/
test_data_dir=$1

test_wav_dir=$PWD

export TEMP_TESTSET_NAME=`basename ${test_data_dir}`
export TEMP_TESTSET_LST=${test_data_dir}/scp/data.lst
export TEMP_TESTSET_XVEC=${test_data_dir}/xvector
export TEMP_TESTSET_F0=${test_data_dir}/f0

output_dir=$PWD/$2/${TEMP_TESTSET_NAME}
export TEMP_MODEL_DIRECTORY=$PWD/exp/models/ssl_models

if [ "${ssl_model}" == "hubert_soft" ];then
   model_name=vc_hubert_km_soft
   feat_model_path=${TEMP_MODEL_DIRECTORY}/hubert_base_ls960.pt
   soft_model_path=${TEMP_MODEL_DIRECTORY}/soft_model.pt
   hifigan_model_dir=${TEMP_MODEL_DIRECTORY}/${model_name}
elif [ "${ssl_model}" == "hubert_km" ];then
   model_name=vc_hubert_km_200
   feat_model_path=${TEMP_MODEL_DIRECTORY}/hubert_base_ls960.pt
   kmeans_model_path=${TEMP_MODEL_DIRECTORY}/km_hubert_200.bin
   hifigan_model_dir=${TEMP_MODEL_DIRECTORY}/${model_name}
else
   exit 1
fi
cd ${proj_dir}

python inference_vc.py --input_test_file ${TEMP_TESTSET_LST} --test_wav_dir $test_wav_dir --feat_model $feat_model_path \
	--soft_model $soft_model_path --kmeans_model $kmeans_model_path \
	--checkpoint_file $hifigan_model_dir --f0_dir ${TEMP_TESTSET_F0} \
	--xv_dir ${TEMP_TESTSET_XVEC} --output_dir $output_dir
cd -

