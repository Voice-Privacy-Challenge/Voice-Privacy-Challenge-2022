#!/usr/bin/python

import sys
sys.path.append('../cllr/')
import argparse
import numpy as np

from performance import optimal_llr

def readMat(ar):
    fh = open(ar)
    x = []
    for line in fh.readlines():
        y = [str(value) for value in line.split()]
        x.append(y)
    fh.close()
    return x

if __name__=="__main__":

    parser = argparse.ArgumentParser(description="Scores calibration")
    parser.add_argument('scores',help="", type=str)
    parser.add_argument('spk',help="spk trials",type=str)
    args = parser.parse_args()

    S = np.array(readMat(args.scores))
    SPK = np.array(readMat(args.spk))
    S = S.astype(np.str)
    SPK = SPK.astype(np.str)

    NON     = []
    TAR     = []
    SPK_NON = []
    SPK_TAR = []
    
    for i in range(len(SPK)):
        if SPK[i,0] == SPK[i,1]:
            TAR.append(S[i,:])
            SPK_TAR.append(SPK[i,:])
        else:
            NON.append(S[i,:])
            SPK_NON.append(SPK[i,:])

    NON = np.array(NON)
    TAR = np.array(TAR)
    SPK_NON = np.array(SPK_NON)
    SPK_TAR = np.array(SPK_TAR)
    
    non = NON[:,2].astype(np.float)
    tar = TAR[:,2].astype(np.float)

    tar, non = optimal_llr(tar, non, laplace=True)

    non = non.astype(np.str)
    tar = tar.astype(np.str)

    NON = NON.astype(non.dtype)
    TAR = TAR.astype(tar.dtype)

    NON[:,2] = non
    TAR[:,2] = tar

    S = np.concatenate((TAR,NON))   
    SPK = np.concatenate((SPK_TAR,SPK_NON))
    np.savetxt(args.scores+".calibrated",S,fmt="%s")
    np.savetxt(args.spk+".calibrated",SPK,fmt="%s")

