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
export USE_SWEEP=0
# Whether to actually run main lighting threads:
export USE_LIGHTS=0
# Whether or not to run the simulation:
export USE_SIM=0


###############################################################################
# Simulation Duration
###############################################################################
# Run for a fixed number of iterations, or until we're killed (0):
export ITERATIONS=0
export RUN_FOREVER=1


###############################################################################
# Debugging
###############################################################################
# Forcibly disable Ruby GC:
export SKIP_GC=0

# Whether or not to show success information.
export VERBOSE=0

# Whether to run a profiler:
export PROFILE_RUN= # ruby-prof|memory_profiler
# If using ruby-prof, what mode to run it in:
export RUBY_PROF_MODE=allocations  # ALLOCATIONS, CPU_TIME, GC_RUNS, GC_TIME, MEMORY, PROCESS_TIME, WALL_TIME

# Dump various PNGs showing the results of given nodes in the DAG over time.
# This is VERY VERY memory intensize!  Don't try to use it for a long run!
export DEBUG_NODES= #perlin,stretched,shifted_0,shifted_1,shifted_2,shifted_3,spotlit,output


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
