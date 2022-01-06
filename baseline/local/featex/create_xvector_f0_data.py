import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np

args = sys.argv
data_dir = args[1]
xvector_file = args[2]
out_dir = args[3]
xvector_dup_flag = bool(int(args[4]))

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')
xvec_out_dir = join(out_dir, "xvector")
pitch_out_dir = join(out_dir, "f0")

# Write pitch features
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
        length = min([kaldi_f0.shape[0], yaapt_f0.shape[0]])
        f0[:length] = yaapt_f0[:length]
        readwrite.write_raw_mat(f0, join(pitch_out_dir, key+'.f0'))


# Write xvector features
with ReadHelper('scp:'+xvector_file) as reader:
    for key, mat in reader:
        #print key, mat.shape
        plen = pitch2shape[key]
        mat = mat[np.newaxis]
        xvec = np.repeat(mat, plen, axis=0)

        if xvector_dup_flag:
            readwrite.write_raw_mat(xvec, join(xvec_out_dir, key+'.xvector'))
        else:
            # only 1 frame is OK for new Pytorch-based models
            readwrite.write_raw_mat(xvec[0], join(xvec_out_dir, key+'.xvector'))


