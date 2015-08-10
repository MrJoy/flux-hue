#!/bin/bash
unset HUE_BRIDGE_IP
unset HUE_BRIDGE_USERNAME

###############################################################################
# Timing and Concurrency
###############################################################################
# Spread out spawning of threads:
# export SPREAD_SLEEP=0.0

# Spread out individual threads' loops:
# export BETWEEN_SLEEP=0.0

# Determine how we handle concurrency -- threads vs. async I/O.
# export THREADS=1
export MAX_CONNECTS=3


###############################################################################
# Visual Effects
###############################################################################
# Whether to use background sweep thread for saw-tooth pattern on hue:
export USE_SWEEP=1

# Which effects to apply to which components:
export BRI_FUNC=perlin

# How rapid the effects move (unrelated to speed of light updates):
export PERLIN_SCALE_Y=4.0
# TODO: Allow scaling X component for Perlin function as well...

# How long an individual change takes to apply (in seconds, at 1/10th sec
# precision):
export TRANSITION=0.3


###############################################################################
# Color Palette
###############################################################################
# export MIN_HUE=48000
# export MAX_HUE=51000
export MIN_BRI=0.25
export MAX_BRI=0.75


###############################################################################
# Simulation Duration
###############################################################################
# Run for a fixed number of iterations, or until we're killed (0):
export ITERATIONS=50
export RUN_FOREVER=0


###############################################################################
# Debugging
###############################################################################
# Forcibly disable Ruby GC:
export SKIP_GC=0

# Whether or not to show success information.
export VERBOSE=0

# Whether to run the profiler and generate `results.html`:
export PROFILE_RUN=0

# Dump various PNGs showing the results of given nodes in the DAG over time:
export DEBUG_PERLIN=1
export DEBUG_CONTRAST=1
export DEBUG_RANGE=1


###############################################################################
HANDLER='kill -HUP $JOBPID 2>/dev/null'
trap "$HANDLER" EXIT
trap "$HANDLER" QUIT
trap "$HANDLER" KILL

{ ./bin/go_nuts.rb ${CONFIGS[0]} & }
export JOBPID=$!

if [[ $ITERATIONS != 0 ]]; then
  export RUN_FOREVER=1
fi


if [[ $RUN_FOREVER == 0 ]]; then
  echo "Sleeping while $JOBPID runs..."
  sleep 120

  echo
  echo "Cleaning up."
  kill -HUP $JOBPID
else
  if [[ $ITERATIONS != 0 ]]; then
    echo "Waiting for $JOBPID to finish..."
  else
    echo "Waiting for $JOBPID until you kill me..."
  fi
  wait
fi
