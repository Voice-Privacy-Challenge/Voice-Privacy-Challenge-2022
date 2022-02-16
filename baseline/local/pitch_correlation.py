import os
import parselmouth
import numpy as np
from scipy.interpolate import interp1d
import pandas as pd
import argparse
from kaldiio import ReadHelper


def pitchCorr(wav_orig,wav_anon):

    # get waveforms
    ori = wav_orig.astype(np.float64) / 2**15
    snd_orig = parselmouth.Sound(ori, sampling_frequency=16000.0, start_time=0.0)
    ano = wav_anon.astype(np.float64) / 2 ** 15
    snd_anon = parselmouth.Sound(ano, sampling_frequency=16000.0, start_time=0.0)

    # extract pitches
    pitch_orig = snd_orig.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
    pitch_anon = snd_anon.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
    a = pitch_orig.selected_array['frequency']
    b = pitch_anon.selected_array['frequency']

    # linear interpolation wrt longest pitch signal
    if len(a)>len(b):
        b = interp1d(np.linspace(1, len(b), num=len(b)),b)(np.linspace(1, len(b), num=len(a)))
    elif len(a)<len(b):
        a = interp1d(np.linspace(1, len(a), num=len(a)),a)(np.linspace(1, len(a), num=len(b)))

    # keep pitch values between 75 and 500 Hz after the interpolation process
    a[a < 75] = 0
    a[a > 500] = 0
    b[b < 75] = 0
    b[b > 500] = 0

    # align the original and anonymise pitches
    cab = np.correlate(a, b, 'full')
    lags = np.linspace(-len(a) + 1, len(a) - 1, 2 * len(a) - 1)
    I = np.argmax(cab)
    T = lags[I].astype(int)
    b = np.roll(b, T)

    # correlate the 2 pitches excluding unvoiced parts
    df = pd.DataFrame(np.stack((a, b)).T.squeeze(), columns=list('ab'))
    c = df.corr().fillna(0)
    return c.iloc[1]['a']

def pitchCorr_f(wav_path_orig,wav_path_anon):

    # get waveforms
    snd_orig = parselmouth.Sound(wav_path_orig)
    snd_anon = parselmouth.Sound(wav_path_anon)

    # extract pitches
    pitch_orig = snd_orig.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
    pitch_anon = snd_anon.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
    a = pitch_orig.selected_array['frequency']
    b = pitch_anon.selected_array['frequency']

    # linear interpolation wrt longest pitch signal
    if len(a)>len(b):
        b = interp1d(np.linspace(1, len(b), num=len(b)),b)(np.linspace(1, len(b), num=len(a)))
    elif len(a)<len(b):
        a = interp1d(np.linspace(1, len(a), num=len(a)),a)(np.linspace(1, len(a), num=len(b)))

    # keep pitch values between 75 and 500 Hz after the interpolation process
    a[a < 75] = 0
    a[a > 500] = 0
    b[b < 75] = 0
    b[b > 500] = 0

    # align the original and anonymized pitches
    cab = np.correlate(a, b, 'full')
    lags = np.linspace(-len(a) + 1, len(a) - 1, 2 * len(a) - 1)
    I = np.argmax(cab)
    T = lags[I].astype(int)
    b = np.roll(b, T)

    # get correlation coefficients between the 2 pitches excluding unvoiced parts
    df = pd.DataFrame(np.stack((a, b)).T.squeeze(), columns=list('ab'))
    c = df.corr().fillna(0)

    return c.iloc[1]['a']

def pitchCorr_list(data, wav_list_orig, wav_list_anon, max_len_diff, result_file):
    assert os.path.isfile(wav_list_orig), f'file {wav_list_orig} does not exist'
    assert os.path.isfile(wav_list_anon), f'file {wav_list_anon} does not exist'
    print("wav_list_orig = ", wav_list_orig)
    print("wav_list_anon = ", wav_list_anon)
    corr_list = list()
    with ReadHelper(f'scp:{wav_list_orig}') as reader_orig:
        with ReadHelper(f'scp:{wav_list_anon}') as reader_anon:
            iter_anon = iter(reader_anon)
            for utid_orig, (freq_orig, samp_orig) in reader_orig:
                #print(utid_orig, freq_orig, type(samp_orig[0]))
                utid_anon, (freq_anon, samp_anon) = next(iter_anon, (None, (None, None)))
                assert utid_anon is not None, f'Mismatch between lists of original and anonymized files: {wav_list_orig} and {wav_list_anon}'
                assert utid_anon == utid_orig, f'Different order of utterances in the lists of original and anonymized files: {wav_list_orig} and {wav_list_anon}'
                assert freq_anon == freq_orig, f'Different sampling frequency of original and anonymized files: {wav_list_orig} and {wav_list_anon}'
                assert freq_anon == 16000, f'Wrong sampling frequency (should be 16000): {wav_list_orig} and {wav_list_anon}'
                diff = abs(len(samp_anon) - len(samp_orig)) / freq_orig * 1000 # in ms 
                assert diff < max_len_diff, f'Difference between lenghts of original and anonymized utterances is too long (exceeds threshold max_len_diff={max_len_diff} ms): {utid_orig}  and {utid_anon}, difference = {diff} ms'                
                #assert diff < 0.070, f'Difference between lenghts of original and anonymized utterances exceeds is too long (exceeds 70ms): {utid_orig}  and {utid_anon}, difference = {diff} ms'                
                #assert len(samp_anon) == len(samp_orig), f'Different lenghts of original and anonymized utterances: {utid_orig} ({len(samp_orig)}) and {utid_anon} ({len(samp_anon)})'
                corr = pitchCorr(samp_orig, samp_anon)
                corr_list.append(corr)
    mean = np.mean(corr_list)
    std = np.std(corr_list)
    file = open(result_file, 'a+')
    str_out = str(data) + "  Pitch_correlation: mean=" + str("{:.4f}".format(mean)) + " std="  + str("{:.4f}".format(std) + "\n")
    print(str_out)
    file.write(str_out)
    file.close()

if __name__ == "__main__":
    #Parse args    
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str, default='libri_test_trials_f')
    parser.add_argument('--list_name', type=str, default=' ')
    parser.add_argument('--list_name_anon', type=str, default=' ')
    parser.add_argument('--max_len_diff', type=int, default=0)
    parser.add_argument('--results', type=str, default=' ')
    config = parser.parse_args()
    pitchCorr_list(config.data, config.list_name, config.list_name_anon, config.max_len_diff, config.results)
    print('Done')