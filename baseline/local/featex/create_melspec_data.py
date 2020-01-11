
import sys
from os.path import join, basename

from ioTools import readwrite
import kaldi_io

args = sys.argv
mspec_file = args[1]
out_dir = args[2]

mspec_out_dir = join(out_dir, "mel")

print "Writing MEL feats....."
# Write mspec features
for key, mat in kaldi_io.read_mat_scp(mspec_file):
    #print key, mat.shape
    readwrite.write_raw_mat(mat, join(mspec_out_dir, key+'.mel'))
print "Finished writing MEL feats."
