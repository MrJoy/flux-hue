#!/bin/bash

# Min/max brightness for dimmable lights:
export MIN_BRI=0
export MAX_BRI=63

# Saturation for color lights:
export SAT=63

# Run indefinitely, don't let GC muck with shit.
export ITERATIONS=0
export SKIP_GC=1

HUE_BRIDGE_IP=192.168.2.8 ./bin/hue lights set 1 2 6 7 8 9 10 11 12 13 14 15 17 18 19 20 21 22 23 26 27 28 30 33 34 35 36 37 3 4 5 16 24 25 --state=on --sat=$SAT --bri=$MAX_BRI
HUE_BRIDGE_IP=192.168.2.45 ./bin/hue lights set 7 8 4 5 6 --state=on --sat=$SAT --bri=$MAX_BRI
HUE_BRIDGE_IP=192.168.2.46 ./bin/hue lights set 1 2 3 --state=on --sat=$SAT --bri=$MAX_BRI


{ HUE_BRIDGE_IP=192.168.2.8 COLOR_LIGHTS="1 2 6 7 8 9 10 11 12 13 14 15 17 18 19 20 21 22 23 26 27 28 30 33 34 35 36 37" DIMMABLE_LIGHTS="3 4 5 16 24 25" ./bin/go_nuts.rb & }
JOB1=$!
{ HUE_BRIDGE_IP=192.168.2.45 COLOR_LIGHTS="7 8" DIMMABLE_LIGHTS="4 5 6" ./bin/go_nuts.rb & }
JOB2=$!
{ HUE_BRIDGE_IP=192.168.2.46 COLOR_LIGHTS="1 2 3" DIMMABLE_LIGHTS="" ./bin/go_nuts.rb & }
JOB3=$!

echo "Sleeping while $JOB1, $JOB2, and $JOB3 run..."
sleep 30

echo
echo "Cleaning up."
kill -HUP $JOB1
sleep 0.5
kill -HUP $JOB2
sleep 0.5
kill -HUP $JOB3
