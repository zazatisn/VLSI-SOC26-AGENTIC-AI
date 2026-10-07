#########################################################################
#                      OPENROAD FLOW CONFIGURATION                      #
#########################################################################

# Design name and target platform
export DESIGN_NAME = <DESIGN_NAME>
export PLATFORM    = <PLATFORM>

# Verilog source files
export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NAME)/*.v))

# Timing constraints file
export SDC_FILE = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NAME)/constraint.sdc

# Core area settings
export CORE_UTILIZATION  = <UTILIZATION_PERCENTAGE>
export CORE_ASPECT_RATIO = <ASPECT_RATIO_FLOAT>
export CORE_MARGIN       = <CORE_MARGIN_FLOAT>

# Placement and routing settings
export PLACE_PINS_ARGS 		    = -min_distance 4 -min_distance_in_tracks
export PLACE_DENSITY            = <PLACEMENT_DENSITY_FLOAT>
export ROUTING_LAYER_ADJUSTMENT = <ROUTING_LAYER_ADJUSTMENT_FLOAT>

# Synthesis optimization settings
export ABC_AREA               = <ABC_AREA_0_OR_1>
export RESYNTH_TIMING_RECOVER = <RESYNTH_TIMING_RECOVER_0_OR_1>

# Power optimization settings
export RECOVER_POWER = <RECOVER_POWER_PERCENTAGE>