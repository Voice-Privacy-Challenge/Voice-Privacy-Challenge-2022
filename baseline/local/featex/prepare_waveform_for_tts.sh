#!/bin/bash
# --- use sv56 to normalize waveform amplitude
# Before use, please specify SOX and SV56
# Usage: sh prepare_waveform_for_tts.sh input_wav output_wav sample_rate

# level of normalization
LEV=26

# path to sox and sv56demo
SOX=sox
SV56=sv56demo

# input file path
file_name=$1

# output file path
OUTPUT=$2

# sampling rate
sample_rate=$3

if ! type "${SOX}" &> /dev/null; then
    echo "${SOX} not in path"
    exit 1;
fi

if ! type "${SV56}" &> /dev/null; then
    echo "${SV56} not in path"
    exit 1;
fi

if [ -e ${file_name} ];
then
    # basename
    basename=`basename ${file_name} .wav`
    # input file name
    INPUT=${file_name}

    # down-sampled wav
    DOWNSPWAV=${OUTPUT}.down.wav
    # raw data name
    RAWORIG=${OUTPUT}.raw
    # normed raw data name
    RAWNORM=${OUTPUT}.raw.norm
    # 16bit wav
    BITS16=${OUTPUT}.16bit.wav
        
    SAMP=`${SOX} --i -r ${INPUT}`
    BITS=`${SOX} --i -b ${INPUT}`

    if [ ${SAMP} -ne ${sample_rate} ] || [ ${BITS} -ne 16 ];
    then
	${SOX} ${INPUT} -b 16 ${DOWNSPWAV} rate -I ${sample_rate}
	INPUT=${DOWNSPWAV}
    fi

    SAMP=`${SOX} --i -r ${INPUT}`
    BITS=`${SOX} --i -b ${INPUT}`
	
    # make sure input is 16bits int
    if [ ${BITS} -ne 16 ] || [ ${SAMP} -ne ${sample_rate} ] ;
    then
	echo "${file_name} is not 16 bits or ${sample_rate} Hz"
	exit 1;
    else
	${SOX} ${INPUT} ${RAWORIG}
    fi

    # norm the waveform
    ${SV56} -q -sf ${SAMP} -lev -${LEV} ${RAWORIG} ${RAWNORM} > /dev/null 2>&1

    # convert
    ${SOX} -t raw -b 16 -e signed -c 1 -r ${SAMP} ${RAWNORM} ${OUTPUT}

    rm ${RAWNORM}
    rm ${RAWORIG}
    if [ -e ${DOWNSPWAV} ];
    then
	rm ${DOWNSPWAV}
    fi
else
    echo "not found ${file_name}"
    exit 1;
fi

