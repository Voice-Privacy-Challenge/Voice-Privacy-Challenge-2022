#!/usr/bin/python
"""
This scripts use one of the tool to extract pitch

pyworld DIO to extract F0
https://github.com/JeremyCCHsu/Python-Wrapper-for-World-Vocoder
https://github.com/mmorise/World

pYAAPT to extract F0, which is robust to low-quality waveform
http://bingweb.binghamton.edu/~hhu1/pitch/YAPT.pdf
http://bjbschmitt.github.io/AMFM_decompy/pYAAPT.html

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

try:
    import pyworld as pw
    global_pyworld_flag=True
except ModuleNotFoundError:
    global_pyworld_flag=False
    pass
global_pyworld_tag = 'pyworld'


try:
    import amfm_decompy.pYAAPT as pYAAPT
    import amfm_decompy.basic_tools as basic
    global_yaapt_flag=True
except ModuleNotFoundError:
    global_yaapt_flag=False
    pass
global_yaapt_tag = 'yaapt'


try:
    import soundfile
except ModuleNotFoundError:
    pass


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

def read_audio(input_wav_path):
    if input_wav_path.endswith(".wav"):
        sr, wavdata = waveReadAsFloat(input_wav_path)
    elif input_wav_path.endswith(".flac"):
        try:
            wavdata, sr = soundfile.read(input_wav_path)
        except NameError:
            print("please install soundfile to load flac")
            sys.exit(1)
    else:
        print("external_get_f0 only supports wav and flac")
        sys.exit(1)
    return sr, wavdata

def save_f0(f0_value, output_path):
    datatype = np.dtype('<f4')
    f0_value = np.asarray(f0_value, dtype=datatype)
    f = open(output_path,'wb')
    f0_value.tofile(f,'')
    f.close()
    return

def extractF0(input_wav, output_f0, extractor_flag, min_f0 = 60, max_f0 = 400, 
              frame_length = 35, frame_shift = 10):
    if os.path.isfile(input_wav):

        if extractor_flag == global_pyworld_tag:
            if global_pyworld_flag:
                sr, wavdata = read_audio(input_wav)
                wavdata = np.asarray(wavdata, dtype=np.double)
                f0_value, _ = pw.dio(wavdata, sr, 
                                     f0_floor=min_f0, f0_ceil=max_f0,
                                     frame_period=frame_shift,
                                     allowed_range=0.01)
            else:
                print("please install pyworld to extract F0")
                sys.exit(1)
        elif extractor_flag == global_yaapt_tag:
            if global_yaapt_flag:
                signal = basic.SignalObj(input_wav)
                pitch = pYAAPT.yaapt(signal, 
                                     **{'f0_min': min_f0, 'f0_max': max_f0,
                                        'frame_length':frame_length,
                                        'frame_space':frame_shift})
                f0_value = pitch.samp_values
            else:
                print("please install yaapt to extract F0")
                sys.exit(1)

        save_f0(f0_value, output_f0)
        print("F0 processed using {:s}: {:s}".format(extractor_flag, output_f0))
    else:
        print("Cannot find %s" % (input_wav))
    return

if __name__ == "__main__":
    # configuration
    try:
        input_data_list = sys.argv[1]
        output_dir = sys.argv[2]
        extractor_flag = sys.argv[3]
    except IndexError:
        print("Usage: python external_get_f0.py INPUT_WAV_DIR OUTPUT_F0_DIR F0_EXTRACTOR")
        quit()
    
    # minimum F0 (Hz)
    min_f0 = 60
    # maximum F0 (Hz)    
    max_f0 = 600
    # frame length (ms)
    frame_length = 35
    # frame shift (ms)
    frame_shift = 10

    with open(input_data_list, 'r') as file_ptr:
        for line in file_ptr:
            #100-121669-0000 flac -c -d -s path/100-121669-0000.flac | 
            line = line.rstrip()
            entry = line.split()
            filename = entry[0]
            # search for the path in the input 
            for tmp in entry:
                if tmp.endswith(".wav") or tmp.endswith(".flac"):
                    input_wav_path = tmp
                    break
            if not os.path.isfile(input_wav_path):
                print("Cannot find {:s}".format(input_wav_path))
                sys.exit(1)
            else:
                output_f0_path = os.path.join(output_dir, filename + '.f0')
                extractF0(input_wav_path, output_f0_path, extractor_flag,
                          min_f0 = min_f0, max_f0 = max_f0, 
                          frame_length = frame_length,
                          frame_shift = frame_shift)
