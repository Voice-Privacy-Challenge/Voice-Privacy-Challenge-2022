from os.path import join

import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import operator


# Each data dir must contain an utt2dur
data_dirs = ['data/test_clean', 'data/dev_clean', 'data/test_other', 'data/dev_other', 'data/train_960']
plot_file = 'data/spks_stats.png'


spk2dur = {}
for ddir in data_dirs:
    with open(join(ddir, 'utt2dur')) as f:
        for line in f.read().splitlines():
            sp = line.split()
            spk = sp[0].split('-')[0]
            cdur = float(sp[1])
            spk2dur[spk] = spk2dur.get(spk, 0.0) + cdur

print(f"Found {len(spk2dur)} of speakers")

sorted_spk2dur = sorted(spk2dur.items(), key=operator.itemgetter(1))

#ditems = spk2dur.items()
spks = [x[0] for x in sorted_spk2dur]
durs = [x[1] for x in sorted_spk2dur]

mean_dur = round(np.mean(durs), 2)

x_pos = np.arange(len(spks))

plt.bar(x_pos, durs, align='center')
plt.axhline(y=mean_dur, color='r', linestyle='-')
plt.annotate(f'Mean duration = {mean_dur}', xy=(20, mean_dur+10))
#plt.xticks(x_pos, spks)
plt.ylabel('Duration (sec.)')
plt.grid(True)

plt.title(f'Durations of {len(spks)} speakers found in LibriSpeech')


plt.savefig(plot_file, dpi=300) 
