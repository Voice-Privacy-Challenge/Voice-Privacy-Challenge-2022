import kaldi_io

import numpy as np

import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt


pitch_feats_file = 'data/am_nsf/train_clean_460_dev/pitch.scp'
save_plot = 'data/am_nsf/train_clean_460_dev/pitch.png'

#with open(pitch_feats_file) as f:
for key, mat in kaldi_io.read_mat_scp(pitch_feats_file):
    print key, mat.shape
    pov = mat[:, 0]
    pitch = mat[:, 1]
    break

fig = plt.figure()
ax1 = fig.add_subplot(111)

x = np.arange(pov.shape[0])

ax1.plot(x, pov, 'r')
ax1.plot(x, pitch, 'g')

plt.savefig(save_plot, dpi=300)
