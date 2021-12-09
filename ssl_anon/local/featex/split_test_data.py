import os
from os.path import join, exists
import sys

args = sys.argv

root_dir = args[1]
test_file = join(root_dir, 'scp/test.lst')

test_dir = args[2]

xvector_dir = join(root_dir, 'xvector')
f0_dir = join(root_dir, 'f0')
mel_dir = join(root_dir, 'mel')
ppg_dir = join(root_dir, 'ppg')

out_xvector_dir = join(test_dir, 'xvector')
out_f0_dir = join(test_dir, 'f0')
out_mel_dir = join(test_dir, 'mel')
out_ppg_dir = join(test_dir, 'ppg')

if not exists(out_xvector_dir):
    os.makedirs(out_xvector_dir)
if not exists(out_f0_dir):
    os.makedirs(out_f0_dir)
if not exists(out_mel_dir):
    os.makedirs(out_mel_dir)
if not exists(out_ppg_dir):
    os.makedirs(out_ppg_dir)

with open(test_file) as f:
    for line in f.read().splitlines():
        os.rename(join(xvector_dir, line+'.xvector'), join(out_xvector_dir,
                                                           line+'.xvector'))
        os.rename(join(f0_dir, line+'.f0'), join(out_f0_dir, line+'.f0'))
        os.rename(join(mel_dir, line+'.mel'), join(out_mel_dir, line+'.mel'))
        os.rename(join(ppg_dir, line+'.ppg'), join(out_ppg_dir, line+'.ppg'))



