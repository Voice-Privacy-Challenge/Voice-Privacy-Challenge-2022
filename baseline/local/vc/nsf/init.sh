#!/bin/sh

. path.sh

# PATH to the pyTools
export TEMP_CURRENNT_PROJECT_PYTOOLS_PATH=${nii_dir}/pyTools

# PATH to currennt
export TEMP_CURRENNT_PROJECT_CURRENNT_PATH=${nii_dir}/CURRENNT_codes/build/currennt

# PATH to SOX (http://sox.sourceforge.net/sox.html)
export TEMP_CURRENNT_PROJECT_SOX_PATH=/usr/bin/sox

# PATH to SV56 (a software to normalize waveform amplitude.
#  https://www.itu.int/rec/T-REC-P.56
#  This software is not necessary, I used it because it is available in our lab.
#  You can use other tools to normalize the waveforms before put them into this project.
#  Then, you can set TEMP_CURRENNT_PROJECT_SV56_PATH=None)
#export TEMP_CURRENNT_PROJECT_SV56_PATH=/home/smg/wang/WORK/WORK/TOOL/local/bin/sv56demo
export TEMP_CURRENNT_PROJECT_SV56_PATH=None

export localpath=`pwd`/local/vc/nsf

# Add pyTools to PYTHONPATH
export PYTHONPATH=${PYTHONPATH}:${TEMP_CURRENNT_PROJECT_PYTOOLS_PATH}:${localpath}
