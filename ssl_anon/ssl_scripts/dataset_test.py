# adapted from https://github.com/facebookresearch/speech-resynthesis

import random
from pathlib import Path
import readwrite
import numpy as np
import torch
import torch.utils.data
import torch.utils.data
from librosa.filters import mel as librosa_mel_fn
from librosa.util import normalize
from scipy.io.wavfile import read
import math
import fairseq


MAX_WAV_VALUE = 32768.0




def mel_spectrogram(y, n_fft, num_mels, sampling_rate, hop_size, win_size, fmin, fmax, center=False):
    if torch.min(y) < -1.:
        print('min value is ', torch.min(y))
    if torch.max(y) > 1.:
        print('max value is ', torch.max(y))

    global mel_basis, hann_window
    if fmax not in mel_basis:
        mel = librosa_mel_fn(sampling_rate, n_fft, num_mels, fmin, fmax)
        mel_basis[str(fmax)+'_'+str(y.device)] = torch.from_numpy(mel).float().to(y.device)
        hann_window[str(y.device)] = torch.hann_window(win_size).to(y.device)

    y = torch.nn.functional.pad(y.unsqueeze(1), (int((n_fft-hop_size)/2), int((n_fft-hop_size)/2)), mode='reflect')
    y = y.squeeze(1)

    spec = torch.stft(y, n_fft, hop_length=hop_size, win_length=win_size, window=hann_window[str(y.device)],
                      center=center, pad_mode='reflect', normalized=False, onesided=True, return_complex=False)

    spec = torch.sqrt(spec.pow(2).sum(-1)+(1e-9))

    spec = torch.matmul(mel_basis[str(fmax)+'_'+str(y.device)], spec)
    spec = spectral_normalize_torch(spec)

    return spec


def load_wav(full_path):
    sampling_rate, data = read(full_path)
    return data, sampling_rate


def dynamic_range_compression(x, C=1, clip_val=1e-5):
    return np.log(np.clip(x, a_min=clip_val, a_max=None) * C)


def dynamic_range_decompression(x, C=1):
    return np.exp(x) / C


def dynamic_range_compression_torch(x, C=1, clip_val=1e-5):
    return torch.log(torch.clamp(x, min=clip_val) * C)


def dynamic_range_decompression_torch(x, C=1):
    return torch.exp(x) / C


def spectral_normalize_torch(magnitudes):
    output = dynamic_range_compression_torch(magnitudes)
    return output


def spectral_de_normalize_torch(magnitudes):
    output = dynamic_range_decompression_torch(magnitudes)
    return output


mel_basis = {}
hann_window = {}




def get_dataset_filelist_vc(h):
    #training_files, training_codes = parse_manifest(h.input_training_file)
    #validation_files, validation_codes = parse_manifest(h.input_validation_file)
    training_files = []
    validation_files = []
    for line in open(h.input_training_file):
        training_files.append(line.strip())

    for line in open(h.input_validation_file):
        validation_files.append(line.strip())
    return training_files, validation_files



