#########################################################################
#                      OPENROAD FLOW CONFIGURATION                      #
#########################################################################

# Design name and target platform
export DESIGN_NAME = sync_fifo
export PLATFORM    = sky130hd

# Verilog source files
export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NAME)/*.v))

# Timing constraints file
export SDC_FILE = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NAME)/constraint.sdc

# Core area settings
export CORE_UTILIZATION  = 40
export CORE_ASPECT_RATIO = 1.0
export CORE_MARGIN       = 2.0

# Placement and routing settings
export PLACE_PINS_ARGS 		    = -min_distance 4 -min_distance_in_tracks
export PLACE_DENSITY            = 0.6
export ROUTING_LAYER_ADJUSTMENT = 0.5

# Synthesis optimization settings
export ABC_AREA               = 0
export RESYNTH_TIMING_RECOVER = 0

# Power optimization settings
export RECOVER_POWER = 0
