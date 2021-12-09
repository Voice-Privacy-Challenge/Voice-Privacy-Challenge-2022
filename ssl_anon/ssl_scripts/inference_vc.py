# adapted from https://github.com/facebookresearch/speech-resynthesis

import argparse
import glob
import json
import os
import random
import sys
import time
from pathlib import Path

from multiprocessing import Manager, Pool
import librosa
import numpy as np
import torch
from scipy.io.wavfile import write

from dataset_test import latentDataset, mel_spectrogram, \
    MAX_WAV_VALUE
from utils import AttrDict
from models_test import latentGenerator,SoftPredictor
import joblib
import fairseq

h = None

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print('DEVICE: ' + str(device))


def stream(message):
    sys.stdout.write(f"\r{message}")


def progbar(i, n, size=16):
    done = (i * size) // n
    bar = ''
    for i in range(size):
        bar += '█' if i <= done else '░'
    return bar


def load_checkpoint(filepath):
    assert os.path.isfile(filepath)
    print("Loading '{}'".format(filepath))
    checkpoint_dict = torch.load(filepath, map_location='cpu')
    print("Complete.")
    return checkpoint_dict


def get_mel(x):
    return mel_spectrogram(x, h.n_fft, h.num_mels, h.sampling_rate, h.hop_size, h.win_size, h.fmin, h.fmax)


def scan_checkpoint(cp_dir, prefix):
    pattern = os.path.join(cp_dir, prefix + '*')
    cp_list = glob.glob(pattern)
    if len(cp_list) == 0:
        return ''
    return sorted(cp_list)[-1]


def generate(h, generator, code):
    start = time.time()
    y_g_hat = generator(**code).to(device)
    if type(y_g_hat) is tuple:
        y_g_hat = y_g_hat[0]
    rtf = (time.time() - start) / (y_g_hat.shape[-1] / h.sampling_rate)
    audio = y_g_hat.squeeze()
    audio = audio * MAX_WAV_VALUE
    audio = audio.cpu().numpy().astype('int16')
    return audio, rtf


def init_worker(arguments):
    import logging
    logging.getLogger().handlers = []

    global generator
    global dataset
    global device
    global a
    global h

    global feat_model
    global kmeans_model
    global soft_model
    a = arguments

    if os.path.isdir(a.checkpoint_file):
        config_file = os.path.join(a.checkpoint_file, 'config.json')
    else:
        config_file = os.path.join(os.path.split(a.checkpoint_file)[0], 'config.json')
    with open(config_file) as f:
        data = f.read()
    json_config = json.loads(data)
    h = AttrDict(json_config)

    generator = latentGenerator(h).to(device)
    if os.path.isdir(a.checkpoint_file):
        cp_g = scan_checkpoint(a.checkpoint_file, 'g_')
    else:
        cp_g = a.checkpoint_file
    state_dict_g = load_checkpoint(cp_g)
    generator.load_state_dict(state_dict_g['generator'])

    if a.feat_model and a.kmeans_model:
        feat_model, cfg, task = fairseq.checkpoint_utils.load_model_ensemble_and_task([str(a.feat_model)])
        feat_model = feat_model[0].to(device)
        feat_model.eval()
        kmeans_model = joblib.load(open(a.kmeans_model, "rb"))
        kmeans_model.verbose = False
        soft_model = None
    elif a.feat_model and a.soft_model:
        feat_model, cfg, task = fairseq.checkpoint_utils.load_model_ensemble_and_task([str(a.feat_model)])
        feat_model = feat_model[0]
        feat_model.remove_pretraining_modules()
        soft_model = SoftPredictor(feat_model).to(device)
        soft_model.eval()
        soft_model.load_state_dict(torch.load(str(a.soft_model)))
        kmeans_model = None
    else:
        feat_model, cfg, task = fairseq.checkpoint_utils.load_model_ensemble_and_task([str(a.feat_model)])
        feat_model = feat_model[0].to(device)
        feat_model.eval()
        kmeans_model = None
        soft_model = None

    file_list = []
    for line in open(a.input_test_file):
        temp = line.strip().split(" ")[-1]
        file_list.append(temp)
    
    dataset = latentDataset(file_list, -1, h.latent_hop_size, h.n_fft, h.num_mels, h.hop_size, h.win_size,
                              h.sampling_rate, h.fmin, h.fmax, n_cache_reuse=0,
                              fmax_loss=h.fmax_for_loss,  device=device,test_wav_dir=a.test_wav_dir,
                              km=h.get('km', None), hubert=h.get('hubert', None), context=h.get('context', None),
                              quantized=h.get('quantized', None),f0=h.get('f0', None), xv=h.get('xv', None),
                              xv_dim=h.get('xv_dim',512),soft=h.get('soft', None),
                              f0_dir=a.f0_dir, xv_dir=a.xv_dir,feat_model=feat_model, soft_model=soft_model,kmeans_model=kmeans_model)

    os.makedirs(a.output_dir, exist_ok=True)


    generator.eval()
    generator.remove_weight_norm()

    # fix seed
    seed = 52
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


