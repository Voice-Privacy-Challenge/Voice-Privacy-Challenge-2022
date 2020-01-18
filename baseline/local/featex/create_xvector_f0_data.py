import sys
from os.path import join, basename

from ioTools import readwrite
import kaldi_io
import numpy as np

args = sys.argv
data_dir = args[1]
xvector_file = args[2]
out_dir = args[3]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')
xvec_out_dir = join(out_dir, "xvector")
pitch_out_dir = join(out_dir, "f0")

# Write pitch features
pitch_file = join(data_dir, 'pitch.scp')
pitch2shape = {}
for key, mat in kaldi_io.read_mat_scp(pitch_file):
    pitch2shape[key] = mat.shape[0]
    kaldi_f0 = mat[:, 1].squeeze().copy()
    yaapt_f0 = readwrite.read_raw_mat(join(yaap_pitch_dir, key+'.f0'), 1)
    #unvoiced = np.where(yaapt_f0 == 0)[0]
    #kaldi_f0[unvoiced] = 0
    #readwrite.write_raw_mat(kaldi_f0, join(pitch_out_dir, key+'.f0'))
    f0 = np.zeros(kaldi_f0.shape)
    f0[:yaapt_f0.shape[0]] = yaapt_f0
    readwrite.write_raw_mat(f0, join(pitch_out_dir, key+'.f0'))


# Write xvector features
with open(xvector_file) as f:
    for key, mat in kaldi_io.read_vec_flt_scp(f):
        #print key, mat.shape
        plen = pitch2shape[key]
        mat = mat[np.newaxis]
        xvec = np.repeat(mat, plen, axis=0)
        readwrite.write_raw_mat(xvec, join(xvec_out_dir, key+'.xvector'))


