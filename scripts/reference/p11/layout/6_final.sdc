###############################################################################
# Created by write_sdc
###############################################################################
current_design simple_8bit_counter
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clock -period 2.0000 [get_ports {clk}]
set_propagated_clock [get_clocks {core_clock}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {en}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {reset}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[0]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[1]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[2]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[3]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[4]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[5]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[6]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {count[7]}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
