# Variables set externally by wrapper script
#   - odb_path: path to .odb file
#   - sdc_path: path to .sdc file
#   - flow_root: path to openroad-flow-scripts

# Paths
set platform "sky130hd"
set platform_dir "$flow_root/flow/platforms/$platform"
set lib_dir "$platform_dir/lib"

# Load liberty files
read_liberty "$lib_dir/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Load ODB database
read_db $odb_path

# Read timing constraints
read_sdc $sdc_path

# Load RC parasitics
source "$platform_dir/setRC.tcl"

# Generate report metrics
proc report_metrics_eval {} {
  puts "\n==================== Summary ===================="
  report_design_area
  report_design_area_metrics

  report_tns
  report_tns_metric
  report_tns_metric -hold

  report_wns
  report_worst_slack
  report_worst_slack_metric
  report_worst_slack_metric -hold

  report_power
  report_power_metric

  set clk_defs [sta::get_clocks]
  if {[llength $clk_defs] > 0} {
    set clk [lindex $clk_defs 0]
    set clk_period [sta::get_property [sta::get_clocks $clk] period]
    puts [format "Clock Period: %.3f ns" $clk_period]
  } else {
    puts "Clock Period: not defined"
  }
}

report_metrics_eval
