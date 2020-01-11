import sys
import kaldi_io
import os
from os.path import join, isdir

from scipy.spatial import distance

args = sys.argv

src_xvec_dir = args[1]
pool_xvec_dir = args[2]
scores_dir = args[3]

if not isdir(scores_dir):
    os.makedirs(scores_dir)

src_xvec_file = join(src_xvec_dir, 'spk_xvector.scp')
pool_xvec_file = join(pool_xvec_dir, 'spk_xvector.scp')

pool_xvectors = {}
c = 0
with open(pool_xvec_file) as f:
    for key, xvec in kaldi_io.read_vec_flt_scp(f):
        #print key, mat.shape
        pool_xvectors[key] = xvec
        c += 1
print("Read ", c, "pool xvectors")

with open(src_xvec_file) as f:
    for sspk, sxvec in kaldi_io.read_vec_flt_scp(f):
        print("Computing cosine measure for " + sspk)
        with open(join(scores_dir, 'affinity_'+sspk), 'w') as sf:
            for pspk, pxvec in pool_xvectors.items():
                # compute cosine distance between src and pool spk
                # Multiplying by -1 to ensure compatibility with affinity
                # Now lower value will indicate less affinity as compared
                # to original cosine distance
                dist = -1.0 * distance.cosine(sxvec, pxvec)
                sf.write(sspk + ' ' + pspk + ' ' + str(dist) + '\n')

