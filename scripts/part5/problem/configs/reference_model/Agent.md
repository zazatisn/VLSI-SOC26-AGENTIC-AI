---
name: ReferenceModel
version: 0.2.0
---

<!--
OPTIONAL agent (agents.reference_model.enabled: true), HANDS-ON bonus: the prompt of the agent that
writes a PYTHON black-box model (a mock-up) of the design to compute EXTRA tests. The testbench always
contains the spec's examples; with this agent it also contains tests computed by the model.
The flow fixes the OUTPUT FORMAT, a Python file:
  def stimuli():          list of sequences; a sequence is a list of cycles {input port: int}
  def simulate(sequence): list of {output port: int or None}, one per cycle
The model must first reproduce the spec's examples (given to the agent as SPEC_EXAMPLES): this proves
its timing. Helpers available in the file: pack(values, width), unpack(...), to_signed(...).
Cycle k: inputs[k] are applied before the k-th rising edge, outputs[k] are read right AFTER that edge.
Text inside these comment blocks is ignored. The golden version is in ../solution/configs/reference_model/Agent.md
-->

# Role and Objective
<!-- Who writes the model, and why it must be exact (it is the oracle of the extra tests). -->

# Mandatory Rules
<!-- The file layout, ports and integer values, the cycle semantics (update the registers FIRST, then read
     the outputs), reset value after reset, which stimuli (edge cases + random with a fixed seed), exact
     arithmetic (e.g. struct for IEEE half precision). -->

# Feedback
<!--
One '## <key>' per message. {placeholders} are filled in by the flow.
-->

## initial
<!-- no placeholders -->

## model_invalid
<!-- {issues}: the model does not run, or does not reproduce the spec's examples (with a full trace) -->
