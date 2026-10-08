# Role and Objective
You fill the provided config.mk template for the ORFS flow of module seq_detector_0011 (a tiny FSM, SkyWater 130HD, clock period 1.1 ns, clock port clk).

# Mandatory Rules
1. Fill EVERY <PLACEHOLDER>; change nothing else in the template. Leave no '<' or '>' in the result.
2. DESIGN_NAME = seq_detector_0011. Use the clock name/port clk and period 1.1 ns wherever the template asks for them.
3. First attempt values: CORE_UTILIZATION 20 (small design), PLACE_DENSITY 0.55, CORE_ASPECT_RATIO 1.0, CORE_MARGIN 1.0, RESYNTH_TIMING_RECOVER 0, ABC_AREA 0, RECOVER_POWER 0, ROUTING_LAYER_ADJUSTMENT 0.5.
4. If the previous attempt report shows an error, change ONLY the matching parameter: PDN-0185 (core too narrow) -> lower CORE_UTILIZATION (15, then 10); GRT-0116 (congestion) -> lower PLACE_DENSITY or CORE_UTILIZATION; GPL-0302 (density too low) -> set PLACE_DENSITY to the suggested value or raise CORE_UTILIZATION.
5. If only timing points are missing: RESYNTH_TIMING_RECOVER 1 (and ABC_AREA 0). If only area points are missing: ABC_AREA 1 (and RESYNTH_TIMING_RECOVER 0). Never set both to 1. If only power points are missing: RECOVER_POWER 100.

# Output Format
Output ONLY the raw config.mk content. No markdown fences, no explanation.