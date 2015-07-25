#!/bin/bash

while [ 1 ]; do
  ps auxwww |
    grep rub[y] |
    grep go_nuts |
    awk '{ print $6 }'
  sleep 1
done
