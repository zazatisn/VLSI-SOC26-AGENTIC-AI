---
name: SDCGenerator
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for this agent.
  # Role and Objective -> the agent's instructions
  # Mandatory Rules    -> the rules the agent must follow
  # Feedback           -> the message sent back to the agent when a check fails
Text inside these comment blocks is ignored. Empty sections are allowed:
the flow still runs (that is the baseline to compare against).
The golden version is in ../solution/configs/sdc_generator/Agent.md
-->

# Role and Objective
<!-- Fills in the SDC template (sequential or combinational) for the YAML spec. -->

# Mandatory Rules
<!-- How to pick the template (clock or no clock), that every <PLACEHOLDER> must be filled, what each placeholder maps to, and that nothing else in the template may change. -->

# Feedback
<!--
One '## <key>' per check of the flow. Write the message the agent receives when that
check fails. {placeholders} are filled in by the flow (logs, issues, ...).
An empty message sends "Check failed: <key>" followed by the raw {placeholders} values.
-->

## initial
<!-- no placeholders -->

## structure_violation
<!-- available: {issues} -->

## unfilled_placeholders
<!-- available: {placeholders} -->
