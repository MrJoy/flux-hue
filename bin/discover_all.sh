#!/bin/bash
IFS=$'\n\t'
TIMEOUT=${1:-5}

gssdp-discover --timeout=${TIMEOUT} |
  fgrep Location: |
  fgrep ':80/description.xml' |
  awk '{ print $2 }' |
  cut -d: -f2 |
  cut -d/ -f3 |
  sort |
  uniq
