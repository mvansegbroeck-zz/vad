#!/bin/bash

silfile=$1
samfile=$2
wffile=$3
export AURORACALC=aurora-front-end/qio
./tools/nr -fs 16000 -swapin 0 -swapout 0 -Length 20 -Ssilfile $silfile -i $samfile -o $wffile
