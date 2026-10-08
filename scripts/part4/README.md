# Part 4: A Big Model Orchestrating Small Models

In Parts 2 and 3, **you** wrote the prompt of every agent. In Part 4, a **big model** (the
orchestrator, Claude Sonnet by default) does that job. It reads the spec, splits the work into subtasks and writes the
`Agent.md` of every subtask. Then **small models** (the workers) do the actual work. You write
only the orchestrator's `Agent.md`: *how* it should plan, prompt and correct its team.

The constraints are the same as in Parts 2 and 3: the RTL must pass a testbench and synthesize,
the SDC must follow its template, and the OpenROAD flow must finish and be scored.

```
                       ┌──────────────────────────── ORCHESTRATOR (big model) ────────────────────────────┐
                       │ 1. PLAN: split the pipeline into subtasks, write an Agent.md for each one         │
                       │ 3. STEP IN: read the tool logs, rewrite a worker's Agent.md, give guidance,       │
                       │             or send the flow back to an earlier subtask                           │
                       └──────────────┬──────────────────────────────────────────────▲─────────────────────┘
                                      │ Agent.md per subtask                         │ worker keeps failing
                                      ▼                                              │
 2. EXECUTE    testbench subtasks ─► sdc subtasks ─► rtl subtasks ─► config_mk subtasks      (WORKERS: small model)
                    │                    │               │                 │
 EDA checks     iverilog compile    template check   simulation +       OpenROAD flow +
                + PASS/FAIL                          Yosys synthesis    PPA evaluation
```

- **Subtasks.** Each subtask belongs to one stage (`testbench`, `sdc`, `rtl`, `config_mk`, always
  in this order) and is either:
  - **`analysis`**: notes such as a test plan or a pipeline architecture. These are not checked
    and are passed to the subtasks that "use" them.
  - **`deliverable`**: the stage's file, checked by the EDA tools.

  A stage can have several subtasks.
- **Workers** see only their own `Agent.md`, the spec, their inputs and the tool reports. After
  `worker_attempts` failed attempts, the orchestrator steps in. It can do one of three things:
  - **retry**: write a new version of the worker's `Agent.md` and/or give it guidance;
  - **redo**: go back to an earlier subtask, e.g. "the testbench expects the wrong latency";
  - **abort**.

---

## Folder layout

```
part4/
├── README.md
├── designs/                          # the YAML specs (same as Parts 2 and 3)
├── evaluation/                       # PPA scoring
├── problem/                          # ◄ what you work on
│   ├── asic_orchestrated_flow.py     # the flow (do not modify)
│   ├── eda_tools.py                  # iverilog / Yosys / OpenROAD / evaluation checks
│   ├── run_configs/
│   │   ├── 4a_orchestrator_claude.yaml   # Claude Sonnet orchestrator, Claude Haiku workers (default)
│   │   └── 4b_orchestrator_gemini.yaml   # Gemini Flash preview orchestrator, Gemini Flash Lite workers
│   ├── configs/
│   │   ├── orchestrator/  config.yaml + Agent.md   # ◄ the prompt you write
│   │   └── worker/        config.yaml              # no Agent.md: the orchestrator writes them
│   ├── templates/
│   └── PDK_files/
└── solution/                         # same files, with the golden orchestrator Agent.md
```

---

## How to run

```bash
cd /home/scripts/part4/problem            # or /home/scripts/part4/solution for the golden prompt
source /home/scripts/api_keys.sh          # API keys (see the main README)

python3 asic_orchestrated_flow.py --config run_configs/4a_orchestrator_claude.yaml   # Claude (needs ANTHROPIC_API_KEY)
python3 asic_orchestrated_flow.py --config run_configs/4b_orchestrator_gemini.yaml   # Gemini (needs GEMINI_API_KEY)
```

| Option | Overrides |
|---|---|
| `--config PATH` | The run config (default `run_configs/4a_orchestrator_claude.yaml`) |
| `--design pX.yaml` | `design.design` (`p1`, `p5`, `p7`, `p8`, `p9` are scored; `p11`–`p13` run unscored) |
| `--orchestrator-profile NAME` | The big model, a profile of `configs/orchestrator/config.yaml` |
| `--worker-profile NAME` | The small model, a profile of `configs/worker/config.yaml` |

```bash
# Quick design, Claude Opus as orchestrator, local llama3.1 as workers
python3 asic_orchestrated_flow.py --design p1.yaml \
    --orchestrator-profile claude-opus-5-5 --worker-profile ollama-llama3.1
```

### Run config (`run_configs/*.yaml`)

