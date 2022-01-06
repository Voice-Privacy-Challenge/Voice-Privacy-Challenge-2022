#!/usr/bin/python
"""
This script use pyworld DIO to extract F0
https://github.com/JeremyCCHsu/Python-Wrapper-for-World-Vocoder
https://github.com/mmorise/World


Usage:
1. specify configuration in __main__
2. $: python pyworld_get_f0.py input_wav output_f0

Note: 
1. the output will be binary, float32, litten-endian, which
   is compatible to HTS-scripts, CURRENNT-scripts, SPTK

2. you can print it to string using SPTK x2x: 
   $: x2x +fa *.f0 > *.f0.txt

3. you can read it through Numpy
   >> f = open("PATH_TO_F0",'rb')
   >> datatype = np.dtype(("<f4",(col,)))
   >> f0 = np.fromfile(f,dtype=datatype)
   >> f.close()

4. you can also use pyTools by xin wang
   >> from ioTools import readwrite
   >> f0 = readwrite.read_raw_mat("PATH_TO_F0", 1)

"""
import os
import sys
import numpy as np
import scipy.io.wavfile

import pyworld as pw

def waveReadAsFloat(wavFileIn):
    """ sr, wavData = wavReadToFloat(wavFileIn)
    Wrapper over scipy.io.wavfile
    Return: 
        sr: sampling_rate
        wavData: waveform in np.float32 (-1, 1)
    """
    
    sr, wavdata = scipy.io.wavfile.read(wavFileIn)
    
    if wavdata.dtype is np.dtype(np.int16):
        wavdata = np.array(wavdata, dtype=np.float32) / \
                  np.power(2.0, 16-1)
    elif wavdata.dtype is np.dtype(np.int32):
        wavdata = np.array(wavdata, dtype=np.float32) / \
                  np.power(2.0, 32-1)
    elif wavdata.dtype is np.dtype(np.float32):
        pass
    else:
        print("Unknown waveform format %s" % (wavFileIn))
        sys.exit(1)
    return sr, wavdata

def extractF0(input_wav, output_f0, min_f0 = 60, max_f0 = 400, frame_shift = 10):
    if os.path.isfile(input_wav):
        sr, wavdata = waveReadAsFloat(input_wav)
        wavdata = np.asarray(wavdata, dtype=np.double)
        f0_value, _ = pw.dio(wavdata, sr, f0_floor=min_f0, f0_ceil=max_f0,
                             frame_period=frame_shift,
                             allowed_range=0.01)
        datatype = np.dtype('<f4')
        f0_value = np.asarray(f0_value, dtype=datatype)
        f = open(output_f0,'wb')
        f0_value.tofile(f,'')
        f.close()
        print("F0 processed: %s" % (output_f0))
    else:
        print("Cannot find %s" % (input_wav))
    return

if __name__ == "__main__":
    # configuration
    try:
        input_dir = sys.argv[1]
        output_dir = sys.argv[2]
    except IndexError:
        print("Usage: python pyworld_get_f0.py INPUT_WAV_DIR OUTPUT_F0_DIR")
        quit()
    
    # minimum F0 (Hz)
    min_f0 = 60
    # maximum F0 (Hz)    
    max_f0 = 600
    # frame shift (ms)
    frame_shift = 10

    wav_list = os.listdir(input_dir)
    wav_list.sort()
    for wav_name in wav_list:
        if wav_name.endswith(".wav"):
            filename = os.path.splitext(wav_name)[0]
            input_wav = os.path.join(input_dir, wav_name)
            output_f0 = os.path.join(output_dir, filename + '.f0')
            extractF0(input_wav, output_f0, min_f0 = min_f0, max_f0 = max_f0,
                      frame_shift = frame_shift)
