import os
import numpy as np
import argparse
import re

if __name__ == "__main__":
    #Parse args    
    parser = argparse.ArgumentParser()
    parser.add_argument('--results',type=str,default=' ')
    config = parser.parse_args()
    path = config.results

    eer_dev_o = 'Weighted average EER dev orig:'
    eer_test_o = 'Weighted average EER test orig:'
    eer_dev_a = 'Weighted average EER dev anon:'
    eer_test_a = 'Weighted average EER test anon:'

    wer_dev_o = 'Average WER dev orig:'
    wer_test_o = 'Average WER test orig:'
    wer_dev_a = 'Average WER dev anon:'
    wer_test_a = 'Average WER test anon:'

    f0_dev = 'Weighted average pitch correlation dev:'
    f0_test = 'Weighted average pitch correlation test:'

    gvd_dev = 'Weighted average gain of voice distinctiveness dev:'
    gvd_test = 'Weighted average gain of voice distinctiveness test:'

    regexs = [
        (re.compile(r'ASV-libri_dev_enrolls-libri_dev_trials_[fm]  EER: (\S+)'), eer_dev_o, 0.25),
        (re.compile(r'ASV-vctk_dev_enrolls-vctk_dev_trials_[fm]  EER: (\S+)'), eer_dev_o, 0.20),
        (re.compile(r'ASV-vctk_dev_enrolls-vctk_dev_trials_[fm]_common  EER: (\S+)'), eer_dev_o, 0.05),
        
        (re.compile(r'ASV-libri_test_enrolls-libri_test_trials_[fm]  EER: (\S+)'), eer_test_o, 0.25),
        (re.compile(r'ASV-vctk_test_enrolls-vctk_test_trials_[fm]  EER: (\S+)'), eer_test_o, 0.20),
        (re.compile(r'ASV-vctk_test_enrolls-vctk_test_trials_[fm]_common  EER: (\S+)'), eer_test_o, 0.05),

        (re.compile(r'ASV-libri_dev_enrolls_anon-libri_dev_trials_[fm]_anon  EER: (\S+)'), eer_dev_a, 0.25),
        (re.compile(r'ASV-vctk_dev_enrolls_anon-vctk_dev_trials_[fm]_anon  EER: (\S+)'), eer_dev_a, 0.20),
        (re.compile(r'ASV-vctk_dev_enrolls_anon-vctk_dev_trials_[fm]_common_anon  EER: (\S+)'), eer_dev_a, 0.05),
        
        (re.compile(r'ASV-libri_test_enrolls_anon-libri_test_trials_[fm]_anon  EER: (\S+)'), eer_test_a, 0.25),
        (re.compile(r'ASV-vctk_test_enrolls_anon-vctk_test_trials_[fm]_anon  EER: (\S+)'), eer_test_a, 0.20),
        (re.compile(r'ASV-vctk_test_enrolls_anon-vctk_test_trials_[fm]_common_anon  EER: (\S+)'), eer_test_a, 0.05),

        (re.compile(r'ASR-libri_dev_asr  *WER (\S+) .*'), wer_dev_o, 0.50),
        (re.compile(r'ASR-vctk_dev_asr  *WER (\S+) .*'), wer_dev_o, 0.50),
        
        (re.compile(r'ASR-libri_test_asr  *WER (\S+) .*'), wer_test_o, 0.50),
        (re.compile(r'ASR-vctk_test_asr  *WER (\S+) .*'), wer_test_o, 0.50),
        
        (re.compile(r'ASR-libri_dev_asr_anon  *WER (\S+) .*'), wer_dev_a, 0.50),
        (re.compile(r'ASR-vctk_dev_asr_anon  *WER (\S+) .*'), wer_dev_a, 0.50),
        
        (re.compile(r'ASR-libri_test_asr_anon  *WER (\S+) .*'), wer_test_a, 0.50),
        (re.compile(r'ASR-vctk_test_asr_anon  *WER (\S+) .*'), wer_test_a, 0.50),
        
        (re.compile(r'libri_dev_trials_[fm]  Pitch_correlation: mean=(\S+) .*'), f0_dev, 0.25),
        (re.compile(r'vctk_dev_trials_[fm]  Pitch_correlation: mean=(\S+) .*'), f0_dev, 0.20),
        (re.compile(r'vctk_dev_trials_[fm]_common  Pitch_correlation: mean=(\S+) .*'), f0_dev, 0.05),
        
        (re.compile(r'libri_test_trials_[fm]  Pitch_correlation: mean=(\S+) .*'), f0_test, 0.25),
        (re.compile(r'vctk_test_trials_[fm]  Pitch_correlation: mean=(\S+) .*'), f0_test, 0.20),
        (re.compile(r'vctk_test_trials_[fm]_common  Pitch_correlation: mean=(\S+) .*'), f0_test, 0.05),
        
        (re.compile(r'libri_dev_trials_[fm]  Gain of voice distinctiveness : (\S+)'), gvd_dev, 0.25),
        (re.compile(r'vctk_dev_trials_[fm]  Gain of voice distinctiveness : (\S+)'), gvd_dev, 0.20),
        (re.compile(r'vctk_dev_trials_[fm]_common  Gain of voice distinctiveness : (\S+)'), gvd_dev, 0.05),
        
        (re.compile(r'libri_test_trials_[fm]  Gain of voice distinctiveness : (\S+)'), gvd_test, 0.25),
        (re.compile(r'vctk_test_trials_[fm]  Gain of voice distinctiveness : (\S+)'), gvd_test, 0.20),
        (re.compile(r'vctk_test_trials_[fm]_common  Gain of voice distinctiveness : (\S+)'), gvd_test, 0.05),
    ]

    assert os.path.isfile(path), f'File {path} does not exist'
    aver = { eer_dev_o: 0.0,
             eer_test_o: 0.0, 
             eer_dev_a: 0.0, 
             eer_test_a: 0.0,
             wer_dev_o: 0.0, 
             wer_test_o: 0.0, 
             wer_dev_a: 0.0,
             wer_test_a: 0.0,
             f0_dev: 0.0, f0_test: 0.0, 
             gvd_dev: 0.0, gvd_test: 0.0}
    with open(path) as stream:
        for line in stream:
            line = line.strip()
            if len(line) == 0:
                continue
            line = line.replace('%','')
            for regex, key, wght in regexs:
                match = regex.match(line)
                if match is None:
                    continue     
                print(line)
                value = float(match.group(1))
                # print(value, wght)
                aver[key] += wght * value
                break
    file = open(path, 'a+')
    for key in aver:
        str_out = str(key) + ' ' + str("{:.3f}".format(aver[key]) + '\n')
        print(key, str("{:.3f}".format(aver[key])))
        file.write(str_out)
    file.close()

     
    print('Done')