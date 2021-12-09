from kaldiio import WriteHelper, ReadHelper
from ioTools import readwrite

import numpy as np
from os.path import join

import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt

data_dir = 'data/eval1_enroll'
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')

pitch_feats_file = join(data_dir, 'pitch.scp')
pro_pitch_feats_file = join(data_dir, 'processed_pitch.scp')
save_plot_pov = join(data_dir, 'pov.png')
save_plot_nccf = join(data_dir, 'nccf.png')
save_plot_pitch = join(data_dir, 'pitch.png')
save_plot_ypitch = join(data_dir, 'yaapt_pitch.png')

#with open(pitch_feats_file) as f:
with ReadHelper('scp:'+pitch_feats_file) as reader:
    for key, mat in reader:
        print key, mat.shape
        nccf = mat[:, 0]
        pitch = mat[:, 1]
        break

with ReadHelper('scp:'+pro_pitch_feats_file) as reader:
    for key, mat in reader:
        print key, mat.shape
        pov = mat[:, 0]
        yaapt_f0 = readwrite.read_raw_mat(join(yaap_pitch_dir, key+'.f0'), 1)
        print "yaapt pitch: ", yaapt_f0.shape
        #pov = pov / np.sum(pov)
        #pitch = mat[:, 1]
        break

x = np.arange(nccf.shape[0])
x1 = np.arange(yaapt_f0.shape[0])


fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.plot(x, nccf, 'r')
plt.savefig(save_plot_nccf, dpi=300)

plt.clf()

fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.plot(x, pitch, 'b')
plt.savefig(save_plot_pitch, dpi=300)

plt.clf()

fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.plot(x, pov, 'r')
plt.savefig(save_plot_pov, dpi=300)

plt.clf()

fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.plot(x1, yaapt_f0, 'r')
plt.savefig(save_plot_ypitch, dpi=300)
