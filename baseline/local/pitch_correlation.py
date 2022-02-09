import parselmouth
import numpy as np
from scipy.interpolate import interp1d
import pandas as pd

def pitchCorr(wav_path_original,wav_path_anon):

    # get waveforms
    snd_original = parselmouth.Sound(wav_path_original)
    snd_anon = parselmouth.Sound(wav_path_anon)

    # extract pitches
    pitch_original = snd_original.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
    pitch_anon = snd_anon.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=500)
    a = pitch_original.selected_array['frequency']
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

    # get correlation coefficients between the 2 pitches excluding unvoiced parts
    df = pd.DataFrame(np.stack((a, b)).T.squeeze(), columns=list('ab'))
    c = df.corr().fillna(0)

    return c.iloc[1]['a']


