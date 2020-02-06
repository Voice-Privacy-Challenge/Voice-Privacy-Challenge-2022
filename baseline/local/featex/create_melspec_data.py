
import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper

args = sys.argv
mspec_file = args[1]
out_dir = args[2]

mspec_out_dir = join(out_dir, "mel")

print("Writing MEL feats.....")
# Write mspec features
with ReadHelper('scp:'+mspec_file) as reader:
    for key, mat in reader:
    #print key, mat.shape
        readwrite.write_raw_mat(mat, join(mspec_out_dir, key+'.mel'))
print("Finished writing MEL feats.")
