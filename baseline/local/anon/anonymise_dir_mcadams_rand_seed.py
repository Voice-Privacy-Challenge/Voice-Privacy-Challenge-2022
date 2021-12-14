#!/usr/bin/env python3.0
# -*- coding: utf-8 -*-
"""
@author: Jose Patino, Massimiliano Todisco, Pramod Bachhav, Nicholas Evans
Audio Security and Privacy Group, EURECOM
"""
import os
import librosa
import numpy as np
import scipy
import argparse
import matplotlib.pyplot as plt
import random

def anonym(n,file, output_dir, winLengthinms=20, shiftLengthinms=10, lp_order=20, mcadams=0.8):    
    filename = file[0]
    filepath = file[1]
    output_file = output_dir + filename +'.wav'
    print(mcadams)
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    if not os.path.exists(output_file):
	    sig, fs = librosa.load(filepath,sr=None)    
	    eps = np.finfo(np.float32).eps
	    sig = sig+eps
	    
	    # simulation parameters
	    winlen = np.floor(winLengthinms*0.001*fs).astype(int)
	    shift = np.floor(shiftLengthinms*0.001*fs).astype(int)
	    length_sig = len(sig)
	    
	    # fft processing parameters
	    NFFT = 2**(np.ceil((np.log2(winlen)))).astype(int)
	    # anaysis and synth window which satisfies the constraint
	    wPR = np.hanning(winlen)
	    K = np.sum(wPR)/shift
	    win = np.sqrt(wPR/K)
	    Nframes = 1+np.floor((length_sig-winlen)/shift).astype(int) # nr of complete frames   
	    
	    # carry out the overlap - add FFT processing
	    sig_rec = np.zeros([length_sig]) # allocate output+'ringing' vector
	    
	    for m in np.arange(1,Nframes):
	        # indices of the mth frame
	        index = np.arange(m*shift,np.minimum(m*shift+winlen,length_sig))    
	        # windowed mth frame (other than rectangular window)
	        frame = sig[index]*win 
	        # get lpc coefficients
	        a_lpc = librosa.core.lpc(frame+eps,lp_order)
	        # get poles
	        poles = scipy.signal.tf2zpk(np.array([1]), a_lpc)[1]
	        #index of imaginary poles
	        ind_imag = np.where(np.isreal(poles)==False)[0]
	        #index of first imaginary poles
	        ind_imag_con = ind_imag[np.arange(0,np.size(ind_imag),2)]
	        
	        # here we define the new angles of the poles, shifted accordingly to the mcadams coefficient
	        # values >1 expand the spectrum, while values <1 constract it for angles>1
		# values >1 constract the spectrum, while values <1 expand it for angles<1
		# the choice of this value is strongly linked to the number of lpc coefficients
	        # a bigger lpc coefficients number constraints the effect of the coefficient to very small variations
	        # a smaller lpc coefficients number allows for a bigger flexibility
	        new_angles = np.angle(poles[ind_imag_con])**mcadams
	        #new_angles = np.angle(poles[ind_imag_con])**path[m]
	        
	        # make sure new angles stay between 0 and pi
	        new_angles[np.where(new_angles>=np.pi)] = np.pi        
	        new_angles[np.where(new_angles<=0)] = 0  
	        
	        # copy of the original poles to be adjusted with the new angles
	        new_poles = poles
	        for k in np.arange(np.size(ind_imag_con)):
	            # compute new poles with the same magnitued and new angles
	            new_poles[ind_imag_con[k]] = np.abs(poles[ind_imag_con[k]])*np.exp(1j*new_angles[k])
	            # applied also to the conjugate pole
	            new_poles[ind_imag_con[k]+1] = np.abs(poles[ind_imag_con[k]+1])*np.exp(-1j*new_angles[k])            
	        
	        # recover new, modified lpc coefficients
	        a_lpc_new = np.real(np.poly(new_poles))
	        # get residual excitation for reconstruction
	        res = scipy.signal.lfilter(a_lpc,np.array(1),frame)
	        # reconstruct frames with new lpc coefficient
	        frame_rec = scipy.signal.lfilter(np.array([1]),a_lpc_new,res)
	        frame_rec = frame_rec*win    
	 
	        outindex = np.arange(m*shift,m*shift+len(frame_rec))
	        # overlap add
	        sig_rec[outindex] = sig_rec[outindex] + frame_rec
	    sig_rec = sig_rec/np.max(np.abs(sig_rec))
	    scipy.io.wavfile.write(output_file, fs, np.float32(sig_rec)) 
	   	#return []
    else:
	    print('file already exists')


def get_seed_from_string(dataset, filename):
    print(dataset, filename) ##
    if dataset.split('_')[0]=='vctk':
        spkr_id = filename.split('_')[0]
    elif dataset.split('_')[0]=='libri':
        spkr_id = filename.split('-')[0]
    else: spkr_id = filename.split('-')[0]
    seed_string = dataset + spkr_id
    seed=np.sum([(ord(i)) for i in seed_string]) 
    print(spkr_id, seed_string, seed)   
    return seed

if __name__ == "__main__":
    #Parse args    
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_dir',type=str,default='../data/libri_test_enrolls_anon')
    #parser.add_argument('--data_dir',type=str,default='./testing_wav')
    parser.add_argument('--anon_suffix',type=str,default='_anon')
    parser.add_argument('--n_coeffs',type=int,default=20)
    parser.add_argument('--mc_coeff_min',type=float,default=0.5)
    parser.add_argument('--mc_coeff_max',type=float,default=0.9)
    parser.add_argument('--winLengthinms',type=int,default=20)
    parser.add_argument('--shiftLengthinms',type=int,default=10)
    parser.add_argument('--subset',type=str,default='vctk_dev_enrolls')
    parser.add_argument('--seed',type=int,default=0)
    config = parser.parse_args()
    
    #Load protocol file
    list_name= config.data_dir + '/wav.scp'
    list_files = np.genfromtxt(list_name,dtype='U')
    
    config.data_dir = config.data_dir+config.anon_suffix
    for n in range(1):
        for idx,file in enumerate(list_files):   
            print(str(idx+1),'/',len(list_files))
            random.seed(get_seed_from_string(config.subset, file[0]))
            rand_mc_coeff = random.uniform(config.mc_coeff_min,config.mc_coeff_max)
            anonym(n,file, output_dir=config.data_dir+'/wav/'+file[0]+'/', winLengthinms=config.winLengthinms, shiftLengthinms=config.shiftLengthinms, lp_order=config.n_coeffs, mcadams=rand_mc_coeff)
      