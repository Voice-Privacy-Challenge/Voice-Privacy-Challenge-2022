#!/usr/bin/python

import argparse
import numpy as np
from scipy.stats.mstats import gmean

def Ddiag(X):
    N   = X.shape[0]
    m   = np.mean(X)
    md  = np.mean(np.diag(X))
    mnd = (N/(N-1))*(m-(md/N))
    
    return abs(md-mnd)

if __name__=="__main__":

    parser = argparse.ArgumentParser(description='Compute De-Identification')
    parser.add_argument('Coo',help="npy file of the matrix Coo", type=str)
    parser.add_argument('Coa',help="npy file of the matrix Coa", type=str)
    args = parser.parse_args()

    Coo = np.load(args.Coo)
    Coa = np.load(args.Coa)

    #Coo -= np.min(Coo)
    #Coa -= np.min(Coa)

    #Coo = Coo/np.max(Coo)
    #Coa = Coa/np.max(Coa)

    #Coo = Normalise(Coo)
    #Coa = Normalise(Coa)

    Edoo = Ddiag(Coo)
    Edoa = Ddiag(Coa)

    print(1-(Edoa/Edoo))

