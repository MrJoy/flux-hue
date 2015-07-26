#!/bin/bash
unset HUE_BRIDGE_IP
unset HUE_BRIDGE_USERNAME

# Min/max brightness for dimmable lights:
export MIN_BRI=31
export MAX_BRI=127

# Saturation for color lights:
export HUE_SATURATION=95

# Run indefinitely, don't let GC muck with shit.
export ITERATIONS=0
export SKIP_GC=1

# Determine how we handle concurrency -- threads vs. async I/O.
export THREADS=1
export MAX_CONNECTS=6

# Whether or not to show success information.
export VERBOSE=0

###############################################################################
trap '(kill -HUP $JOB1; sleep 0.5; kill -HUP $JOB2; sleep 0.5; kill -HUP $JOB3) 2>/dev/null' EXIT
trap '(kill -HUP $JOB1; sleep 0.5; kill -HUP $JOB2; sleep 0.5; kill -HUP $JOB3) 2>/dev/null' QUIT
trap '(kill -HUP $JOB1; sleep 0.5; kill -HUP $JOB2; sleep 0.5; kill -HUP $JOB3) 2>/dev/null' KILL

{ ./bin/go_nuts.rb Bridge-01 & }
JOB1=$!
{ ./bin/go_nuts.rb Bridge-02 & }
JOB2=$!
{ ./bin/go_nuts.rb Bridge-03 & }
JOB3=$!

echo "Sleeping while $JOB1, $JOB2, and $JOB3 run..."
sleep 30

echo
echo "Cleaning up."
(
  kill -HUP $JOB1
  sleep 0.5
  kill -HUP $JOB2
  sleep 0.5
  kill -HUP $JOB3
) 2>/dev/null
