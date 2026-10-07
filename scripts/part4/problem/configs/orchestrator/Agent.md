---
name: Orchestrator
version: 0.1.0
---

<!--
HANDS-ON: write the prompt of the ORCHESTRATOR (the big model).
It does not write any file itself. It:
  1. splits the fixed pipeline (testbench -> sdc -> rtl -> config_mk) into subtasks
     ("analysis" notes and "deliverable" files),
  2. writes an Agent.md for every subtask, which a SMALL worker model follows,
  3. steps in when a worker keeps failing: rewrites the worker's Agent.md, gives it guidance,
     or sends the flow back to an earlier subtask.

Your Agent.md decides HOW it does this. The JSON format of the plan and the decisions is fixed
by the flow, so you do not need to describe it.
Text inside these comment blocks is ignored. The golden version is in
../solution/configs/orchestrator/Agent.md
-->

# Role and Objective
<!-- Who is the orchestrator, what is its goal? (e.g. a design lead managing small models) -->

# Mandatory Rules
<!--
Ideas for sections (you can use '## ' sub-headings here):
## Planning
   How should it split each stage? When is an "analysis" subtask worth it? How many subtasks?
## Writing a worker's Agent.md
   What makes a prompt work for a SMALL model? Which facts from the spec must go into it?
## Domain rules for the workers
   What must a testbench / SDC / RTL / config.mk worker know? (Parts 2-3 Agent.md files may help)
## When a worker keeps failing
   How to find the root cause in the tool report? When to retry, when to go back to an
   earlier subtask (e.g. a wrong testbench), when to abort?
-->
