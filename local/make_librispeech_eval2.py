'''
Usage: python local/make_librispeech_eval.py <protocol_dir> <librispeech_data_path> <exp_tag>
'''
import sys
import os
import shutil
from os.path import join, exists

args = sys.argv
proto_path = args[1]
data_path = args[2]
if len(args) > 3:
    exp_tag = args[3]
else:
    exp_tag = ""

enroll_files = ["dev_clean_train.txt"]
trial_files = ["dev_clean_trials.txt"]

# Prepare enroll data
enroll_dir = 'data/eval2_enroll'+exp_tag
prefix_spkid = {}
if exists(enroll_dir):
    shutil.rmtree(enroll_dir)
os.makedirs(enroll_dir)
enroll_wav_scp = []
enroll_utt2spk = []
spk2gender = []
for ef in enroll_files:
    ef_path = join(proto_path, ef)
    with open(ef_path) as f:
        for line in f.read().splitlines():
            line = line.strip().split()
            spkid = line[0]
            gender = line[2].lower()
            spk2gender.append(spkid + ' ' + gender)
            uttarr = line[1].split(',')
            for utt in uttarr:
                uttid = utt.split('/')[-1].split('.')[0]
                prefix_key = uttid.split('-')[0]
                if prefix_key not in prefix_spkid:
                    prefix_spkid[prefix_key] = spkid
                uttid = spkid+'-'+uttid
                uttpath = join(data_path, utt)
                enroll_wav_scp.append(uttid + ' flac -c -d -s ' + uttpath + ' | ')
                enroll_utt2spk.append(uttid + ' ' + spkid)

enroll_wav_scp = sorted(enroll_wav_scp)
enroll_utt2spk = sorted(enroll_utt2spk)
spk2gender = sorted(spk2gender)
with open(join(enroll_dir, 'wav.scp'), 'w') as f:
    f.write('\n'.join(enroll_wav_scp) + '\n')
with open(join(enroll_dir, 'utt2spk'), 'w') as f:
    f.write('\n'.join(enroll_utt2spk) + '\n')
with open(join(enroll_dir, 'spk2gender'), 'w') as f:
    f.write('\n'.join(spk2gender) + '\n')


# Prepare trial data
trial_dir = 'data/eval2_trial'+exp_tag
if exists(trial_dir):
    shutil.rmtree(trial_dir)
os.makedirs(trial_dir)
trial_wav_scp = []
trial_utt2spk = []
spk2gender = []
trial_trials_male = []
trial_trials_female = []
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
            prefix_key = uttid.split('-')[0]
            if prefix_key in prefix_spkid:
                prefix = prefix_spkid[prefix_key]
            else:
                prefix = 'dev_clean_'+prefix_key
                prefix_spkid[prefix_key] = prefix
            uttid = prefix + '-' + uttid
            spk2gender.append(prefix + ' ' + gender.lower())

            uttpath = join(data_path, utt)
            trial_wav_scp.append(uttid + ' flac -c -d -s ' + uttpath + ' | ')
            trial_utt2spk.append(uttid + ' ' + prefix)
            if gender == 'M':
                trial_trials_male.append(spkid + ' ' + uttid + ' ' + target_type)
            else:
                trial_trials_female.append(spkid + ' ' + uttid + ' ' + target_type)

trial_wav_scp = sorted(trial_wav_scp)
trial_utt2spk = sorted(trial_utt2spk)
trial_trials = sorted(trial_trials_male + trial_trials_female)
with open(join(trial_dir, 'wav.scp'), 'w') as f:
    f.write('\n'.join(trial_wav_scp) + '\n')
with open(join(trial_dir, 'utt2spk'), 'w') as f:
    f.write('\n'.join(trial_utt2spk) + '\n')
with open(join(trial_dir, 'trials'), 'w') as f:
    f.write('\n'.join(trial_trials) + '\n')

tt_male = sorted(trial_trials_male)
tt_female = sorted(trial_trials_female)
with open(join(trial_dir, 'trials_male'), 'w') as f:
    f.write('\n'.join(tt_male) + '\n')
with open(join(trial_dir, 'trials_female'), 'w') as f:
    f.write('\n'.join(tt_female) + '\n')

with open(join(trial_dir, 'spk2gender'), 'w') as f:
    f.write('\n'.join(spk2gender) + '\n')

