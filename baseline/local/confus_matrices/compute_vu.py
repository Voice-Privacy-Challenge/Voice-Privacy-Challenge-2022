#!/usr/bin/python

import argparse
import numpy as np
import math
from scipy.stats.mstats import gmean


def Ddiag(X):
    N   = X.shape[0]                #matrix dimension
    m   = np.mean(X)                #mean of all elements
    md  = np.mean(np.diag(X))       #mean of diagonal elements
    mnd = (N/(N-1))*(m-(md/N))      #mean of off-diagonal elements             
    return abs(md-mnd)

if __name__=="__main__":

    parser = argparse.ArgumentParser(description='Compute Gain of Voice Uniqueness')
    parser.add_argument('Coo',help="npy file of the matrix Coo", type=str)
    parser.add_argument('Caa',help="npy file of the matrix Caa", type=str)
    args = parser.parse_args()

    Coo = np.load(args.Coo)
    Caa = np.load(args.Caa)

    Edoo = Ddiag(Coo)
    Edaa = Ddiag(Caa)

    print(10*np.log10(Edaa/Edoo))

