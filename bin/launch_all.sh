#!/bin/bash
unset HUE_BRIDGE_IP
unset HUE_BRIDGE_USERNAME

# Min/max brightness for dimmable lights:
# export MIN_BRI=31
# export MAX_BRI=127

# (Initial) saturation for color lights:
export SATURATION=255

export TIMESCALE_H=2.0
export TIMESCALE_S=7.0
export TRANSITION=0.4

# Run indefinitely, don't let GC muck with shit.
export ITERATIONS=0
export SKIP_GC=1

# Determine how we handle concurrency -- threads vs. async I/O.
export THREADS=3
export MAX_CONNECTS=2
export OVERRAMP=0

# Whether or not to show success information.
export VERBOSE=0

export CONFIGS=(
  Bridge-01
  Bridge-02
  Bridge-03
)

###############################################################################
HANDLER='(kill -HUP $JOB1; sleep 1; kill -HUP $JOB2; sleep 1; kill -HUP $JOB3; sleep 1) 2>/dev/null'
trap "$HANDLER" EXIT
trap "$HANDLER" QUIT
trap "$HANDLER" KILL

{ ./bin/go_nuts.rb ${CONFIGS[0]} & }
export JOB1=$!
{ ./bin/go_nuts.rb ${CONFIGS[1]} & }
export JOB2=$!
{ ./bin/go_nuts.rb ${CONFIGS[2]} & }
export JOB3=$!

if [[ $ITERATIONS == 0 ]]; then
  echo "Sleeping while $JOB1, $JOB2, and $JOB3 run..."
  sleep 120

  echo
  echo "Cleaning up."
  # (
    kill -HUP $JOB1
    sleep 1
    kill -HUP $JOB2
    sleep 1
    kill -HUP $JOB3
    sleep 1
  # )
  echo "Done?"
else
  wait
fi
