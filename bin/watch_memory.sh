#!/bin/bash

while [ 1 ]; do
  ps auxwww |
    grep rub[y] |
    grep go_nuts |
    awk '{ print $6 }' | perl -pse 's/\n/, /g' | perl -pse 's/, $//'
    echo
  sleep 1
done