| Key | Meaning |
|---|---|
| `orchestrator.profile` / `workers.profile` | The big and the small model |
| `limits.max_subtasks` | Maximum size of the plan |
| `limits.max_plan_attempts` | Times the orchestrator can fix a rejected plan |
| `limits.worker_attempts` | Attempts of a worker (with the tool reports) before the orchestrator steps in |
| `limits.orchestrator_interventions` | Times the orchestrator can step in for one subtask |
| `limits.max_replans` | Times the orchestrator can send the flow back to an earlier subtask |
| `limits.report_chars` | How much of a long log the orchestrator reads (head + tail) |
| `flow.verification_mode` | `RTL`, or `BOTH` to add gate-level simulation |
| `flow.score_threshold` | `null`: accept the first scored layout. A number: the config.mk subtask must reach it, so the orchestrator keeps tuning |
| `design.*`, `paths.*` | As in Parts 2 and 3 |

---

## What you do (hands-on)

Write `problem/configs/orchestrator/Agent.md`. The flow already tells the orchestrator the fixed
facts: the stages, how every deliverable is checked, and the JSON format of a plan and a
decision. Your prompt decides the **strategy**:

1. **Planning:** how to split each stage. When is an `analysis` subtask worth its tokens?
2. **Prompting small models:** what makes an `Agent.md` work for a small model? Which facts from
   the spec must it contain? Which domain rules (from your Part 2–3 prompts) should be passed on?
3. **Stepping in:** how to find the root cause in a tool log. When should it rewrite the worker's
   prompt, and when should it go back to the testbench or the RTL architecture?

Run with an empty prompt first (the baseline), then with yours, then with the golden one in
`solution/`. Compare the results and the token reports.

**Things to think about**

- Read the generated prompts in `runs/<run>/<design>/agents/<subtask>/Agent_v*.md`. Would *you*
  pass the task with that prompt? What did the orchestrator change in `Agent_v2.md`?
- Big-model tokens are expensive and small-model tokens are cheap. Look at the
  `orchestrator (big model)` and `workers (small model)` rows of the token summary. Is planning
  and stepping in cheaper than giving every step to the big model?
- Does a better orchestrator prompt reduce the worker attempts and interventions?
- Compare with Part 2: are the generated `Agent.md` files better or worse than yours?
- Change the team: another provider (`4b`, Gemini), a stronger orchestrator (`--orchestrator-profile claude-opus-5-5`),
  or local workers (`--worker-profile ollama-llama3.1`).

---

## Outputs

Everything goes to `runs/<run>/<design>/`:

| Path | Content |
|---|---|
| `asic_orchestrated_flow.log` | Full log: prompts, answers, tool reports, decisions |
| `plan.json` | The plan: every subtask with its status, attempts, interventions |
| `agents/<subtask>/Agent_v1.md, Agent_v2.md, ...` | Every prompt the orchestrator wrote for a worker |
| `subtasks/<subtask>/attempt_N_*` | Every output and tool log of every attempt |
| `history.json` | Every attempt: subtask, prompt version, passed or not, report |
| `final/` | Final testbench, SDC, RTL, config.mk and the best layout (`6_final.odb`, `6_final.sdc`) |
| `token_usage.json` | Tokens and throughput per agent (orchestrator, `worker/<subtask>`) and per step |

At the end, the flow prints a summary of the subtasks (status, attempts, interventions, prompt
versions) and the token table, with separate **big model** and **small models** rows.

---

## Troubleshooting

| Message | Fix |
|---|---|
| `Plan rejected: ...` | The orchestrator's plan broke a rule (missing deliverable, unknown `uses`, too many subtasks). It gets the errors and tries again (`max_plan_attempts`) |
| `environment variable ... is not set` | `source /home/scripts/api_keys.sh` |
| `profile 'X' not found` | Use a profile listed in `configs/orchestrator/config.yaml` or `configs/worker/config.yaml` |
| `Run the script from its own folder` | `cd` into `part4/problem` (or `part4/solution`) |
| Rate limit (429) / overloaded (503) errors | Every model call is retried automatically (up to 6 times, with backoff). If it still fails, the attempt counts as failed and the flow goes on. If it keeps happening, wait, switch provider (`4a` ↔ `4b`) or move the workers to `ollama-llama3.1` |
| Gemini `503 UNAVAILABLE` / "model is overloaded" (run `4b`) | High demand on the Google API. Re-run the same command after a short wait. If it keeps failing, use Gemini Lite instead of Preview for the orchestrator: `--orchestrator-profile gemini_lite` |
| `Your previous answer could not be read` | The answer was cut off or incomplete: the model is asked again. Raise `max_tokens` in the profile if it repeats |
