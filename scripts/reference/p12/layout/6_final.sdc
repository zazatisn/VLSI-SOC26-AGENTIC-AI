###############################################################################
# Created by write_sdc
###############################################################################
current_design registered_adder_8bit
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clock -period 1.5000 [get_ports {clk}]
set_propagated_clock [get_clocks {core_clock}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[4]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[5]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[6]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {a[7]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[4]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[5]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[6]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {b[7]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {reset}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[0]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[1]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[2]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[3]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[4]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[5]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[6]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {sum[7]}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
