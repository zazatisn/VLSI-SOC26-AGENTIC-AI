# Profiling the designs

`profile_designs.py` measures, for every design and run config:

- **time**: wall time of the run, split into LLM time (from `token_usage.json`) and EDA time (the rest)
- **OpenROAD**: number of OpenROAD runs, how many reached the final layout, and their time
- **iterations**: RTL simulation iterations
- **tokens**: total, prompt, completion, per agent, and the models used
- **result**: success / failed / timeout and the PPA score

Everything is saved as CSV in `results/` and summarized in `results/profile_report.md`.
Run it inside the Docker container (or a local install) from `scripts/profile/`.

## 1. EDA only (no LLM, no API cost)

The golden design of every pN through the same tools the flows use: reference simulation
(`check_designs.py`), the full OpenROAD flow with the golden `config.mk`, and the PPA measurement.
This is the pure tool time per design, a lower bound for every agent run.

```bash
python3 profile_designs.py eda -r 3              # every design, 3 repeats (~30-40 min)
python3 profile_designs.py eda -d p11 -d p8 -r 5
```

It does not change the references (`evaluation/visible/pN/pN.json`).

## 2. Agent runs

The real flows from the `solution/` folders (golden prompts): every run config x design x repeat.
Each run uses a fresh DSPy cache, so every answer comes from the model and the tokens and latency are real.

```bash
# plan and time estimate only
python3 profile_designs.py agent --runs 2b_multi_agent,3_multi_agent_collaboration -d p11 -d p8 -r 3 --dry-run

# a pilot: one easy, one medium and one hard design, plus p5 for the Part 3 loops
python3 profile_designs.py agent --runs 2a_single_agent,2b_multi_agent,3_multi_agent_collaboration,4a_orchestrator_claude \
        -d p11 -d p14 -d p8 -d p5 -r 3

# every design (default) with a local model, a pause between runs for API rate limits
python3 profile_designs.py agent --runs 2b_multi_agent --extra-args "--profile ollama-llama3.1" -r 3 --pause 10
```

| option | meaning |
|---|---|
| `--runs` | comma separated run configs: `2a_single_agent`, `2b_multi_agent`, `2c_multi_agent_mixed_models`, `2d_multi_agent_mixed_models_validators`, `3_multi_agent_collaboration`, `4a_orchestrator_claude`, `4b_orchestrator_gemini` |
| `-d pN` | design (repeatable, default: all 11) |
| `-r N` | repeats per run config and design (default 3) |
| `--timeout S` | stop a run after S seconds (default 3600) |
| `--variant problem` | use the attendees' `problem/` prompts instead of `solution/` |
| `--extra-args "..."` | passed to the flow, e.g. `"--profile ollama-llama3.1"` |
| `--pause S` | wait between runs |
| `--keep-layouts` | keep `.odb` / `.gds` (removed by default to save space) |
| `--verbose` | show the flow output |

The command is **resumable**: finished runs are in `results/agent_runs.csv` and are skipped.
Run folders go to `results/runs/` (git-ignored); the CSV tables are small and can be committed.

Do not run two runs of the **same design** at the same time: they share the ORFS design folder.
Different designs in parallel (e.g. two terminals with different `-d`) are fine.

## 3. Report

```bash
python3 profile_designs.py harvest   # import runs already in the repo (rescue recordings, golden OpenROAD logs)
python3 profile_designs.py report    # -> results/profile_report.md
```

## What we measured so far (Oct 2026, from the rescue recordings)

| run | design | runs | success | wall time | of which LLM | tokens |
|---|---|---|---|---|---|---|
| 2a single agent | p1 | 1 | 1/1 | 2.1 min | 64 s | 27k |
| 2b multi-agent | p1 | 1 | 1/1 | 81 s | 37 s | 16k |
| 2b multi-agent | p8 | 3 | 0/3 | 64 s | 56 s | 52k |
| 2c hybrid (local llama) | p1 | 3 | 0/3 | 2.1 min | 91 s | 15k |
| 2d hybrid + validators | p1 | 3 | 0/3 | 1.9 min | 108 s | 61k |
| 3 feedback loops | p5 | 3 | 0/3 | 2.4 min | 100 s | 57k |
| 4a orchestrator | p1, p14 | 2 | 2/2 | 3.2 min | ~2 min | 41-48k |
| 4a orchestrator | p8 | 1 | - | 10.6 min | 8.5 min | 218k |

Golden OpenROAD flow (no LLM): p11 19 s, p15 23 s, p16 38 s, p12 39 s, p13 41 s, p14 41 s; p8 41-88 s per run.

- The LLM is the bottleneck: 50-95 % of the wall time. OpenROAD stays under a minute except for p8.
- Failed runs stop early (the RTL loop runs out of iterations), so a short run is often a failed one.
- 2c / 2d had some cached answers in these recordings, so their times are slightly low.

### Design tiers

| tier | designs | why |
|---|---|---|
| easy | p11, p12, p1, p15 | < 160 cells, OpenROAD ~20-40 s |
| medium | p13, p14, p16, p5 | 200-360 cells, pipelining or a FIFO |
| hard | p7, p9, p8 | arithmetic datapaths; p8 failed in every 2b recording |

p9 and p13 have negative slack in their golden run, so their golden layout scores 75 instead of 80.

Rough cost of a full matrix: 11 designs x 5 run configs x 5 repeats = 275 runs, ~2.5 min each
-> about 12-15 h sequential, ~4 h with 3-4 designs in parallel (API rate limits permitting).
