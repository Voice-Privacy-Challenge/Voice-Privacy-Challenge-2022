'''
This is a general TSNE plotting script
It needs spk2gender and spk_xvector.scp
'''

import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.lines as mlines

from os.path import join

import numpy as np
from sklearn.manifold import TSNE

import kaldi_io

data = 'train'
spk_xvector_dir = f'exp/0007_voxceleb_v2_1a/exp/xvector_nnet_1a/am_nsf/xvectors_train_clean_360_{data}'
spk_xvector_file = join(spk_xvector_dir, 'spk_xvector.scp')
tsne_file = join(spk_xvector_dir, 'spk_xvector.png')

spk2gender_file = f'data/am_nsf/train_clean_360_{data}/spk2gender'

def get_cmap(n, name='hsv'):
    return plt.cm.get_cmap(name, n)

# get gender info
spk2gender = {}
with open(spk2gender_file) as f:
    for line in f.read().splitlines():
        sp = line.split()
        spkid = sp[0]
        gen = sp[1]
        spk2gender[spkid] = gen

X = []
spks = []
for key, mat in kaldi_io.read_vec_flt_scp(spk_xvector_file):
    #print(key, mat.shape)
    spks.append(key)
    X.append(mat[np.newaxis])

X = np.concatenate(X)
print("X = ", X.shape)
mean_X = np.mean(X, axis=0)
std_X = np.std(X, axis=0)
X = (X - mean_X) / std_X

tsne = TSNE(n_components=2, init='random', random_state=42,
                     perplexity=5)
Y = tsne.fit_transform(X)

nspk = Y.shape[0]
#nspk = 3
fig = plt.figure()
ax1 = fig.add_subplot(111)

#cmap = get_cmap(3, name='tab10') # for male, female and others
#colors = [cmap(i) for i in range(nspk)]
#colors = ['b'] * nspk
#smark = ['s'] * nspk
for i, spkid in enumerate(spks):
    # Check gender
    scolor = 'b'
    smark = '*'
    if spkid in spk2gender:
        if spk2gender[spkid] == 'm':
            scolor = 'g'
        elif spk2gender[spkid] == 'f':
            scolor = 'r'
    ax1.scatter(Y[i, 0], Y[i, 1], c=scolor, s=5, marker=smark)

plt.title(f'TSNE for {nspk} speakers in AM&NSF {data}. One vector per speaker.')


# Legend
#other_leg = mlines.Line2D([], [], color='blue', marker='s', linestyle='None',
#                        markersize=10, label='Others')
#v1male_leg = mlines.Line2D([], [], color='green', marker='*',
#                        linestyle='None', markersize=5, label='Voxceleb1 Male')
#v2male_leg = mlines.Line2D([], [], color='green', marker='^', linestyle='None',
#                        markersize=5, label='Voxceleb2 Male')
#v1female_leg = mlines.Line2D([], [], color='red', marker='*',
#                        linestyle='None', markersize=5, label='Voxceleb1 Female')
#v2female_leg = mlines.Line2D([], [], color='red', marker='^', linestyle='None',
#                        markersize=5, label='Voxceleb2 Female')
v2_leg = mlines.Line2D([], [], color='green', marker='*', linestyle='None',
                        markersize=5, label='Male')
v1_leg = mlines.Line2D([], [], color='red', marker='*',
                        linestyle='None', markersize=5, label='Female')

plt.legend(handles=[v1_leg, v2_leg])

plt.savefig(tsne_file, dpi=300)
