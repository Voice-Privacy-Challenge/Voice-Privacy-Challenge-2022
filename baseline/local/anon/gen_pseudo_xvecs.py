import sys
from os.path import basename, join
import operator

import numpy as np
import random
from kaldiio import WriteHelper, ReadHelper

args = sys.argv
print(args)

src_data = args[1]
pool_data = args[2]
affinity_scores_dir = args[3]
xvec_out_dir = args[4]
pseudo_xvecs_dir = args[5]
rand_level = args[6]
cross_gender = args[7] == "true"
proximity = args[8]

rand_seed = args[9]

REGION = 100
WORLD = 200

random.seed(rand_seed)

if cross_gender:
    print("**Opposite gender speakers will be selected.**")
else:
    print("**Same gender speakers will be selected.**")

print("Randomization level: " + rand_level)
print("Proximity: " + proximity)
# Core logic of anonymization by randomization
def select_random_xvec(top500, pool_xvectors):
    # number of random xvectors to select out of pool
    #random100mask = np.random.random_integers(0, 199, NR)
    random100mask = random.sample(range(WORLD), REGION)
    pseudo_spk_list = [x for i, x in enumerate(top500) if i in
                           random100mask]
    pseudo_spk_matrix = np.zeros((REGION, 512), dtype='float64')
    for i, spk_aff in enumerate(pseudo_spk_list):
        pseudo_spk_matrix[i, :] = pool_xvectors[spk_aff[0]]
    # Take mean of 100 randomly selected xvectors
    pseudo_xvec = np.mean(pseudo_spk_matrix, axis=0)
    return pseudo_xvec


gender_rev = {'m': 'f', 'f': 'm'}
src_spk2gender_file = join(src_data, 'spk2gender')
src_spk2utt_file = join(src_data, 'spk2utt')
pool_spk2gender_file = join(pool_data, 'spk2gender')

src_spk2gender = {}
src_spk2utt = {}
pool_spk2gender = {}
# Read source spk2gender and spk2utt
print("Reading source spk2gender.")
with open(src_spk2gender_file) as f:
    for line in f.read().splitlines():
        sp = line.split()
        src_spk2gender[sp[0]] = sp[1]
print("Reading source spk2utt.")
with open(src_spk2utt_file) as f:
    for line in f.read().splitlines():
        sp = line.split()
        src_spk2utt[sp[0]] = sp[1:]
# Read pool spk2gender
print("Reading pool spk2gender.")
with open(pool_spk2gender_file) as f:
    for line in f.read().splitlines():
        sp = line.split()
        pool_spk2gender[sp[0]] = sp[1]

# Read pool xvectors
print("Reading pool xvectors.")
pool_xvec_file = join(xvec_out_dir, 'xvectors_'+basename(pool_data),
                     'spk_xvector.scp')
pool_xvectors = {}
c = 0
#with open(pool_xvec_file) as f:
 #   for key, xvec in kaldi_io.read_vec_flt_scp(f):
with ReadHelper('scp:'+pool_xvec_file) as reader:
    for key, xvec in reader:
        #print key, mat.shape
        pool_xvectors[key] = xvec
        c += 1
print("Read ", c, "pool xvectors")

pseudo_xvec_map = {}
pseudo_gender_map = {}
for spk, gender in src_spk2gender.items():
    # Filter the affinity pool by gender
    affinity_pool = {}
    # If we are doing cross-gender VC, reverse the gender else gender remains same
    if cross_gender:
        gender = gender_rev[gender]
    #print("Filtering pool for spk: "+spk)
    pseudo_gender_map[spk] = gender
    with open(join(affinity_scores_dir, 'affinity_'+spk)) as f:
        for line in f.read().splitlines():
            sp = line.split()
            pool_spk = sp[1]
            af_score = float(sp[2])
            if pool_spk2gender[pool_spk] == gender:
                affinity_pool[pool_spk] = af_score

    # Sort the filtered affinity pool by scores
    if proximity == "farthest":
        sorted_aff = sorted(affinity_pool.items(), key=operator.itemgetter(1))
    elif proximity == "nearest":
        sorted_aff = sorted(affinity_pool.items(), key=operator.itemgetter(1),
                           reverse=True)


    # Select WORLD least affinity speakers and then randomly select REGION out of
    # them
    top_spk = sorted_aff[:WORLD]
    if rand_level == 'spk':
        # For rand_level = spk, one xvector is assigned to all the utterances
        # of a speaker
        pseudo_xvec = select_random_xvec(top_spk, pool_xvectors)
        # Assign it to all utterances of the current speaker
        for uttid in src_spk2utt[spk]:
            pseudo_xvec_map[uttid] = pseudo_xvec
    elif rand_level == 'utt':
        # For rand_level = utt, random xvector is assigned to all the utterances
        # of a speaker
        for uttid in src_spk2utt[spk]:
            # Compute random vector for every utt
            pseudo_xvec = select_random_xvec(top_spk, pool_xvectors)
            # Assign it to all utterances of the current speaker
            pseudo_xvec_map[uttid] = pseudo_xvec
    else:
        print("rand_level not supported! Errors will happen!")


# Write features as ark,scp
print("Writing pseud-speaker xvectors to: "+pseudo_xvecs_dir)
ark_scp_output = 'ark,scp:{}/{}.ark,{}/{}.scp'.format(
                    pseudo_xvecs_dir, 'pseudo_xvector',
                    pseudo_xvecs_dir, 'pseudo_xvector')
with WriteHelper(ark_scp_output) as writer:
      for uttid, xvec in pseudo_xvec_map.items():
          writer(uttid, xvec)

print("Writing pseudo-speaker spk2gender.")
with open(join(pseudo_xvecs_dir, 'spk2gender'), 'w') as f:
    spk2gen_arr = [spk+' '+gender for spk, gender in pseudo_gender_map.items()]
    sorted_spk2gen = sorted(spk2gen_arr)
    f.write('\n'.join(sorted_spk2gen) + '\n')


