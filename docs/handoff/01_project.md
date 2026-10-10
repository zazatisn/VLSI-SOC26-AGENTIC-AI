# 01 — The project

## What it is

The hands-on material for the **VLSI-SoC 2026 tutorial "Agentic AI in EDA"** (University of Thessaly,
Prof. Christos Sotiriou; Qualcomm support). A 3-hour morning session, 9:00–12:00:

| time | block |
|---|---|
| 9:00–9:15 | welcome + setup (Docker, API keys, regression check) |
| 9:15–9:50 | Part 1 foundations: sentiment agent (DSPy), testbench agent (Google / ICLAD 2025 problem) |
| 9:50–10:20 | Part 2 Spec2Tapeout: single agent vs decomposed agents, scoring vs golden run, check_designs |
| 10:20–10:40 | break |
| 10:40–11:10 | Part 3 feedback loops: PPA optimization + resynthesis |
| 11:10–11:45 | Part 4 orchestrator: a big model plans and writes prompts for small worker models |
| 11:45–12:00 | Part 5 open challenges + Q&A |

The same code base is also the starting point of a **research paper** (see `05_paper.md`), developed in a
private mirror of this repo.

- Public repo: `https://github.com/zazatisn/VLSI-SOC26-AGENTIC-AI` (owner: zazatisn)
- Owner's working copy: `C:\Users\zazat\Desktop\VLSI-SOC` (Windows; Docker Desktop / WSL)
- Docker image (x86): `kostasvarak/vlsi-soc26-ai:latest` → `docker pull` then `docker tag … vlsi-soc26-ai`
- ARM (e.g. Qualcomm laptops, WSL): build `Dockerfile.arm64`

## Repository map

```
Dockerfile, Dockerfile.arm64     x86 image (also on Docker Hub) / ARM image (KLayout + OpenROAD from source)
install/install_ubuntu.sh        local install (Ubuntu 22/24/26) into ~/eda, writes ~/eda/vlsi_soc_env.sh
install/install_macos.sh         local install for macOS
README.md                        setup options A (pull) / B (build) / C (local), parts, instructor checklist
scripts/
  api_keys.example.sh            template; the real api_keys.sh is git-ignored
  part1/sentiment_analysis/      DSPy sentiment agent: Agent.md + trainset.json, NO feedback loop
  part1/google_verification/     ICLAD 2025 Google problem: spec -> testbench, graded by 31 mutants (exactly one correct)
                                 single_pass.py, iterative.py; designs like enc_bin2gray ... cdc_fifo_flops_push_credit
  part2/ part3/ part4/           each: problem/ (attendees edit) and solution/ (golden prompts), designs/, evaluation/
    problem|solution/
      asic_autonomous_flow.py    parts 2-3 (asic_orchestrated_flow.py + eda_tools.py in part 4)
      run_configs/*.yaml         2a_single_agent, 2b_multi_agent, 2c_multi_agent_mixed_models,
                                 2d_multi_agent_mixed_models_validators, 3_multi_agent_collaboration,
                                 4a_orchestrator_claude, 4b_orchestrator_gemini
      configs/<agent>/Agent.md   the prompt: # Role and Objective, # Mandatory Rules, # Feedback (## <check> sections)
      configs/<agent>/config.yaml  model profiles (active_profile); never keys
      templates/                 config.mk and SDC templates with <PLACEHOLDERS>
    designs/pN.yaml              the specs (renamed from "problems"; config key paths.designs_dir, problems_dir still accepted)
    evaluation/                  evaluate_openroad.py (PPA score), report_metrics.tcl, visible/pN/{pN.json, tb}
  reference/                     golden RTL, constraint.sdc, config.mk, mutants.yaml per design
    check_designs.py             spec <-> golden RTL <-> reference TB; --mutants --synth --gls; -d pN --rtl F; -d pN --tb F
    make_reference.py            golden OpenROAD run -> evaluation/visible/pN/pN.json in parts 2-4 (has floorplan fallbacks)
  rescue/                        make_rescue.py (record runs, presets.yaml), show_rescue.py (list/show/files/replay), runs/
  regression/regression.py       environment check: tools, sim, synth+GLS, full OpenROAD on golden p11, evaluation; --quick --llm --agent --all
  profile/profile_designs.py     time / tokens / success per design and run (eda, agent, harvest, report)
```

