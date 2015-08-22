#!/bin/bash
###############################################################################
# Visual Effects
###############################################################################
# Whether to use background sweep thread for saw-tooth pattern on hue:
export USE_SWEEP=1
# Whether to actually run main lighting threads:
export USE_LIGHTS=1
# Whether or not to run the simulation:
export USE_SIM=1
# Whether or not to use Novation LaunchPad for controls:
export USE_INPUT=0


###############################################################################
# Debugging
###############################################################################
# Run for a fixed number of iterations, or until we're killed (0):
export ITERATIONS=0

# Forcibly disable Ruby GC:
export SKIP_GC=0

# Logging verbosity.  Valid values: DEBUG, INFO, WARN, ERROR.  Default is INFO.
export FLUX_LOGLEVEL=INFO

# Whether to run a profiler:
export PROFILE_RUN= # ruby-prof|memory_profiler

# If using ruby-prof, what mode to run it in:
export RUBY_PROF_MODE=allocations  # ALLOCATIONS, CPU_TIME, GC_RUNS, GC_TIME, MEMORY, PROCESS_TIME, WALL_TIME

# Dump various PNGs showing the results of given nodes in the DAG over time.
# This is VERY VERY memory intensize!  Don't try to use it for a long run!
export DEBUG_NODES= #perlin,stretched,shifted_0,shifted_1,shifted_2,shifted_3,spotlit,output


###############################################################################
./bin/simulate.rb
