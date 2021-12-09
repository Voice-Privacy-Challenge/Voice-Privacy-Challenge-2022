#!/bin/python

'''
Script to divide a given data directory for Acoustic modeling 
and Neural Source Filter waveform modeling. The dev set will contain some
speakers from train set, and the test set will contain completely disjoint
speakers.

The root-dir should be in kaldi format, out-dir will be where newly created
train, dev and test will be stored.

The data division will be with respect to gender. First, ntest speakers
(ntest/2 male, ntest/2 female) will be
split from the dataset with all their utterances to create the test set, then
ndev speakers (ndev/2 male, ndev/2 female) will be sampled from remaining data
and a given percentage (dev-utt-per value can range from 0 to 1) of utterances 
will be sampled from each speaker to
create the dev set.

Remaining data will be used for training.

To run:
python local/split_am_nsf_data.py <root-dir> <out-dir> <ntest> <ndev>
'''

import sys
import os
from os.path import join, basename

args = sys.argv

root_dir = args[1]
out_dir = args[2]
ntest = int(args[3])
ndev = int(args[4])

print "Config: root_dir =", root_dir, " out_dir =", out_dir
print "Config: ntest =", ntest, " ndev =", ndev

test_dir = join(out_dir, basename(root_dir) + '_test')
dev_dir = join(out_dir, basename(root_dir) + '_dev')
train_dir = join(out_dir, basename(root_dir) + '_train')

spk2utt = {}
spk2gender = {}
utt2wav = {}
utt2text = {}
utt2spk = {}

with open(join(root_dir, 'spk2utt')) as f:
    for line in f.read().splitlines():
        sp = line.split()
        spkid = sp[0]
        utts = sp[1:]
        spk2utt[spkid] = utts

with open(join(root_dir, 'spk2gender')) as f:
    for line in f.read().splitlines():
        sp = line.split()
        spkid = sp[0]
        gen = sp[1]
        spk2gender[spkid] = gen

with open(join(root_dir, 'wav.scp')) as f:
    for line in f.read().splitlines():
        sp = line.split()
        uttid = sp[0]
        wav_path = ' '.join(sp[1:])
        utt2wav[uttid] = wav_path

with open(join(root_dir, 'text')) as f:
    for line in f.read().splitlines():
        sp = line.split()
        uttid = sp[0]
        text = ' '.join(sp[1:])
        utt2text[uttid] = text

with open(join(root_dir, 'utt2spk')) as f:
    for line in f.read().splitlines():
        sp = line.split()
        uttid = sp[0]
        spk = sp[1]
        utt2spk[uttid] = spk


# Find ntest/2 male and ntest/2 female speakers
test_spks = []
spklim = int(ntest / 2)
print "Per gender speaker limit for test =", spklim
mspk, fspk = 0, 0
for spk, gender in spk2gender.items():
    if mspk < spklim and gender == 'm':
        test_spks.append(spk)
        mspk += 1
    elif fspk < spklim and gender == 'f':
        test_spks.append(spk)
        fspk += 1

print "Selected ", len(test_spks), " test speakers."

# Find dev spks and utts
dev_spks = []
dev_utts = []
spklim = int(ndev / 2)
print "Per gender speaker limit for dev = ", spklim

mspk, fspk = 0, 0
for spk, gender in spk2gender.items():
    if spk not in test_spks:
        if mspk < spklim and gender == 'm':
            dev_spks.append(spk)
            spk_utts = spk2utt[spk]
            #utt_frac = int(devper * len(spk_utts))
            dev_utts.extend(spk_utts)
            mspk += 1
        elif fspk < spklim and gender == 'f':
            dev_spks.append(spk)
            spk_utts = spk2utt[spk]
            #utt_frac = int(devper * len(spk_utts))
            dev_utts.extend(spk_utts)
            fspk += 1

print "Selected ", len(dev_spks), " dev speakers."

os.makedirs(test_dir)
with open(join(test_dir, 'spk2utt.unsorted'), 'w') as f:
    for spk in test_spks:
        f.write(spk + ' ' + ' '.join(spk2utt[spk]) + '\n')

with open(join(test_dir, 'spk2gender.unsorted'), 'w') as f:
    for spk in test_spks:
        f.write(spk + ' ' + spk2gender[spk] + '\n')

with open(join(test_dir, 'utt2spk.unsorted'), 'w') as f:
    for spk in test_spks:
        for utt in spk2utt[spk]:
            f.write(utt + ' ' + spk + '\n')

with open(join(test_dir, 'text.unsorted'), 'w') as f:
    for spk in test_spks:
        for utt in spk2utt[spk]:
            f.write(utt + ' ' + utt2text[utt] + '\n')

with open(join(test_dir, 'wav.scp.unsorted'), 'w') as f:
    for spk in test_spks:
        for utt in spk2utt[spk]:
            f.write(utt + ' ' + utt2wav[utt] + '\n')

print "Finished creating test dir."

os.makedirs(dev_dir)
with open(join(dev_dir, 'spk2utt.unsorted'), 'w') as f:
    for spk in dev_spks:
        #spk_utts = [utt for utt in spk2utt[spk] if utt in dev_utts]
        spk_utts = spk2utt[spk]
        f.write(spk + ' ' + ' '.join(spk_utts) + '\n')

with open(join(dev_dir, 'spk2gender.unsorted'), 'w') as f:
    for spk in dev_spks:
        f.write(spk + ' ' + spk2gender[spk] + '\n')

with open(join(dev_dir, 'utt2spk.unsorted'), 'w') as f:
    for utt in dev_utts:
        f.write(utt + ' ' + utt2spk[utt] + '\n')

with open(join(dev_dir, 'text.unsorted'), 'w') as f:
    for utt in dev_utts:
        f.write(utt + ' ' + utt2text[utt] + '\n')

with open(join(dev_dir, 'wav.scp.unsorted'), 'w') as f:
    for utt in dev_utts:
        f.write(utt + ' ' + utt2wav[utt] + '\n')

print "Finished creating dev dir."

all_spks = list(spk2gender.keys())
all_utts = list(utt2spk.keys())
train_spks = [spk for spk in all_spks if spk not in test_spks and spk not in
                dev_spks]
train_utts = [utt for utt in all_utts if utt2spk[utt] not in test_spks and
                utt not in dev_utts]
print "Selected", len(train_spks), "train speakers and", len(train_utts), "train utterances."

os.makedirs(train_dir)
with open(join(train_dir, 'spk2utt.unsorted'), 'w') as f:
    for spk in train_spks:
        spk_utts = [utt for utt in spk2utt[spk] if utt in train_utts]
        f.write(spk + ' ' + ' '.join(spk_utts) + '\n')

with open(join(train_dir, 'spk2gender.unsorted'), 'w') as f:
    for spk in train_spks:
        f.write(spk + ' ' + spk2gender[spk] + '\n')

with open(join(train_dir, 'utt2spk.unsorted'), 'w') as f:
    for utt in train_utts:
        f.write(utt + ' ' + utt2spk[utt] + '\n')

with open(join(train_dir, 'text.unsorted'), 'w') as f:
    for utt in train_utts:
        f.write(utt + ' ' + utt2text[utt] + '\n')

with open(join(train_dir, 'wav.scp.unsorted'), 'w') as f:
    for utt in train_utts:
        f.write(utt + ' ' + utt2wav[utt] + '\n')

print "Finished creating train dir."
