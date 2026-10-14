---
name: ModuleGenerator
version: 0.1.0
---

<!--
HANDS-ON: write your own prompt for the module generators (Part 5).
  # Role and Objective -> instructions of a module generator (it writes ONE module from its contract)
  # Mandatory Rules    -> Verilog-2001 rules + "the contract is the law"
  # Feedback           -> the messages a module generator receives
Every module is checked ALONE before integration: header = contract, compiles, Yosys lint, and the
planner's Python model on random inputs (combinational modules). Then all modules are put in one file and
the testbench runs. A change that makes the whole design worse is undone (
