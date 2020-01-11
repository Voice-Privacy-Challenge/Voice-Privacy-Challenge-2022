import kaldi_io
from kaldiio import ReadHelper

#ppg_scp_file = 'exp/nnet3_cleaned/ppg_train_clean_460/phone_post.scp'
ppg_scp_file = 'exp/nnet3_cleaned/ppg_wpd_fs1_train_clean_460/phone_post.1.scp'
mfcc_scp_file = 'data/train_clean_460_hires/feats.scp'

ppg2shape = {}
mfcc2shape = {}
c = 0
with open(mfcc_scp_file) as f:
    for key, mat in kaldi_io.read_mat_scp(f):
        #print(key, mat.shape)
        #mfcc2shape[key] = mat.shape
        #c += 1
        #if c > 10:
        #    break
        if key == '115-121720-0000':
            print mat.shape
            break

'''
c = 0
with ReadHelper('scp:'+ppg_scp_file) as reader:
    for key, mat in reader:
        #print(key, mat.shape)
        ppg2shape[key] = mat.shape
        c += 1
        if c > 10:
            break

for utt, mshape in mfcc2shape.items():
    if utt in ppg2shape:
        #print(f'Utt: {utt}, MFCC shape: {mshape}, PPG shape: {ppg2shape[utt]}')
        print 'Utt:', utt, 'MFCC shape:', mshape, 'PPG shape:', ppg2shape[utt]
'''