@torch.no_grad()
def inference(item_index):
    code, gt_audio, filename, _ = dataset[item_index]
    if type(code['cont']) is np.ndarray:
        code['cont'] = torch.from_numpy(code['cont']).unsqueeze(0) 
    else:
        code['cont'] = code['cont'].unsqueeze(0) 
    code['f0'] = code['f0'].unsqueeze(0) 
    code['xv'] = code['xv'].unsqueeze(0) 


    fname_out_name = Path(filename).stem

    new_code = dict(code)

    audio, rtf = generate(h, generator, new_code)
    output_file = os.path.join(a.output_dir, fname_out_name + '.wav')
    audio = librosa.util.normalize(audio.astype(np.float32))
    write(output_file, h.sampling_rate, audio)
    #generate ground true 
    #if gt_audio is not None:
    #    output_file = os.path.join(a.output_dir, fname_out_name + '_gt.wav')
    #    gt_audio = librosa.util.normalize(gt_audio.squeeze().cpu().numpy().astype(np.float32))
    #    write(output_file, h.sampling_rate, gt_audio)


def main():
    print('Initializing Inference Process..')

    parser = argparse.ArgumentParser()
    parser.add_argument('--input_test_file', default=None)
    parser.add_argument('--test_wav_dir', default=None)
    parser.add_argument('--feat_model', type=Path)
    parser.add_argument('--kmeans_model', type=Path,nargs="?",default=None)
    parser.add_argument('--soft_model', type=Path,nargs="?",default=None)
    parser.add_argument('--output_dir', default='generated_files')
    parser.add_argument('--checkpoint_file', required=True)
    parser.add_argument('--f0_dir', type=Path)
    parser.add_argument('--xv_dir', type=Path)

    a = parser.parse_args()
    print(a)
    seed = 52
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


    if os.path.isdir(a.checkpoint_file):
        config_file = os.path.join(a.checkpoint_file, 'config.json')
    else:
        config_file = os.path.join(os.path.split(a.checkpoint_file)[0], 'config.json')
    with open(config_file) as f:
        data = f.read()
    json_config = json.loads(data)
    h = AttrDict(json_config)

    if os.path.isdir(a.checkpoint_file):
        cp_g = scan_checkpoint(a.checkpoint_file, 'g_')
    else:
        cp_g = a.checkpoint_file
    if not os.path.isfile(cp_g) or not os.path.exists(cp_g):
        print(f"Didn't find checkpoints for {cp_g}")
        return

    file_list = []
    for line in open(a.input_test_file):
        file_list.append(line.strip())


    
    init_worker(a)

    for i in range(0, len(dataset)):
        inference(i)
        bar = progbar(i, len(dataset))
        message = f'{bar} {i}/{len(dataset)} '
        stream(message)

if __name__ == '__main__':
    main()
