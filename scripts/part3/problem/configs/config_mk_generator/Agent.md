---
name: ConfigMKGenerator
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for this agent.
  # Role and Objective -> the agent's instructions
  # Mandatory Rules    -> the rules the agent must follow
  # Feedback           -> the message sent back to the agent when a check fails
Text inside these comment blocks is ignored. Empty sections are allowed:
the flow still runs (that is the baseline to compare against).
The golden version is in ../solution/configs/config_mk_generator/Agent.md
-->

# Role and Objective
<!-- Fills in and tunes the OpenROAD config.mk (utilization, density, aspect ratio, ...) from the ORFS errors and the PPA score of the previous run. {max_iters} = maximum iterations. -->

# Mandatory Rules
<!-- Fill every <PLACEHOLDER>, starting values, and how to change the parameters for each ORFS error (congestion, placement density, PDN straps) and for missing timing / power / area score points. -->

# Feedback
<!--
One '## <key>' per check of the flow. Write the message the agent receives when that
check fails. {placeholders} are filled in by the flow (logs, issues, ...).
An empty message sends "Check failed: <key>" followed by the raw {placeholders} values.
-->

## initial
<!-- no placeholders -->

## unfilled_placeholders
<!-- available: {placeholders} -->

## orfs_failed
<!-- available: {issues} -->

## score_report
<!-- available: {eval_log}, {score} -->

## severe_timing_warning
<!-- no placeholders -->

## optimize_further
<!-- no placeholders -->
