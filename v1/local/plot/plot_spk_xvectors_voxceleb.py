import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.lines as mlines


import numpy as np
from sklearn.manifold import TSNE

import kaldi_io

spk_xvector_file = 'exp/xvector_nnet_1a/xvectors_train/spk_xvector.scp'
tsne_file = 'exp/xvector_nnet_1a/xvectors_train/voxceleb_spk_xvector_voxversion.png'

vox1_meta_file = '/home/bsrivast/asr_data/VoxCeleb/voxceleb/vox1_meta_map.csv'
vox2_meta_file = '/home/bsrivast/asr_data/VoxCeleb/voxceleb2/vox2_meta.csv'

def get_cmap(n, name='hsv'):
    return plt.cm.get_cmap(name, n)

# get gender info
spk2gender = {}
spk2vox = {}
with open(vox1_meta_file) as f:
    for line in f.read().splitlines():
        sp = line.split()
        spkid = sp[1]
        gen = sp[2]
        spk2gender[spkid] = gen
        spk2vox[spkid] = 1
with open(vox2_meta_file) as f:
    for line in f.read().splitlines()[1:]:
        sp = line.split(',')
        spkid = sp[0].strip()
        gen = sp[2].strip()
        spk2gender[spkid] = gen
        spk2vox[spkid] = 2

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
                     perplexity=100)
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
    #if spkid in spk2gender:
    #    if spk2gender[spkid] == 'm':
    #        scolor = 'g'
    #    elif spk2gender[spkid] == 'f':
    #        scolor = 'r'
    # Check voxceleb version
    smark = 's'
    if spkid in spk2vox:
        if spk2vox[spkid] == 1:
            smark = '*'
            scolor = 'r'
        elif spk2vox[spkid] == 2:
            smark = '^'
            scolor = 'g'

    ax1.scatter(Y[i, 0], Y[i, 1], c=scolor, s=1, marker=smark)

#ax1.scatter(Y[:, 0], Y[:, 1], c=colors, s=1, marker=smark)
plt.title(f'TSNE for {nspk} speakers in Voxceleb train. One vector per speaker.')


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
v2_leg = mlines.Line2D([], [], color='green', marker='^', linestyle='None',
                        markersize=5, label='Voxceleb2')
v1_leg = mlines.Line2D([], [], color='red', marker='*',
                        linestyle='None', markersize=5, label='Voxceleb1')

plt.legend(handles=[v1_leg, v2_leg])

plt.savefig(tsne_file, dpi=300)
