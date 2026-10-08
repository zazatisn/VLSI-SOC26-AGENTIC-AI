# Reference designs: golden RTL, sign-off and testbench grading

For every design `pN` of Parts 2–4 this folder holds what a perfect agent would produce, plus
the tools that check the designs, sign off an agent's RTL and grade an agent's testbench.

```
reference/
├── check_designs.py        spec ↔ golden RTL ↔ reference TB checks, sign-off, testbench grading
├── make_reference.py       generates the PPA reference evaluation/visible/pN/pN.json (run in Docker)
└── pN/
    ├── <module>.v          golden RTL, written from the YAML spec
    ├── constraint.sdc      golden SDC (the flow's template, filled in)
    ├── config.mk           golden ORFS config (the flow's template, filled in)
    └── mutants.yaml        bugs injected into the golden RTL, to measure a testbench
```

The specs are in `partN/designs/pN.yaml` and the reference (sign-off) testbenches in
`partN/evaluation/visible/pN/*_tb.v` (the same files in Parts 2, 3 and 4).

| ID | Module | What it is | Clock | Reference TB | PPA reference |
|---|---|---|---|---|---|
| p1 | `seq_detector_0011` | Moore FSM, detects 0011 | 1.1 ns | ICLAD, **corrected** (reset race) | ICLAD |
| p5 | `dot_product` | 2-stage pipelined dot product | 4.5 ns | ICLAD, **corrected** (`valid` port not in spec) + more tests | ICLAD |
| p7 | `exp_fixed_point` | 2-stage Taylor e^x | 4.5 ns | ICLAD case + all 256 inputs, enable, reset | ICLAD |
| p8 | `fp16_multiplier` | FP16 multiplier, combinational | 9.0 ns | ICLAD 3 cases + 317 (rounding ties, overflow, ...) | ICLAD |
| p9 | `fir_filter` | 8-tap pipelined FIR | 8.0 ns | ICLAD test + signed random, reset | ICLAD |
| p11 | `simple_8bit_counter` | counter with enable | 2.0 ns | new | `make_reference.py` |
| p12 | `registered_adder_8bit` | registered adder | 1.5 ns | new | `make_reference.py` |
| p13 | `sliding_window_avg_8bit` | 4-tap moving average | 2.5 ns | new | `make_reference.py` |
| p14 | `alu_8bit` | 8-op ALU with zero/carry flags | 2.5 ns | new | `make_reference.py` |
| p15 | `uart_tx` | UART transmitter 8N1 | 2.0 ns | new | `make_reference.py` |
| p16 | `sync_fifo` | 8 × 8 synchronous FIFO | 2.0 ns | new | `make_reference.py` |

## Check the designs

```bash
cd /home/scripts/reference
python3 check_designs.py                    # every design
python3 check_designs.py --mutants --synth --gls
```

For every design it checks that:
- the spec has the required sections and its `ports` match its `module_signature`;
- the reference TB compiles against the bare `module_signature` (exactly what the flows do with an agent's TB);
- the golden RTL has the same ports as the signature (Yosys) and **passes the reference TB**;
- `--mutants`: the reference TB **fails on every mutant** (it is strong enough);
- `--synth` / `--gls`: the golden RTL synthesizes to sky130hd without latches, and the netlist passes the TB.

## Sign off an agent's RTL

The flows only run the testbench the agent wrote. A wrong testbench can accept a wrong design.
Sign-off runs the independent reference testbench on any RTL:

```bash
python3 check_designs.py -d p8 --rtl ../part2/solution/runs/2b_multi_agent/solution/p8/fp16_multiplier.v
```

## Grade an agent's testbench

A testbench must pass a correct design and fail on buggy ones:

```bash
python3 check_designs.py -d p8 --tb ../part2/solution/runs/2b_multi_agent/results/p8/tb_gen_flow/fp16_multiplier_tb.v
#   (example output)
#   Golden RTL: PASS
#     caught  truncation, no rounding
#     MISSED  round half up, not to even
#   Testbench strength for p8: 2/3 bugs caught (67%)
```

## Generate the PPA references (once, in Docker)

p11–p16 have no `pN.json` yet, so the flows accept their layouts without a score. Generate the references once:

```bash
python3 make_reference.py --keep-layout     # every design without a pN.json; ~2-5 min per design
```

It runs the golden files through ORFS exactly like the flows do. If the golden `config.mk` fails
(small designs often hit PDN errors), it retries with safer floorplans and saves the one that worked.
It then measures the layout with `evaluation/report_metrics.tcl` and writes `pN.json` to Parts 2, 3 and 4.
The golden layout itself scores 75–80/100 (80 when the reference meets timing: a TNS of 0 earns the TNS bonus). `--keep-layout` also keeps the golden GDS in `pN/layout/`.
That's a known-good result to show if a live run fails. Commit the new `pN.json` files.
