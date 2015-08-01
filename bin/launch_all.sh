#!/bin/bash
unset HUE_BRIDGE_IP
unset HUE_BRIDGE_USERNAME

###############################################################################
# Initial Values for Lights
###############################################################################
export INIT_SAT=254
export INIT_BRI=127
export INIT_HUE=49500


###############################################################################
# Timing and Concurrency
###############################################################################
# Spread out spawning of threads:
# TODO: Move the use of this down to the wakeup iteration.
export SPREAD_SLEEP=0.0

# Spread out individual threads' loops:
export BETWEEN_SLEEP=0.0

# Determine how we handle concurrency -- threads vs. async I/O.
export THREADS=1
export MAX_CONNECTS=3


###############################################################################
# Visual Effects
###############################################################################
# Whether to use background sweep thread for saw-tooth pattern on hue:
export USE_SWEEP=0

# Which effects to apply to which components:
export HUE_FUNC=none
export SAT_FUNC=none
export BRI_FUNC=perlin

# How rapid the effects move (unrelated to speed of light updates):
export TIMESCALE_H=0.2
export TIMESCALE_S=1.0
export TIMESCALE_B=2.0
# TODO: Allow scaling X component for Perlin function as well...

# How long an individual change takes to apply (in seconds, at 1/10th sec
# precision):
export TRANSITION=0.4


###############################################################################
# Color Palette
###############################################################################
export MIN_HUE=48000
export MAX_HUE=51000
export MIN_SAT=212
export MAX_SAT=254
export MIN_BRI=63
export MAX_BRI=191


###############################################################################
# Simulation Duration
###############################################################################
# Run for a fixed number of iterations, or until we're killed (0):
export ITERATIONS=0


###############################################################################
# Debugging
###############################################################################
# Forcibly disable Ruby GC:
export SKIP_GC=1

# Whether or not to show success information.
export VERBOSE=0


###############################################################################
# Lighting Setups to Use
###############################################################################
export CONFIGS=(
  Bridge-01
  Bridge-02
  Bridge-03
  Bridge-04
)


###############################################################################
HANDLER='(kill -HUP $JOB1; sleep 1; kill -HUP $JOB2; sleep 1; kill -HUP $JOB3; sleep 1;  kill -HUP $JOB4; sleep 1) 2>/dev/null'
trap "$HANDLER" EXIT
trap "$HANDLER" QUIT
trap "$HANDLER" KILL

{ ./bin/go_nuts.rb ${CONFIGS[0]} & }
export JOB1=$!
{ ./bin/go_nuts.rb ${CONFIGS[1]} & }
export JOB2=$!
{ ./bin/go_nuts.rb ${CONFIGS[2]} & }
export JOB3=$!
{ ./bin/go_nuts.rb ${CONFIGS[3]} & }
export JOB4=$!

if [[ $ITERATIONS == 0 ]]; then
  echo "Sleeping while $JOB1, $JOB2, and $JOB3 run..."
  sleep 120

  echo
  echo "Cleaning up."
  kill -HUP $JOB1
  sleep 1
  kill -HUP $JOB2
  sleep 1
  kill -HUP $JOB3
  sleep 1
  kill -HUP $JOB4
  sleep 1
else
  wait
fi
