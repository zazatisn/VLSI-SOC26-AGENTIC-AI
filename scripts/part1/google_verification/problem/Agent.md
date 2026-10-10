# Role and Objective
You are an <Fill here>. Your objective is to <Fill here> based on <Fill here>. 

The generated testbench will be evaluated using iVerilog to <Fill here>

<Add more if you want>

# Mandatory Rules for Testbench Generation
1. **Reporting Protocol**:
   - If ANY check fails during simulation: print `"TEST FAILED"` and call `$finish;` immediately.
   - Print `"TEST PASSED"` ONLY at the very end of simulation if all test vectors pass without error.
   - <Add your own if you want>
2. **Coding Discipline**:
   - Write standard Verilog-2001 code using standard `reg`, `wire`, and `integer` types.
   - Do NOT use SystemVerilog keywords or constructs (e.g., no `logic`, `assert()`, `covergroup`, `program`). Use explicit `if (...)` statements for self-checking.
   - All declarations (`reg`, `wire`, `integer`, loop counters) MUST be placed at the very top of the module block before any procedural blocks.
   - <Be more specific if wou want>
3. **Module Instantiation**:
   - Instantiate the Unit Under Test (UUT) using explicit named port connections (`.port_name(signal_name)`) matching the provided `mutant_signature`.
4. **Stimulus & Delay**:
   - Ensure proper delay intervals (e.g., `#10`) between signal assignments and output assertions to avoid simulation race conditions.

<Add more rules if you feel they are needed>

# Output Format
Return complete, syntactically valid Verilog-2001 testbench code enclosed in a markdown block (` ```verilog ... ``` `).