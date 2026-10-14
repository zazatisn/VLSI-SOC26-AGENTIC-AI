# Part 5: RTL Planner and Module Generators

Part 5 is the Part 3 flow (feedback loops, PPA optimization, resynthesis) with **two changes**:

1. the RTL is written by a **planner and module generators** instead of one RTL agent;
2. the testbench contains **only the examples of the YAML spec**.

Everything else (SDC, `config.mk`, OpenROAD, PPA score, iterative optimization, resynthesis) is exactly
Part 3. With `flow.rtl_mode: classic` the script behaves like Part 3 for the RTL.

```
spec ─► TB agent ─► (examples only) ─► RTL PLANNER ─► module generator 1 ─┐
        converts the                    contracts      module generator 2 ─┼─► integrate ─► testbench ─► Yosys ─► SDC ─► config.mk ─► OpenROAD ─► score
        spec's examples                 + top_rtl      module generator N ─┘    (1 file)       sim
        to test vectors                    ▲                ▲ each module checked ALONE: header, compile, lint, Python model
                                           └─ replan (optional RTL integrator decides who fixes) ◄─ failures ── resynthesis (timing) ─► planner
```

---

## 1. RTL planner, module generators, optional integrator

1. **RTL planner** (`rtl_planner`) reads the spec and decides how to split it. For every module it writes
   a **contract**: the exact Verilog header, what it computes, its latency in cycles and, for
   combinational modules, a small Python model. It also writes the **top module** (`top_rtl`), which only
   instantiates and wires the modules. Small designs are not split (`"decompose": false`): one module
   generator then writes the whole design, as in Part 3.
2. **Plan check, before any module is written** (no tokens): the top module with the planned modules as
   empty stubs must pass Yosys (hierarchy, port widths, drivers) and compile with the testbench.
3. **Module generators** (`module_generator`) write one module at a time from its contract. Every module
   is checked **alone**: header = contract, it compiles, Yosys lint (latches, multiple drivers, widths),
   and the planner's Python model on random inputs (combinational modules).
4. **Integration**: all modules in one file (children first, top last), then the Part 3 checks: testbench
   simulation, Yosys synthesis, optional gate-level simulation, physical flow.
5. **RTL integrator** (`rtl_integrator`) is **optional and off by default**, like the validators
   (`agents.rtl_integrator.enabled: true`, run config `5b`). When the integrated design fails the testbench
   and no tool can name the module, the integrator reads the log and the design and decides which
   module(s) must change, or that the plan must change.

### Who gets the feedback?

| failure | goes to |
|---|---|
| plan check (stubs, Yosys, testbench compile) | the planner |
| a module's own check (header, compile, lint, Python model) | that module's generator only |
| compile / Yosys errors of the integrated design | the module named in the error (file:line or module name); the top module belongs to the planner |
| testbench or gate-level mismatch (nobody can be named) | **integrator ON**: the integrator decides. **OFF** (default), `sim_failure_feedback: all`: every module generator gets the log and keeps its module if it is not the cause; after `replan_after_failures` failures in a row the planner replans. `sim_failure_feedback: planner`: the planner gets it directly |
| timing failed by far in the physical flow (resynthesis) | the planner (architecture, pipelining); if it keeps the plan, every module must get faster |

After a replan, a module whose contract did not change keeps its code: only the changed modules are rewritten.

---

## 2. The testbench: only what is in the YAML

Models are bad at inventing test cases, and bad at computing their expected values: in our first runs an
agent testbench expected `0x7bff × 0x0400 = 0x3c00` for the FP16 multiplier (the right answer is `0x43ff`),
and a correct RTL was "fixed" until it broke. So in Part 5 (`flow.tb_mode: examples`):

1. the **`tb_generator`** agent does **not write Verilog**. It converts the examples that are in the spec
   (`sample_input`/`sample_output`, `sample_usage`, numbers in `timing`/`description`) into
   `SPEC_EXAMPLES`, a small Python file with one list of input cycles and one list of expected-output
   cycles per example. Vectors are built with the built-in helper `pack(values, width)`
   (element 0 in the lowest bits), never as hand-written hex;
2. the flow checks the file (ports, widths, same number of cycles) and a template writes the testbench
   (`tb_gen_flow/<top>_tb.v`, the vectors in `<top>_vectors.json`, your file in `spec_examples.py`).
   The testbench prints `TEST: FAIL | SPEC_EXAMPLES[i] (name) cycle k | ...`, `RESULT: P of T tests passed`
   and `PASS`/`FAIL`.

Cycle `k`: the inputs are applied before the `k`-th rising edge, the outputs are read right after it
(combinational designs: `outputs[k] = f(inputs[k])`). `None` = not checked.

> If the RTL keeps failing a spec example, look at `tb_gen_flow/spec_examples.py` first: the conversion of
> the spec's timing into cycles is the only place where this testbench can be wrong. You can fix the
> vectors by hand and run with `overrides.tb_path`.

### Optional: more test cases from a Python black-box model

`agents.reference_model.enabled: true` adds the **`reference_model`** agent. It writes `ref_model.py`, a
Python mock-up of the design (`stimuli()` and `simulate()`): edge cases and random values with a fixed seed.

- The model **must reproduce the spec's examples first**. If it does not, the agent gets the whole trace
  (inputs, spec, model, per cycle) and a hint such as "your outputs are 1 cycle late".
- Python then computes the expected values of the extra tests, which are appended to the testbench
  (`model test N` in the failure lines).
- If no usable model comes out after `reference_model.max_iters` attempts, the run goes on with the spec's
  examples only.

Extra tests are off by default because a wrong model rejects a correct design: that is the price of more coverage.

---

## Folder layout

