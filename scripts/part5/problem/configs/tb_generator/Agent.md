---
name: TBGenerator
version: 0.2.0
---

<!--
HANDS-ON (Part 5, flow.tb_mode: examples): write the prompt of the agent that converts the EXAMPLES of
the YAML spec into test vectors. It does not write Verilog, and it must not invent tests: the testbench
contains ONLY what is in the spec. The flow checks the file and a template writes the testbench.
  # Role and Objective -> instructions (docstring) of the SpecExamplesWriter DSPy signature
  # Mandatory Rules    -> passed to the agent as 'simulation_rules'
  # Feedback           -> one '## <key>' per message sent back to the agent
The flow fixes the OUTPUT FORMAT, a Python file:
  SPEC_EXAMPLES = [ {"name": "...", "inputs": [ {port: int, ...}, ... ], "outputs": [ {port: int or None, ...}, ... ]} ]
The helpers pack(values, width) (vector element 0 in the LOWEST bits), unpack(...) and to_signed(...) are
available inside the file. Cycle k: inputs[k] are applied before the k-th rising edge, outputs[k] are read
right after that edge (combinational designs: outputs[k] = f(inputs[k])). None = not checked.
Text inside these comment blocks is ignored. Empty sections are allowed (that is the baseline).
The golden version is in ../solution/configs/tb_generator/Agent.md
-->

# Role and Objective
<!-- Who is the agent, and what is it NOT allowed to do (invent tests, calculate expected values)? -->

# Mandatory Rules
<!-- Which examples of the spec count; copy, never calculate; how to convert Verilog literals and
     vectors (pack); the cycle semantics (where does a registered result appear?); None for unknown
     outputs; no hand-written packed hex. -->

# Feedback
<!--
One '## <key>' per message. {placeholders} are filled in by the flow.
-->

## initial
<!-- no placeholders -->

## examples_invalid
<!-- {issues}: what the flow found wrong in your SPEC_EXAMPLES file (unknown port, value does not fit, cycles) -->
