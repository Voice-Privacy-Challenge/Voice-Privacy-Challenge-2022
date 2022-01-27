import sys,os
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np

args = sys.argv

data_dir = args[1]
xvector_file = args[2]
out_dir = args[3]
tts_type = 'not ssl'
if len(args) == 5:
    tts_type = args[4]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')
xvec_out_dir = join(out_dir, "xvector")
pitch_out_dir = join(out_dir, "f0")
xvector_repeat_flag = 0

# Write pitch features 
# if f0 has been downloaed, skip write 
if os.listdir(pitch_out_dir):
    print('%s F0 has been download, skip write'%dataname)
else:
    pitch_file = join(data_dir, 'pitch.scp')
    pitch2shape = {}
    with ReadHelper('scp:'+pitch_file) as reader:
        for key, mat in reader:
            pitch2shape[key] = mat.shape[0]
            kaldi_f0 = mat[:, 1].squeeze().copy()
            yaapt_f0 = readwrite.read_raw_mat(join(yaap_pitch_dir, key+'.f0'), 1)
            #unvoiced = np.where(yaapt_f0 == 0)[0]
            #kaldi_f0[unvoiced] = 0
            #readwrite.write_raw_mat(kaldi_f0, join(pitch_out_dir, key+'.f0'))
            f0 = np.zeros(kaldi_f0.shape)
            f0[:yaapt_f0.shape[0]] = yaapt_f0
            readwrite.write_raw_mat(f0, join(pitch_out_dir, key+'.f0'))

if tts_type == 'ssl':
    xvector_repeat_flag=1

# Write xvector features
with ReadHelper('scp:'+xvector_file) as reader:
    for key, mat in reader:
        #print key, mat.shape
        if xvector_repeat_flag:
            xvec = mat
        else:
            plen = pitch2shape[key]
            plen = mat.shape[0]
            mat = mat[np.newaxis]
            xvec = np.repeat(mat, plen, axis=0)
        readwrite.write_raw_mat(xvec, join(xvec_out_dir, key+'.xvector'))


