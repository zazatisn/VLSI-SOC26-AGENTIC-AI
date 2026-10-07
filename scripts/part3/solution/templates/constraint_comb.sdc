current_design <MODULE_NAME>

set clk_period    <PERIOD_NS>

set_max_delay $clk_period -from [all_inputs] -to [all_outputs]
set_min_delay 0 -from [all_inputs] -to [all_outputs]