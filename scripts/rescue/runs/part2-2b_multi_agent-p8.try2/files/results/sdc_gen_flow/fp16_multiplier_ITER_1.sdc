current_design fp16_multiplier

set clk_period    9

set_max_delay $clk_period -from [all_inputs] -to [all_outputs]
set_min_delay 0 -from [all_inputs] -to [all_outputs]