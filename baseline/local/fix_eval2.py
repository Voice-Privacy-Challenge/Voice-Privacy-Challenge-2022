'''
Usage: python local/fix_eval2.py <protocol_dir> <enroll_dir> <trial_dir>
'''
import sys
import os
import shutil
from os.path import join, exists

args = sys.argv
proto_path = args[1]
enroll_dir = args[2]
trial_dir = args[3]

enroll_files = ["enroll.txt"]
trial_files = ["trials.txt"]

# Prepare enroll data
wav_scp = []
utt2spk = []
spk2gender = []
text = []

enroll_spks = set()
enroll_uttids = set()

for ef in enroll_files:
    ef_path = join(proto_path, ef)
    with open(ef_path) as f:
        for line in f.read().splitlines():
            line = line.strip().split()

            # Register all speaker ids
            spkid = line[0]
            enroll_spks.add(spkid)

            # Register all utterance ids
            uttarr = line[1].split(',')
            for utt in uttarr:
                uttid = utt.split('/')[-1].split('.')[0]
                enroll_uttids.add(uttid)

# Filter wav.scp, utt2spk, text and spk2gender
# based on spkids and uttids
with open(join(enroll_dir, 'wav.scp')) as f:
    for line in f.readlines():
        uttid = line.split()[0]
        if uttid in enroll_uttids:
            wav_scp.append(line)
with open(join(enroll_dir, 'text')) as f:
    for line in f.readlines():
        uttid = line.split()[0]
        if uttid in enroll_uttids:
            text.append(line)
with open(join(enroll_dir, 'utt2spk')) as f:
    for line in f.readlines():
        uttid = line.split()[0]
        if uttid in enroll_uttids:
            utt2spk.append(line)
with open(join(enroll_dir, 'spk2gender')) as f:
    for line in f.readlines():
        spkid = line.split()[0]
        if spkid in enroll_spks:
            spk2gender.append(line)
with open(join(enroll_dir, 'wav.scp'), 'w') as f:
    for line in wav_scp:
        f.write(line)
with open(join(enroll_dir, 'text'), 'w') as f:
    for line in text:
        f.write(line)
with open(join(enroll_dir, 'utt2spk'), 'w') as f:
    for line in utt2spk:
        f.write(line)
with open(join(enroll_dir, 'spk2gender'), 'w') as f:
    for line in spk2gender:
        f.write(line)



# Prepare trial data
wav_scp = []
utt2spk = []
spk2gender = []
text = []
trials_male = []
trials_female = []

trial_spks = set()
trial_uttids = set()

for i, tf in enumerate(trial_files):
    tf_path = join(proto_path, tf)
    with open(tf_path) as f:
        for line in f.read().splitlines():
            line = line.strip().split()
            spkid = line[0]
            utt = line[1]
            target_type = line[2]
            gender = line[3]

            uttid = utt.split('/')[-1].split('.')[0]
            utt_spkid = uttid.split('-')[0]

            trial_spks.add(spkid)
            trial_spks.add(utt_spkid)
            trial_uttids.add(uttid)

            if gender == 'M':
                trials_male.append(spkid + ' ' + uttid + ' ' + target_type)
            else:
                trials_female.append(spkid + ' ' + uttid + ' ' + target_type)


# Filter wav.scp, utt2spk and spk2gender
# based on spkids and uttids
with open(join(trial_dir, 'wav.scp')) as f:
    for line in f.readlines():
        uttid = line.split()[0]
        if uttid in trial_uttids:
            wav_scp.append(line)
with open(join(trial_dir, 'text')) as f:
    for line in f.readlines():
        uttid = line.split()[0]
        if uttid in trial_uttids:
            text.append(line)
with open(join(trial_dir, 'utt2spk')) as f:
    for line in f.readlines():
        uttid = line.split()[0]
        if uttid in trial_uttids:
            utt2spk.append(line)
with open(join(trial_dir, 'spk2gender')) as f:
    for line in f.readlines():
        spkid = line.split()[0]
        if spkid in trial_spks:
            spk2gender.append(line)
with open(join(trial_dir, 'wav.scp'), 'w') as f:
    for line in wav_scp:
        f.write(line)
with open(join(trial_dir, 'text'), 'w') as f:
    for line in text:
        f.write(line)
with open(join(trial_dir, 'utt2spk'), 'w') as f:
    for line in utt2spk:
        f.write(line)
with open(join(trial_dir, 'spk2gender'), 'w') as f:
    for line in spk2gender:
        f.write(line)


all_trials = sorted(trials_male + trials_female)
with open(join(trial_dir, 'trials'), 'w') as f:
    f.write('\n'.join(all_trials) + '\n')

tt_male = sorted(trials_male)
tt_female = sorted(trials_female)
with open(join(trial_dir, 'trials_male'), 'w') as f:
    f.write('\n'.join(tt_male) + '\n')
with open(join(trial_dir, 'trials_female'), 'w') as f:
    f.write('\n'.join(tt_female) + '\n')

