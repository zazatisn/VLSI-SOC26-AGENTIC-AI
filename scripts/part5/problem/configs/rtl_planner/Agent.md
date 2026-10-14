---
name: RTLPlanner
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for the RTL planner (Part 5).
  # Role and Objective -> the planner's instructions
  # Mandatory Rules    -> how to split the design and how to fill the plan
  # Feedback           -> the messages the planner receives when its plan or the design fails
The flow fixes the OUTPUT FORMAT, three separate answers:
  plan_json     : {"decompose": true|false, "summary": "...",
                   "modules": [{"name", "header", "function", "latency_cycles", "children"}]}   (no code inside)
  top_rtl       : module <top> ... endmodule   (only instances and wiring)
  module_models : Python, one function per combinational module, named like the module:
                  def <module>(inp): return {<output>: <int>, ...}   (the flow runs it on random inputs)
Every plan is checked BEFORE any module is written: top_rtl + empty stubs of the modules must pass
Yosys and compile with the testbench. Text inside these comment blocks is ignored. Empty sections are
allowed (that is the baseline). The golden version is in ../solution/configs/rtl_planner/Agent.md
-->

# Role and Objective
<!-- Who is the planner? What does a good plan look like (modules that can be written and checked alone)? -->

# Mandatory Rules
<!-- When to split and when not (small designs: "decompose": false). How many modules. How to write a
     contract: exact ANSI header with widths, a precise function text, latency_cycles. The latency budget
     must add up to the spec's timing. What may be in top_rtl. How to write a module model (let Python
     compute, never write numbers by hand). -->

# Feedback
<!--
One '## <key>' per message. {placeholders} are filled in by the flow.
An empty message sends "Check failed: <key>" followed by the raw {placeholders} values.
-->

## initial
<!-- no placeholders -->

## plan_invalid
<!-- {issues}: what the plan checks found -->

## top_failed
<!-- {log}: errors in your top_rtl once the real modules are connected -->

## testbench_failed
<!-- {log}, {unit_report}, {design}: the design keeps failing the testbench while the modules pass their own checks -->

## integrator_replan
<!-- {diagnosis}, {reason}, {log}: the RTL integrator asks for a new plan -->

## timing_resynthesis
<!-- {eval_log}: the layout failed timing by far: change the architecture -->
