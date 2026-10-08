###############################################################################
# Created by write_sdc
###############################################################################
current_design uart_tx
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clock -period 2.0000 [get_ports {clk}]
set_propagated_clock [get_clocks {core_clock}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[4]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[5]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[6]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {data_in[7]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {reset}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {start}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {busy}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {tx}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
