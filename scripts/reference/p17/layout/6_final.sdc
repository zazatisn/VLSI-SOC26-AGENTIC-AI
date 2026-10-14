###############################################################################
# Created by write_sdc
###############################################################################
current_design vga_lcd
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clock -period 5.0000 [get_ports {clk}]
set_propagated_clock [get_clocks {core_clock}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {enable}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[4]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[5]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_addr[6]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_wdata[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_wdata[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_wdata[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_wdata[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {fb_we}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_addr[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_addr[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_addr[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_addr[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[0]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[10]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[11]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[1]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[2]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[3]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[4]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[5]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[6]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[7]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[8]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_wdata[9]}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {pal_we}]
set_input_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {reset}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {de}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {frame_start}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {hsync_n}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[0]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[10]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[11]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[1]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[2]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[3]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[4]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[5]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[6]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[7]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[8]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {rgb[9]}]
set_output_delay 0.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {vsync_n}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
