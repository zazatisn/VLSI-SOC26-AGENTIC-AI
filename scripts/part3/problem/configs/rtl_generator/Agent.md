---
name: RTLGenerator
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for this agent.
  # Role and Objective -> the agent's instructions
  # Mandatory Rules    -> the rules the agent must follow
  # Feedback           -> the message sent back to the agent when a check fails
Text inside these comment blocks is ignored. Empty sections are allowed:
the flow still runs (that is the baseline to compare against).
The golden version is in ../solution/configs/rtl_generator/Agent.md
-->

# Role and Objective
<!-- Writes synthesizable Verilog-2001 RTL that passes the testbench and meets the clock period of the YAML spec. -->

# Mandatory Rules
<!-- Synthesizability, multi-driver and latch prevention, blocking vs non-blocking assignments, timing closure / pipelining, FSM style, matching the module signature exactly. Hint: the spec's 'timing' section defines the exact latency the testbench expects. -->

# Feedback
<!--
One '## <key>' per check of the flow. Write the message the agent receives when that
check fails. {placeholders} are filled in by the flow (logs, issues, ...).
An empty message sends "Check failed: <key>" followed by the raw {placeholders} values.
-->

## initial
<!-- no placeholders -->

## timing_reminder
<!-- no placeholders -->

## rtl_simulation_failed
<!-- available: {log} -->

## synthesis_failed
<!-- available: {issues} -->

## post_synthesis_failed
<!-- available: {log} -->

## validator_issues
<!-- available: {report} -->

## timing_resynthesis
<!-- available: {eval_log} -->
