#!/usr/bin/python

import argparse
import numpy as np


def Ddiag(X):
    N   = X.shape[0]                #matrix dimension
    m   = np.mean(X)                #mean of all elements
    md  = np.mean(np.diag(X))       #mean of diagonal elements
    mnd = (N/(N-1))*(m-(md/N))      #mean of off-diagonal elements             
    return abs(md-mnd)



if __name__=="__main__":

    parser = argparse.ArgumentParser(description='Compute De-Identification')
    parser.add_argument('Soo',help="npy file of the matrix Soo", type=str)
    parser.add_argument('Sop',help="npy file of the matrix Sop", type=str)
    args = parser.parse_args()

    Soo = np.load(args.Soo)
    Sop = np.load(args.Sop)

    print(1-(Ddiag(Sop)/Ddiag(Soo)))

