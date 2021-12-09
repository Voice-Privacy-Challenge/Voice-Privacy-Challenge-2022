#!/usr/bin/python

import argparse
import numpy as np
import math


def Ddiag(X):
    N   = X.shape[0]                #matrix dimension
    m   = np.mean(X)                #mean of all elements
    md  = np.mean(np.diag(X))       #mean of diagonal elements
    mnd = (N/(N-1))*(m-(md/N))      #mean of off-diagonal elements             
    return abs(md-mnd)

if __name__=="__main__":

    parser = argparse.ArgumentParser(description='Compute Gain of Voice Uniqueness')
    parser.add_argument('Soo',help="npy file of the similarity matrix Soo", type=str)
    parser.add_argument('Spp',help="npy file of the similarity matrix Spp", type=str)
    args = parser.parse_args()

    Soo = np.load(args.Soo)
    Spp = np.load(args.Spp)

    print(10*np.log10(Ddiag(Spp)/Ddiag(Soo)))