## The designs (11)

| id | module | what | clock | tier |
|---|---|---|---|---|
| p11 | simple_8bit_counter | counter, sync reset + enable | 2.0 ns | easy (fast demo) |
| p12 | registered_adder_8bit | adder + output register | 1.5 | easy |
| p1 | seq_detector_0011 | Moore FSM | 1.1 | easy |
| p15 | uart_tx | UART 8N1 transmitter | 2.0 | easy |
| p13 | sliding_window_avg_8bit | 4-tap moving average | 2.5 | medium (golden WNS < 0) |
| p14 | alu_8bit | 8-op ALU + flags | 2.5 | medium |
| p16 | sync_fifo | 8x8 FIFO | 2.0 | medium |
| p5 | dot_product | 2-stage pipelined dot product | 4.5 | medium |
| p7 | exp_fixed_point | 2-stage Taylor e^x | 4.5 | hard |
| p9 | fir_filter | 8-tap pipelined FIR | 8.0 | hard (golden WNS < 0) |
| p8 | fp16_multiplier | IEEE half-precision multiply, combinational | 9.0 | hard (run-config default) |

p1, p5, p7, p8, p9 come from the ICLAD / ASU Spec2Tapeout set; p11–p16 were added for the tutorial.
Every spec has a `timing:` section — the latency contract both the TB agent and the RTL agent read.
All 11 have golden references (`pN.json`) in parts 2, 3 and 4.

## The flows in one paragraph each

- **Part 2** (`asic_autonomous_flow.py`): TB agent → RTL agent (iverilog sim + Yosys) → SDC agent →
  config.mk agent → OpenROAD → PPA score. Checks in order: TB compiles, RTL sim passes, SDC matches template,
  Yosys clean, config.mk filled, OpenROAD flow, PPA score. 2a = one agent writes all four files; 2b = one
  agent per file (Gemini Flash Lite); 2c = hybrid (template tasks on local llama3.1); 2d = 2c + validators.
- **Part 3** (`3_multi_agent_collaboration.yaml`): loop 1 `iterative_optimization` (config.mk agent tunes
  until `score_threshold` 92 or `max_physical_iters`); loop 2 `enable_resynthesis` (WNS < −0.5 ns → RTL agent
  pipelines the design, `max_resynthesis_attempts` 3). Feedback text = `## score_report`, `## optimize_further`,
  `## severe_timing_warning`, `## timing_resynthesis` in the Agent.md files.
- **Part 4** (`asic_orchestrated_flow.py`): the orchestrator (Claude Sonnet in 4a, Gemini in 4b) writes
  `plan.json` (subtasks per stage), an `Agent_v1.md` per subtask for small workers (Claude Haiku), steps in on
  repeated failure (rewrite prompt → `Agent_v2.md`, guidance, or redo an earlier subtask). Outputs in
  `runs/<run>/<design>/`: plan.json, agents/, subtasks/, history.json, token_usage.json.

## Status (Oct 2026)

Done: install scripts, x86 + ARM Docker, README, designs rename, 6 new designs + reference TBs + mutants,
golden references for all designs, check_designs / make_reference, rescue recordings, regression check,
profiling script, Claude Haiku/Sonnet/Opus profiles in all configs, tutorial deck v3_3 (81 slides).
Open: the paper experiments (private repo), profiling all designs inside Docker
(`profile_designs.py eda` / `agent`), optional warning for mild negative slack in `evaluate_openroad.py`.
