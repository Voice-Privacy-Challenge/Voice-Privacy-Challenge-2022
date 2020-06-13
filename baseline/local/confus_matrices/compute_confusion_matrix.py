#!/usr/bin/python

import argparse
import numpy as np
import math
from scipy.stats.mstats import gmean
from math import log10, log2

def readMat(ar):
    fh = open(ar)
    x = []
    for line in fh.readlines():
        y = [str(value) for value in line.split()]
        x.append(y)
    fh.close()
    return x

def getListOfSpk(spk_trial):
    L = []
    for i in range(len(spk_trial)):
        if not spk_trial[i,0] in L:
            L.append(spk_trial[i,0])
    return L

def getListOfLlrGivenAandB(scores,spk_trial,A,B):
    a = spk_trial[:,0]
    b = spk_trial[:,1]
    indexes_a = np.where(a == A)[0]
    indexes_b = np.where(b == B)[0]
    indexes = list(set(indexes_a)&set(indexes_b))
    return scores[indexes]
    #return (10**scores[indexes]/(1 + 10**scores[indexes]))

if __name__=="__main__":

    parser = argparse.ArgumentParser(description='Compute the confusion matrix given the PLDA output scores and the speaker id trial file')
    parser.add_argument('scores',help="PLDA output scores file", type=str)
    parser.add_argument('spk_trial',help="speaker trial file (speaker id corresponding to the trial file)", type=str)
    parser.add_argument('out_dir',help="output directory",type=str)
    parser.add_argument('name',help="name of the confusion matrix",type=str)
    args = parser.parse_args()

    scores      = np.array(readMat(args.scores))[:,2]
    scores      = np.array([float(s) for s in scores])
    spk_trial   = np.array(readMat(args.spk_trial))
    out_dir     = args.out_dir
    name        = args.name

    #sum_llrs    = sum(10**scores)
    spk_list            = getListOfSpk(spk_trial)
    N_spk               = len(spk_list)

    confusion_matrix    = np.zeros((N_spk,N_spk))
    k = 0
    for i in range(N_spk):
        for j in range(k,N_spk):
            LLR = getListOfLlrGivenAandB(scores,spk_trial,spk_list[i],spk_list[j])
            #c = gmean(LLR)
            LLR = np.array(LLR)
            #if i == j:
            #    c = np.sum(np.log2(1+ 1/LR))/len(LR)
            #else:
            #    c = np.sum(np.log2(1+ LR))/len(LR)
            #c = sum(np.log2(1+LR)/len(LR))
            c = 1/(1 + np.exp(-(np.sum(LLR)/len(LLR))))
            confusion_matrix[i,j] = c #(sum(LLR)/len(LLR))
            confusion_matrix[j,i] = c #(sum(LLR)/len(LLR))
        k += 1

    #print("sum conf")
    #print(np.sum(confusion_matrix))
   
    #confusion_matrix = confusion_matrix/np.sum(confusion_matrix)

    np.save(out_dir+"/confusion_matrix_"+name,confusion_matrix)
