import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import ReadHelper

args = sys.argv
ppg_file = args[1]
out_dir = args[2]

ppg_out_dir = join(out_dir, "ppg")

print("Writing PPG feats.....")
# Write ppg features
with ReadHelper('scp:'+ppg_file) as reader:
    for key, mat in reader:
        readwrite.write_raw_mat(mat, join(ppg_out_dir, key+'.ppg'))
print("Finished writing PPG feats.")

