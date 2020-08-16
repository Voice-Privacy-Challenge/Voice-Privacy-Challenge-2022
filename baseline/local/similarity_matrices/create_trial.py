#!/usr/bin/python

import argparse
import numpy as np

def readMat(ar):
    fh = open(ar)
    x = []
    for line in fh.readlines():
        y = [str(value) for value in line.split()]
        x.append(y)
    fh.close()
    return x

def readList(ar):
    fh = open(ar)
    x = []
    for line in fh.readlines():
        y = [str(value) for value in line.split()]
        x.append((y[0]))
    fh.close()
    return x

if __name__=="__main__":

    parser = argparse.ArgumentParser(description='This computes the trial file given to list of segments and utt2spk')
    parser.add_argument('osp_segments_scp',help="Original speech segment list", type=str)
    parser.add_argument('asp_segments_scp',help="Anonymized speech segment list", type=str)
    parser.add_argument('name',help="name of the trial file",type=str)
    parser.add_argument('out_dir',help="output directory",type=str)
    parser.add_argument('utt2spk',help="utt2spk file", type=str)
    args = parser.parse_args()

    osp_segments_scp    = readList(args.osp_segments_scp)
    asp_segments_scp    = readList(args.asp_segments_scp)
    name                = args.name
    utt2spk             = readMat(args.utt2spk)
    out_dir             = args.out_dir

    #Dictionary from utt to spk
    D_utt2spk = dict()
    for i in range(len(utt2spk)):
        D_utt2spk[utt2spk[i][0]] = utt2spk[i][1]

    k = 0
    trial = []
    for i in range(len(osp_segments_scp)):
        for j in range(k,len(asp_segments_scp)):
            if osp_segments_scp[i] != asp_segments_scp[j]:
                trial.append([D_utt2spk[osp_segments_scp[i]], osp_segments_scp[i], D_utt2spk[asp_segments_scp[j]], asp_segments_scp[j]])
            
        k += 1

    trial = np.array(trial)
    segment_trial = trial[:,[1,3]]
    spk_trial = trial[:,[0,2]]
    np.savetxt(out_dir+"/segments_"+name+"_trial.txt", segment_trial, delimiter=" ", newline = "\n", fmt="%s")
    np.savetxt(out_dir+"/spk_"+name+"_trial.txt", spk_trial, delimiter=" ", newline = "\n", fmt="%s")
