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

def parse_scores(scores_file):  
    
    with open(scores_file) as f:
        file_content = f.readlines()
    
    #Parameters for ASV table
    header_ASV=r'\# & \textbf{Data set} & \textbf{Enroll} & \textbf{Trials} & \textbf{Gender} & \textbf{EER, \%} & \textbf{$\text{C}_{llr}^{min}$} & \textbf{$\text{C}_{llr}$} \\ \hline\hline'+'\n'
    nr_cols_ASV=8
    width_ASV=1
    line_jump_ASV=4
    
    #Parameters for ASR table
    header_ASR=r'\# & \textbf{Data set} & \textbf{Data} & \textbf{WER, \%}, small & \textbf{WER, \%, large} \\ \hline\hline'+'\n'
    nr_cols_ASR=5
    width_ASR=0.7
    line_jump_ASR=3
    
    #Tables for ASV results
    ASV_table_dev = get_table(file_content,'ASV','dev',header_ASV,nr_cols_ASV,width_ASV,line_jump_ASV)
    ASV_table_test = get_table(file_content,'ASV','test',header_ASV,nr_cols_ASV,width_ASV,line_jump_ASV)
    
    #Tables for ASR results    
    ASR_table_dev = get_table(file_content,'ASR','dev',header_ASR,nr_cols_ASR,width_ASR,line_jump_ASR)
    ASR_table_test = get_table(file_content,'ASR','test',header_ASR,nr_cols_ASR,width_ASR,line_jump_ASR)
    
    #Combine tables
    header_combined_ASV_table = r'\# & \textbf{Dev. set} & \textbf{EER, \%} & \textbf{$\text{C}_{llr}^{min}$} & \textbf{$\text{C}_{llr}$} & \textbf{Enroll} & \textbf{Trial} & \textbf{Gen} & \textbf{Test set} & \textbf{EER, \%} & \textbf{$\text{C}_{llr}^{min}$} & \textbf{$\text{C}_{llr}$}\\ \hline\hline'+'\n'
    nr_cols_combined_ASV=12
    width_combined_ASV=1
    combined_ASV = combine_tables(ASV_table_dev,ASV_table_test,'ASV',header_combined_ASV_table, nr_cols_combined_ASV,width_combined_ASV)
    
    header_combined_ASR_table = r'\multirow{2}{*}{\#} & \multirow{2}{*}{\textbf{Dev. set}} & \multicolumn{2}{c|}{\textbf{WER, \%}} & \multirow{2}{*}{\textbf{Data}} & \multirow{2}{*}{\textbf{Test set}} & \multicolumn{2}{c|}{\textbf{WER, \%}} \\ \cline{3-4} \cline{7-8}  &  & \textbf{$\text{LM}_{s}$} & \textbf{$\text{LM}_{l}$} &  &  & \textbf{$\text{LM}_{s}$} & \textbf{$\text{LM}_{l}$} \\ \hline\hline'+'\n'
    #there is a little typo associated to this header which I haven't figured out yet relating to the use of multicolumn  and || in parallel. I don't know how to solve this in latex
    nr_cols_combined_ASR=8
    width_combined_ASR=0.7
    combined_ASR = combine_tables(ASR_table_dev,ASR_table_test,'ASR',header_combined_ASR_table, nr_cols_combined_ASR,width_combined_ASR)
    
    #Print tables 
    print_table(scores_file,ASV_table_dev,'ASV','dev')
    print_table(scores_file,ASV_table_test,'ASV','test')
    print_table(scores_file,ASR_table_dev,'ASR','dev')
    print_table(scores_file,ASR_table_test,'ASR','test')
    print_table(scores_file,combined_ASV,'ASV','')
    print_table(scores_file,combined_ASR,'ASR','')

def print_table(scores_file,table,task,partition): 
    if len(table)>12: #(12 is the size of an empty table)
        path_latex_results_folder = os.path.dirname(os.path.abspath(scores_file))+'/latex_tables'
        if not os.path.isdir(path_latex_results_folder): os.makedirs(path_latex_results_folder)
        if partition=='': partition ='combined'
        path_latex_file = path_latex_results_folder + '/' + scores_file +'.' + task + '_' + partition + '.latex'          
        if os.path.isfile(path_latex_file): os.remove(path_latex_file)
        outf = open(path_latex_file,"a")    
        outf.writelines(table)
        outf.close()
  
def combine_tables(table1,table2,task,header,nr_cols,width):
    indeces ={'ASV':[26,33],
              'ASR':[25,27]}
    if (len(table1)>12) & (len(table2)>12) & (len(table1)==len(table2)): #(12 is the size of an empty table)
        combined_table=initialise_table(nr_cols,width,header)
        content_table1 = table1[8:-5]
        content_table2 = table2[8:-5]
        for line1, line2 in zip(content_table1,content_table2):
            if task=='ASV':
                new_line = get_combined_line_asv(line1,line2)
            elif task=='ASR':
                new_line = get_combined_line_asr(line1,line2)
            combined_table.append(new_line)
        combined_table = finalise_table(combined_table,task,'')
        combined_table[5] =combined_table[5][:indeces[task][0]]+'|'+combined_table[5][indeces[task][0]:indeces[task][1]]+'|'+combined_table[5][indeces[task][1]:]       
    return combined_table

