---
name: TBGenerator
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for this agent.
  # Role and Objective -> the agent's instructions
  # Mandatory Rules    -> the rules the agent must follow
  # Feedback           -> the message sent back to the agent when a check fails
Text inside these comment blocks is ignored. Empty sections are allowed:
the flow still runs (that is the baseline to compare against).
The golden version is in ../solution/configs/tb_generator/Agent.md
-->

# Role and Objective
<!-- Writes a self-checking Verilog-2001 testbench from the YAML spec and the module signature. -->

# Mandatory Rules
<!-- Clock and reset, drive/sample protocol, how every check must be printed (the flow looks for PASS / FAIL in the simulation log), Verilog-2001 coding discipline, timeouts and $finish. Hint: every spec has a 'timing' section that defines the latency and when to check the outputs. -->

# Feedback
<!--
One '## <key>' per check of the flow. Write the message the agent receives when that
check fails. {placeholders} are filled in by the flow (logs, issues, ...).
An empty message sends "Check failed: <key>" followed by the raw {placeholders} values.
-->

## initial
<!-- no placeholders -->

## syntax_error
<!-- available: {errors} -->

## validator_mismatch
<!-- available: {issues} -->

## missing_pass_message
<!-- no placeholders -->
