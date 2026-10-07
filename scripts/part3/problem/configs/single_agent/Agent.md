---
name: SingleAgent
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for this agent.
  # Role and Objective -> the agent's instructions
  # Mandatory Rules    -> the rules the agent must follow
  # Feedback           -> the message sent back to the agent when a check fails
Text inside these comment blocks is ignored. Empty sections are allowed:
the flow still runs (that is the baseline to compare against).
The golden version is in ../solution/configs/single_agent/Agent.md
-->

# Role and Objective
<!-- ONE agent that writes, in one answer, the Verilog-2001 testbench, the synthesizable RTL, the SDC file and the OpenROAD config.mk for a YAML spec. It is called again with feedback until every stage passes. -->

# Mandatory Rules
<!-- The whole workflow and every rule: testbench rules (clock/reset, drive on negedge / check on posedge, PASS/FAIL printing), RTL rules (synthesizable Verilog-2001, no latches, no multi-drivers, timing/pipelining, FSM style), SDC rules (how to fill the SDC template) and config.mk rules (starting values, how to tune them from the ORFS errors/score). Hint: the spec's 'timing' section defines the latency both the testbench and the RTL must use. -->

# Feedback
<!--
One '## <key>' per check of the flow. Write the message the agent receives when that
check fails. {placeholders} are filled in by the flow (logs, issues, ...).
An empty message sends "Check failed: <key>" followed by the raw {placeholders} values.
-->

## initial
<!-- no placeholders -->

## stage_failed
<!-- available: {details}, {passed}, {stage} -->

## tb_syntax_error
<!-- available: {errors} -->

## tb_missing_pass_message
<!-- no placeholders -->

## rtl_simulation_failed
<!-- available: {log} -->

## sdc_structure_violation
<!-- available: {issues} -->

## sdc_unfilled_placeholders
<!-- available: {placeholders} -->

## synthesis_failed
<!-- available: {issues} -->

## post_synthesis_failed
<!-- available: {log} -->

## config_unfilled_placeholders
<!-- available: {placeholders} -->

## orfs_failed
<!-- available: {issues} -->

## timing_resynthesis
<!-- available: {eval_log} -->

## score_report
<!-- available: {eval_log}, {score} -->

## severe_timing_warning
<!-- no placeholders -->

## optimize_further
<!-- no placeholders -->
