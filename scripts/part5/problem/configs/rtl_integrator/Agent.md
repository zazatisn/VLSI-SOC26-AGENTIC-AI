---
name: RTLIntegrator
version: 0.1.0
---

<!--
OPTIONAL agent (agents.rtl_integrator.enabled: true, e.g. run config 5b_rtl_planner_integrator.yaml).
It decides who fixes a failure of the integrated design: one or more modules, or the plan.
The flow fixes the OUTPUT FORMAT (one JSON object):
  {"diagnosis": "...", "fixes": [{"module": "<name>", "fix": "..."}], "replan": false, "replan_reason": ""}
HANDS-ON (bonus): write its role and its diagnosis rules.
The golden version is in ../solution/configs/rtl_integrator/Agent.md
-->

# Role and Objective
<!-- An integration / verification engineer: find the root cause and decide who must change. -->

# Mandatory Rules
<!-- How to trace a failing output back to a module; when the plan (contract, latency, wiring) is wrong
     instead of a module; name only the modules that must change. -->