class latentDataset(torch.utils.data.Dataset):
    def __init__(self, training_files, segment_size, latent_hop_size, n_fft, num_mels,
                 hop_size, win_size, sampling_rate, fmin, fmax, split=True, n_cache_reuse=1,
                 device=None,fmax_loss=None, km=None,soft=None,test_wav_dir=None,latent_dir=None,
                 f0=True, f0_dir=None, f0_dim=1, xv=True, xv_dir=None, xv_dim=512, pad=None,
                hubert=None,context=None,quantized=None,feat_model=None, kmeans_model=None, soft_model=None):
        self.audio_files = training_files
        random.seed(1234)
        self.segment_size = segment_size
        self.latent_hop_size = latent_hop_size
        self.sampling_rate = sampling_rate
        self.split = split
        self.n_fft = n_fft
        self.num_mels = num_mels
        self.hop_size = hop_size
        self.win_size = win_size
        self.fmin = fmin
        self.fmax = fmax
        self.fmax_loss = fmax_loss
        self.cached_wav = None
        self.n_cache_reuse = n_cache_reuse
        self._cache_ref_count = 0
        self.device = device
        self.km = km
        self.soft = soft
        self.test_wav_dir =test_wav_dir
        self.f0 = f0
        self.f0_hop_size = 160
        self.f0_dir = f0_dir
        self.f0_dim = f0_dim
        self.xv = xv
        self.xv_dir = xv_dir
        self.xv_dim = xv_dim
        self.pad = pad

        self.hubert = hubert
        self.context = context
        self.quantized = quantized

        if self.km:
            self.kmeans_model = kmeans_model
        if self.soft:
            self.soft_model = soft_model.to(self.device)
        self.feat_model = feat_model.to(self.device)

    def _sample_interval_latent(self, seqs, seq_len=None):
        N = max([v.shape[-1] for v in seqs])
        if seq_len is None:
            seq_len = self.segment_size if self.segment_size > 0 else N

        hops = [N // v.shape[-1] for v in seqs]
        lcm = np.lcm.reduce(hops)

        # Randomly pickup with the batch_max_steps length of the part
        interval_start = 0
        interval_end = N // lcm - seq_len // lcm

        start_step = random.randint(interval_start, interval_end)
        new_seqs = []
        for i, v in enumerate(seqs):
            start = start_step * (lcm // hops[i])
            end = (start_step + seq_len // lcm) * (lcm // hops[i])
            new_seqs += [v[..., start:end]]

        return new_seqs

    def __getitem__(self, index):
        temp_path = self.audio_files[index]
        full_path = self.test_wav_dir + '/' + temp_path
        filename = full_path.split('/')[-1].split('.')[0]
        if self._cache_ref_count == 0:
            audio, sampling_rate = load_wav(full_path)
            if sampling_rate != self.sampling_rate:
                import resampy
                audio = resampy.resample(audio, sampling_rate, self.sampling_rate)

            if self.pad:
                padding = self.pad - (audio.shape[-1] % self.pad)
                audio = np.pad(audio, (0, padding), "constant", constant_values=0)
            audio = audio / MAX_WAV_VALUE
            audio = normalize(audio) * 0.95
            self.cached_wav = audio
            self._cache_ref_count = self.n_cache_reuse
        else:
            audio = self.cached_wav
            self._cache_ref_count -= 1

        audio_temp = torch.from_numpy(audio).unsqueeze(0).to(torch.float32).to(self.device)
        if self.hubert:
            latent = self.feat_model.extract_features(source=audio_temp, mask=False, output_layer=6)[0]
            latent = latent[0]
        elif self.km:
            temp = self.feat_model.extract_features(source=audio_temp, mask=False, output_layer=6)[0]
            latent = self.kmeans_model.predict(temp[0].cpu().numpy())
            latent = torch.from_numpy(latent)
            latent = latent.type(torch.LongTensor).to(self.device)
        elif self.context:
            latent = self.feat_model(audio_temp, mask=False, features_only=True)['x'][0]  ## context output
        elif self.quantized:
            latent = self.feat_model(audio_temp, mask=False, features_only=False)['x'][0]  ## quantized output
        elif self.soft:
            latent = self.soft_model(audio_temp).squeeze(0)
        else:
            raise Exception("latent feature or model configure error")

        latent_length = min(audio.shape[0] // self.latent_hop_size, latent.shape[0])
        latent = latent[:latent_length]
        

        audio = audio[:latent_length * self.latent_hop_size]
        assert audio.shape[0] // self.latent_hop_size == latent.shape[0], "latent audio mismatch"

        #read f0
        f0 = readwrite.read_raw_mat(str(self.f0_dir) + '/' + filename + '.f0', self.f0_dim)
        f0_length = min(audio.shape[0] // self.f0_hop_size, f0.shape[0])
        if f0.shape[0] < audio.shape[0] // self.f0_hop_size:
            f0 = np.pad(f0, (0, audio.shape[0] // self.f0_hop_size - f0.shape[0]), 'constant')
        if f0.shape[0] > audio.shape[0] // self.f0_hop_size:
            f0 = f0[:f0_length]


        audio = torch.FloatTensor(audio).to(self.device)
        audio = audio.unsqueeze(0)

        assert audio.size(1) >= self.segment_size, "Padding not supported!!"
        #f0 = np.asarray(f0)
        f0 = torch.FloatTensor(f0).to(self.device)
        #print("check",f0.shape)
        if self.km:
            audio, latent,f0 = self._sample_interval_latent([audio, latent,f0])
        else:
            audio, latent,f0 = self._sample_interval_latent([audio, latent.transpose(1, 0),f0])
        #print("dataset line266", audio.shape)
        mel_loss = mel_spectrogram(audio, self.n_fft, self.num_mels,
                                   self.sampling_rate, self.hop_size, self.win_size, self.fmin, self.fmax_loss,
                                   center=False)
        if self.km:
            feats = {"cont": latent}
        else:
            feats = {"cont": latent.transpose(1, 0)}


        feats['f0'] = f0.unsqueeze(0)

        if self.xv:
            xv = readwrite.read_raw_mat(str(self.xv_dir) + '/' + filename + '.xvector', self.xv_dim)
            #trim is needed if xvector saved as [frames,512], e.g.baseline1, no need to use if xvector saved as [1,512]
            if xv.shape[0] < feats['f0'].shape[1]:
                xv = np.vstack([xv, xv[(feats['f0'].shape[1]-xv.shape[0])]])
            if xv.shape[0] > feats['f0'].shape[1]:
                xv = xv [:feats['f0'].shape[1]]
            feats['xv'] = torch.FloatTensor(xv).to(self.device)


        return feats, audio.squeeze(0), str(filename), mel_loss.squeeze()

    def __len__(self):
        return len(self.audio_files)