```
part5/
├── README.md
├── designs/  evaluation/                       # same specs and PPA scoring as Part 3
├── problem/                                    # ◄ what you work on
│   ├── asic_autonomous_flow.py                 #   the Part 3 flow + rtl_mode: planner + tb_mode: examples
│   ├── rtl_planner_tools.py                    #   plan checks, headers, stubs, feedback routing (no LLM)
│   ├── reference_model_tools.py                #   spec examples / Python model -> testbench (no LLM)
│   ├── run_configs/5a_rtl_planner.yaml             # integrator OFF (default)
│   ├── run_configs/5b_rtl_planner_integrator.yaml  # integrator ON
│   └── configs/
│       ├── tb_generator/      Agent.md (minimal) + config.yaml    (spec examples -> test vectors)
│       ├── rtl_planner/       Agent.md (minimal) + config.yaml
│       ├── module_generator/  Agent.md (minimal) + config.yaml
│       ├── rtl_integrator/    Agent.md (minimal) + config.yaml    (optional agent)
│       ├── reference_model/   Agent.md (minimal) + config.yaml    (optional agent)
│       └── sdc_generator/ config_mk_generator/ ...  (as in Part 3)
└── solution/                                   # golden Agent.md prompts
```

In `problem/` the Part 3 loops (iterative optimization, resynthesis) are off, so the run focuses on the
RTL. In `solution/` they are on.

## How to run

```bash
cd /home/scripts/part5/problem          # or /home/scripts/part5/solution
source /home/scripts/api_keys.sh

python3 asic_autonomous_flow.py --config run_configs/5a_rtl_planner.yaml                  # p8, integrator off
python3 asic_autonomous_flow.py --config run_configs/5a_rtl_planner.yaml --design p7.yaml
python3 asic_autonomous_flow.py --config run_configs/5b_rtl_planner_integrator.yaml       # integrator on

# a stronger model for the planner only (planning is a reasoning task)
python3 asic_autonomous_flow.py --config run_configs/5a_rtl_planner.yaml --agent-profile rtl_planner=claude-sonnet-5-5
```

Good designs: `p8` (unpack / multiply / normalize / round / pack), `p7`, `p9`, `p5`. Hard designs made for Part 5:
`p17` (`vga_lcd`: timing generator + framebuffer + palette + pipeline) and `p18` (`rv32i_core`: a single-cycle
RV32I core; its spec example is a short program with the expected retire port, cycle by cycle). On small designs
(`p11`, `p12`, `p1`) a good planner answers `"decompose": false`.

**Outputs** in `runs/<run>/results/<design>/`:

| file | what |
|---|---|
| `tb_gen_flow/spec_examples.py`, `<top>_tb.v`, `<top>_vectors.json` | the spec's examples as vectors and the generated testbench (`spec_examples_ITER_N.py`: every attempt) |
| `tb_gen_flow/ref_model.py` | the black-box model, only with the reference model enabled |
| `rtl_gen_flow/plan.txt`, `plan/plan_N.txt` | the accepted plans (`plan/plan_N_answer.txt`: the raw answer of every planner call) |
| `rtl_gen_flow/modules/<module>_CALL_N.v` | every version of every module |
| `rtl_gen_flow/<top>_ITER_N.v` | the integrated design of every RTL iteration |
| `rtl_gen_flow/<top>_sim_ITER_N.log`, `<top>_yosys_ITER_N.log` | testbench and synthesis logs |

`token_usage.json` shows the tokens per agent: compare `rtl_planner` + `module_generator` with the single
`rtl_generator` of Part 3 on the same design.

### Settings (`planner:` in the run config)

| key | default | meaning |
|---|---|---|
| `max_plan_iters` | 3 | attempts to get a valid plan |
| `max_module_iters` | 3 | attempts per module to pass its own checks (then it is integrated anyway) |
| `max_modules` | 8 | upper limit for the plan |
| `unit_models` | true | check combinational modules with the planner's Python models (random inputs) |
| `candidates` | 1 | independent versions per module attempt, the best one wins |
| `sim_failure_feedback` | all | `all` or `planner` (used when the integrator is off) |
| `replan_after_failures` | 3 | testbench failures in a row before the planner replans |
| `max_replans` | 2 | new plans after the first one |

The RTL iterations are still `iterations.max_rtl_gen_iters` (one iteration = write/fix modules, integrate,
simulate). `flow.tb_mode` is `examples` (default) or `agent` (the Part 3 testbench agent).

---

## What you do (hands-on)

1. **`tb_generator/Agent.md`**: how to turn the spec's examples into cycles (where does a registered result
   appear?), copy instead of calculate, `pack` for vectors, `None` for unknown outputs.
2. **`rtl_planner/Agent.md`**: when to split and when not; how to write a contract (exact header, precise
   function text, latency); the latency budget; what may be in the top module; the Python module models.
3. **`module_generator/Agent.md`**: "the contract is the law", the Verilog-2001 rules (start from the
   Part 3 `rtl_generator` rules), and the `testbench_failed` message: what should a module generator do
   when the whole design fails but its own module may be correct?
4. Run p8 with `5a`, then with `5b` (integrator on). Compare with your Part 3 run of p8.
5. Bonus: enable `reference_model` and compare coverage and failures.

**Things to think about**

- Did the planner split p8 the way you would? Did it decide not to split a small design?
- How many RTL iterations, and how many tokens, compared with one RTL agent (Part 3)?
- Integrator off vs on: how many module rewrites did a testbench failure cost? Were correct modules rewritten?
- Is a testbench with only the spec's examples enough? What does it miss that the Part 3 testbench found?
- Is the result really correct? Check the final RTL with `scripts/reference/check_designs.py -d p8 --rtl <file>`.
