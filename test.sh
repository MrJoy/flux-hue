#!/bin/bash

WINDOW=8192
SPAN=32
for FREQ in 44100 96k; do
  FNAME="test/results/${FREQ}"
  if [ -e "${FNAME}" ]; then
    rm "${FNAME}"
  fi
  touch "${FNAME}"
  for HZ in 125 250 500 1000 2000 4000 8000; do
    for PARAMS in 0 1; do
      if [ $PARAMS == 0 ]; then
        OPTS="--skip-low --skip-high"
        echo "${HZ}Hz/${FREQ}Hz, Window=${WINDOW}, Unfiltered:" >> "${FNAME}"
      else
        OPTS=""
        echo "${HZ}Hz/${FREQ}Hz, Window=${WINDOW}, Filtered:" >> "${FNAME}"
      fi
      time bin/sm-audio-processor --input-file=test/fixtures/Sin${HZ}Hz\@0dB24bit${FREQ}HzM.caf --window=${WINDOW} --span=${SPAN} $OPTS |
        grep 'INFO:' |
        grep -v 'Channel' |
        perl -pse 's/^.*?INFO: //g' >> "${FNAME}"
    done
  done
done
