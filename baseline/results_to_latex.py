#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: Jose Patino
Audio Security and Privacy Group, EURECOM

This scripts parses the output of the results files of the the baseline systems released by the organisers of the VoicePrivacy 2020 Challenge.
Its use is as follows:
python results_to_latex.py RESULTS_file

Latex files are generated in a latex_table/ folder at the same root folder as the RESULTS_file for ASV/ASR and dev/test combinations
"""

import sys,os

def parse_scores_new(scores_file):  
    
    with open(scores_file) as f:
        file_content = f.readlines()
    
    #Parameters for ASV table
    header_ASV=r'\textbf{\#} & \textbf{Data set} & \textbf{Enroll} & \textbf{Trials} & \textbf{Gender} & \textbf{EER, \%} & \textbf{minCllr} & \textbf{Cllr} \\ \hline'+'\n'
    nr_cols_ASV=8
    width_ASV=1
    line_jump_ASV=4
    
    #Parameters for ASR table
    header_ASR=r'\textbf{\#} & \textbf{Data set} & \textbf{Data} & \textbf{WER, \%}, small & \textbf{WER, \%, large} \\ \hline'+'\n'
    nr_cols_ASR=5
    width_ASR=0.7
    line_jump_ASR=3
    
    #Table for dev ASV results
    ASV_table_dev = get_table(file_content,'ASV','dev',header_ASV,nr_cols_ASV,width_ASV,line_jump_ASV)
    ASV_table_test = get_table(file_content,'ASV','test',header_ASV,nr_cols_ASV,width_ASV,line_jump_ASV)
    
    #Table for dev ASR results    
    ASR_table_dev = get_table(file_content,'ASR','dev',header_ASR,nr_cols_ASR,width_ASR,line_jump_ASR)
    ASR_table_test = get_table(file_content,'ASR','test',header_ASR,nr_cols_ASR,width_ASR,line_jump_ASR)
    
    #ASR_table_dev = get_table_asr(file_content,'dev')
    #ASR_table_test = get_table_asr(file_content,'test')
    
    #Print tables (12 is the size of an empty table)
    if len(ASV_table_dev)>12: print_table(scores_file,ASV_table_dev,'ASV','dev')
    if len(ASV_table_test)>12: print_table(scores_file,ASV_table_test,'ASV','test')
    if len(ASR_table_dev)>12: print_table(scores_file,ASR_table_dev,'ASR','dev')
    if len(ASR_table_test)>12: print_table(scores_file,ASR_table_test,'ASR','test')

        
def print_table(scores_file,table,task,partition):    
    path_latex_results_folder = os.path.dirname(os.path.abspath(scores_file))+'/latex_tables'
    if not os.path.isdir(path_latex_results_folder): os.makedirs(path_latex_results_folder)
    path_latex_file = path_latex_results_folder + '/' + scores_file +'.' + task + '_' + partition + '.latex'
    if os.path.isfile(path_latex_file): os.remove(path_latex_file)
    outf = open(path_latex_file,"a")    
    outf.writelines(table)
    outf.close()
    
    
def get_table(scores, task, partition, header, nr_cols,width,line_jump):
    table_content = initialise_table(nr_cols,width)
    #Define headers
    table_content.append(header)
    #Parse content
    counter = 1
    scores_content = []
    for idx in range(len(scores)):
        score = scores[idx].strip()
        if (score[0:3]==task):
            if partition==score.split('-')[1].split('_')[1]:
                if task=='ASV':
                    str_content = generate_asv_line(counter,score.strip(),scores[idx+1:idx+line_jump])
                elif task=='ASR':
                    str_content = generate_asr_line(counter,score.strip(),scores[idx+1:idx+line_jump])
                #future work, add separators across datasets 
                counter+=1
                scores_content.append(str_content)                
    table_content.extend(scores_content)
    table_content = finalise_table(table_content,task,partition)
    return table_content    

def initialise_table(nr_cols,width):
    table_content = []
    table_content.append(r'\usepackage{graphicx}'+'\n')
    table_content.append(r'\begin{table}[]'+'\n')
    table_content.append(r'\centering'+'\n')
    table_content.append(r'\resizebox{'+str(width)+r'\textwidth}{!}{'+'\n')
    table_content.append(r'\begin{tabular}{'+ 'c'.join(['|']*(nr_cols+1)) +'}'+'\n')    
    table_content.append(r'\hline'+'\n')       
    return table_content

def finalise_table(table_content,task,partition):
    if partition=='dev': partition='development'
    table_content.append(r'\end{tabular}'+'\n')
    table_content.append('}'+'\n')
    table_content.append(r'\caption{'+task+' results for '+partition+' data (o-original, a-anonymized speech).}'+'\n')
    table_content.append(r'\label{tab:'+task+'-'+partition+'}'+'\n')
    table_content.append(r'\end{table}'+'\n')    
    return table_content

def generate_asv_line(counter, data_info, numbers):
    dataset = data_info.split('-')[1].split('_')[0] + '\_' + data_info.split('-')[1].split('_')[1]
    dataset = get_extra_dataset(dataset,data_info)
    enroll = get_o_or_a(data_info.split('-')[1])
    trials = get_o_or_a(data_info.split('-')[2])
    gender = data_info.split('-')[2].split('_')[3]
    eer = numbers[0].split(':')[1].strip()[:-1]
    min_cllr = numbers[1].split(':')[1].split('/')[0].strip()
    cllr = numbers[1].split(':')[1].split('/')[1].strip()
    eer_line = ' & '.join([str(counter),dataset,enroll,trials,gender,eer,min_cllr,cllr]) + '\\\\ \hline'+'\n'
    return eer_line

def generate_asr_line(counter,data_info,numbers):
    dataset = data_info.split('-')[1].split('_')[0] + '\_' + data_info.split('-')[1].split('_')[1]
    data = get_o_or_a(data_info.split('-')[1])
    wer_small = numbers[0].strip().split(' ')[1]
    wer_large = numbers[1].strip().split(' ')[1]
    wer_line = ' & '.join([str(counter), dataset, data, wer_small, wer_large]) + '\\\\ \hline'+'\n'
    return wer_line

def get_extra_dataset(dataset,data_info):
    if (data_info.split('-')[1].split('_')[0]=='vctk') & (len(data_info.split('-')[2].split('_'))>4):
        if data_info.split('-')[2].split('_')[4]=='common':
            dataset = dataset + '\_com'
        else:
            dataset = dataset + '\_dif'            
    return dataset

def get_o_or_a(data_info):
    # o for original, a for anonymised data
    if data_info.split('_')[-1]=='anon':
        x='a'
    else:
        x='o'
    return x

if __name__ == "__main__":
    #  the scores file is expected as an input:
    #  python results_to_latex.py my_scores
    scores_file = sys.argv[1]
    #scores_file = 'RESULTS_xvectors'
    parse_scores_new(scores_file)
    