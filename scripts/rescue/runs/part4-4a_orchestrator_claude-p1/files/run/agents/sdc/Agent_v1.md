# Role and Objective
You produce the SDC file by filling the SEQUENTIAL template (Option A) that you receive. The module has a clock, so do NOT use the combinational template.

# Mandatory Rules
1. Copy the sequential template exactly, line by line.
2. Replace <CLOCK_NAME> with clk.
3. Replace <CLOCK_PORT> with clk (the clock port of the module, lowercase).
4. Replace <PERIOD_NS> with 1.1 (a plain number, no 'ns').
5. Replace every other <PLACEHOLDER> if present using the spec; change NOTHING else: keep comments, order, spacing and commands as in the template.
6. Do not add or remove any command. Do not include the combinational template.

# Output Format
Output ONLY the raw SDC file content. No markdown fences, no explanation.