def get_combined_line_asv(line1, line2):
    counter1,dataset1,enroll1,trial1,gen1,eer1,mincllr1,cllr1 = line1.split(' & ')
    counter2,dataset2,enroll2,trial2,gen2,eer2,mincllr2,cllr2 = line2.split(' & ')
    new_line = ' & '.join([counter1,dataset1,eer1,mincllr1,cllr1.split('\\')[0],enroll1,trial1,gen1,
                                  dataset2, eer2, mincllr2,cllr2])
    return new_line

def get_combined_line_asr(line1, line2):
    counter1,dataset1,data1,wer1_s,wer1_l = line1.split(' & ')
    counter2,dataset2,data2,wer2_s,wer2_l = line2.split(' & ')
    new_line = ' & '.join([counter1,dataset1,wer1_s,wer1_l.split('\\')[0],data1,dataset2,wer2_s,wer2_l])
    return new_line
    
def get_table(scores, task, partition, header, nr_cols,width,line_jump):
    table_content = initialise_table(nr_cols,width,header)
    #Parse content
    counter = 1
    scores_content = []
    for idx in range(len(scores)):
        score = scores[idx].strip()
        if (score[0:3]==task):
            if partition==score.split('-')[1].split('_')[1]:
                if task=='ASV':
                    str_content = generate_asv_line(score.strip(),scores[idx+1:idx+line_jump])
                elif task=='ASR':
                    str_content = generate_asr_line(score.strip(),scores[idx+1:idx+line_jump])
                counter+=1
                scores_content.append(str_content)
    scores_content = sort_table(scores_content,task)
    scores_content = enhance_table(scores_content,line_jump)                
    table_content.extend(scores_content)
    table_content = finalise_table(table_content,task,partition)
    return table_content    

def sort_table(table,task):
    if task=='ASV':
        idxs=[0, 3]
    else:
        idxs=[0, 0]
    sorted_table=sorted(table, key = lambda x: (x.split(' & ')[idxs[0]], x.split(' & ')[idxs[1]]))       
    sorted_table = [str(t[0]+1)+' & '+t[1] for t in enumerate(sorted_table)]
    return sorted_table

def enhance_table(table,line_jump):
    enhanced_table = [x + ('\hline ' if (((i+1)%(line_jump-1)==0) & ((i+1)<len(table))) else '') for i, x in enumerate(table)]
    return enhanced_table

def initialise_table(nr_cols,width,header):
    table_content = []
    table_content.append(r'%\usepackage{graphicx}'+'\n')
    table_content.append(r'%\usepackage{multirow}'+'\n')
    table_content.append(r'\begin{table}[]'+'\n')
    table_content.append(r'\centering'+'\n')
    table_content.append(r'\resizebox{'+str(width)+r'\textwidth}{!}{'+'\n')
    table_content.append(r'\begin{tabular}{'+ 'c'.join(['|']*(nr_cols+1)) +'}'+'\n')    
    table_content.append(r'\hline'+'\n')
    table_content.append(header)       
    return table_content

def finalise_table(table_content,task,partition):
    if partition=='dev': partition='development'
    table_content.append(r'\end{tabular}'+'\n')
    table_content.append('}'+'\n')
    if partition=='':
        table_content.append(r'\caption{'+task+' results for both development and test partitions (o-original, a-anonymized speech).}'+'\n')
    else:
        table_content.append(r'\caption{'+task+' results for '+partition+' data (o-original, a-anonymized speech).}'+'\n')
    if partition=='': partition='combined'
    table_content.append(r'\label{tab:'+task+'-'+partition+'}'+'\n')
    table_content.append(r'\end{table}'+'\n')    
    return table_content

def generate_asv_line(data_info, numbers):
    dataset = data_info.split('-')[1].split('_')[0] + '\_' + data_info.split('-')[1].split('_')[1]
    dataset = get_extra_dataset(dataset,data_info)
    enroll = get_o_or_a(data_info.split('-')[1])
    trials = get_o_or_a(data_info.split('-')[2])
    gender = data_info.split('-')[2].split('_')[3]
    eer = numbers[0].split(':')[1].strip()[:-1]
    min_cllr = numbers[1].split(':')[1].split('/')[0].strip()
    cllr = numbers[1].split(':')[1].split('/')[1].strip()
    eer_line = ' & '.join([dataset,enroll,trials,gender,"{:.3f}".format(float(eer)),"{:.3f}".format(float(min_cllr)),"{:.3f}".format(float(cllr))]) + '\\\\ \hline'+'\n'
    return eer_line

def generate_asr_line(data_info,numbers):
    dataset = data_info.split('-')[1].split('_')[0] + '\_' + data_info.split('-')[1].split('_')[1]
    data = get_o_or_a(data_info.split('-')[1])
    wer_small = numbers[0].strip().split(' ')[1]
    wer_large = numbers[1].strip().split(' ')[1]
    wer_line = ' & '.join([dataset, data, "{:.2f}".format(float(wer_small)), "{:.2f}".format(float(wer_large))]) + '\\\\ \hline '+'\n'
    return wer_line

def get_extra_dataset(dataset,data_info):
    if (data_info.split('-')[1].split('_')[0]=='vctk'):
        if (len(data_info.split('-')[2].split('_'))>4):
            if data_info.split('-')[2].split('_')[4]=='common':
                dataset = dataset + '\_com'
            else:
                dataset = dataset + '\_dif'
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
    #scores_file = 'RESULTS_baseline'
    parse_scores(scores_file)
    
