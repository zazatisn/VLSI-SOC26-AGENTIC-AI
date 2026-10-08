# Part 2: From a Single Agent to a Team of Agents (Spec → GDS)

In Part 2, AI agents take a **YAML hardware specification** all the way to a **placed-and-routed
layout** (`6_final.odb`), which is then scored for power, performance and area (PPA).
You compare **one agent doing everything** with **a team of specialised agents**, and then
see what happens when you mix cloud and local models and add reviewer agents (validators).

```
YAML spec ─► Testbench ─► RTL ─► RTL simulation ─► SDC ─► Yosys synthesis ─► config.mk ─► OpenROAD ─► PPA score
             (iverilog)          (iverilog + vvp)                                         (ORFS)      (evaluation)
```

Every check that fails is sent back to the responsible agent as **feedback**, and the agent tries again.

---

## Contents

- [Folder layout](#folder-layout)
- [The four runs](#the-four-runs)
- [How to run](#how-to-run)
- [What you do (hands-on)](#what-you-do-hands-on)
- [The three kinds of files you can change](#the-three-kinds-of-files-you-can-change)
  - [Run configs: `run_configs/*.yaml`](#1-run-configs-run_configsyaml)
  - [Agent model configs: `configs/<agent>/config.yaml`](#2-agent-model-configs-configsagentconfigyaml)
  - [Agent prompts: `configs/<agent>/Agent.md`](#3-agent-prompts-configsagentagentmd)
- [Choosing models (profiles)](#choosing-models-profiles)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)

---

## Folder layout

```
part2/
├── README.md                     # this file
├── designs/                      # the YAML specs (p1.yaml, p5.yaml, ...)
├── evaluation/                   # PPA scoring scripts + reference results
├── problem/                      # ◄ what you work on
│   ├── asic_autonomous_flow.py   # the flow (do not modify)
│   ├── run_configs/              # one file per run (2a, 2b, 2c, 2d)
│   ├── configs/<agent>/          # config.yaml (model) + Agent.md (prompt), MINIMAL prompts
│   ├── templates/                # config.mk and SDC templates the agents fill in
│   └── PDK_files/                # gate-level simulation models (sky130hd)
└── solution/                     # reference: same files, with the golden Agent.md prompts
```

`problem/` and `solution/` are identical except for the `Agent.md` files.
In `problem/` the prompts are **empty skeletons**, so you can write your own. In `solution/` they
are our **golden** prompts. You can run either folder in exactly the same way.

The agents (one folder each in `configs/`):

| Agent | Job | Used in |
|---|---|---|
| `single_agent` | Writes testbench + RTL + SDC + config.mk in **one** answer | 2a |
| `tb_generator` | Writes the self-checking testbench | 2b, 2c, 2d |
| `rtl_generator` | Writes the synthesizable RTL | 2b, 2c, 2d |
| `sdc_generator` | Fills in the SDC timing constraints | 2b, 2c, 2d |
| `config_mk_generator` | Fills in / tunes the OpenROAD `config.mk` | 2b, 2c, 2d |
| `tb_validator` | Reviews the testbench against the spec | 2d |
| `rtl_validator` | Reviews the RTL after a failed iteration | 2d |

---

## The four runs

All four runs: **no iterative PPA optimization** (stop at the first successful layout),
**no resynthesis** (the RTL is never regenerated because of timing).

| Run | Config | Agents | Models | Validators |
|---|---|---|---|---|
| **2a** | `run_configs/2a_single_agent.yaml` | 1 single agent | Gemini Flash Lite | off |
| **2b** | `run_configs/2b_multi_agent.yaml` | TB, RTL, SDC, config.mk | all Gemini Flash Lite | off |
| **2c** | `run_configs/2c_multi_agent_mixed_models.yaml` | TB, RTL, SDC, config.mk | TB + RTL: Gemini Flash Lite · SDC + config.mk: local `llama3.1` | off |
| **2d** | `run_configs/2d_multi_agent_mixed_models_validators.yaml` | + TB and RTL validators | as 2c, validators on Gemini Flash Lite | **on** |

**Things to compare:** did the flow finish? How many iterations did each stage need? What was
the final score? How many tokens and how much time did it take? Where did the small local model
struggle, and did the validators catch bugs earlier?

---

## How to run

Inside the container (see the main [README](../../README.md) for the Docker setup):

```bash
cd /home/scripts/part2/problem          # or /home/scripts/part2/solution for the golden prompts

# API keys (once per shell, see the main README: scripts/api_keys.sh)
source /home/scripts/api_keys.sh

# Local model for runs 2c and 2d
ollama pull llama3.1

python3 asic_autonomous_flow.py --config run_configs/2a_single_agent.yaml
python3 asic_autonomous_flow.py --config run_configs/2b_multi_agent.yaml
python3 asic_autonomous_flow.py --config run_configs/2c_multi_agent_mixed_models.yaml
python3 asic_autonomous_flow.py --config run_configs/2d_multi_agent_mixed_models_validators.yaml
```

The script must be started **from its own folder** (`problem/` or `solution/`).

**Designs.** The default is `p8.yaml` (fp16 multiplier). Choose another with `--design`:

| Spec | Design | Clock | Latency (see `timing` in the spec) | PPA score |
|---|---|---|---|---|
| `p1.yaml` | `seq_detector_0011`: FSM, quick to run | 1.1 ns | Moore output, 1 cycle | yes |
| `p5.yaml` | `dot_product`: signed, 2-stage pipeline | 4.5 ns | 2 register stages | yes |
| `p7.yaml` | `exp_fixed_point`: Taylor e^x, 2-stage pipeline | 4.5 ns | 2 register stages | yes |
| `p8.yaml` | `fp16_multiplier`: combinational | 9 ns | none (combinational) | yes |
| `p9.yaml` | `fir_filter`: signed, 8 taps | 8 ns | 1 (registered output) | yes |
| `p11.yaml` | `simple_8bit_counter`: very quick | 2.0 ns | 1 | after `make_reference.py` |
| `p12.yaml` | `registered_adder_8bit`: very quick | 1.5 ns | 1 | after `make_reference.py` |
| `p13.yaml` | `sliding_window_avg_8bit` | 2.5 ns | 1 | after `make_reference.py` |
| `p14.yaml` | `alu_8bit`: 8 operations, zero/carry flags | 2.5 ns | 1 | after `make_reference.py` |
| `p15.yaml` | `uart_tx`: UART transmitter, FSM + counters | 2.0 ns | frame of 10 × 8 cycles | after `make_reference.py` |
| `p16.yaml` | `sync_fifo`: 8 × 8 FIFO, full/empty | 2.0 ns | 1 (registered read) | after `make_reference.py` |

```bash
python3 asic_autonomous_flow.py --config run_configs/2b_multi_agent.yaml --design p1.yaml
```

Every spec has a **`timing`** section that defines the latency, the reset behaviour and how its
sample values line up with the clock. Some also have an **`arithmetic`** section with the exact
formula and reference values. The testbench agent and the RTL agent must both follow it, or a
correct RTL fails a testbench that checks one cycle too early or too late.

> `p11`–`p16` get a PPA score once their reference results exist: run
> `python3 ../../reference/make_reference.py` once in the container (see `scripts/reference/README.md`).
> Until then they run the whole flow and the layout is accepted without a score.

Every design also has a **reference testbench** (`evaluation/visible/pN/*_tb.v`) and a **golden RTL**
(`scripts/reference/pN/`). The flow only runs the testbench the agent wrote, so use them to check
the agent's work independently:

```bash
cd /home/scripts/reference
# Sign-off: is the agent's final RTL really correct?
python3 check_designs.py -d p8 --rtl ../part2/problem/runs/2b_multi_agent/solution/p8/fp16_multiplier.v
# How strong is the agent's testbench? (it must pass the golden RTL and fail on planted bugs)
python3 check_designs.py -d p8 --tb ../part2/problem/runs/2b_multi_agent/results/p8/tb_gen_flow/fp16_multiplier_tb.v
```

---

## What you do (hands-on)

You do **not** modify the script. You improve the agents through their `Agent.md` files in
`problem/configs/<agent>/`:

1. Run **2a** and **2b** with the empty prompts to get a baseline. Look at the log: which
   stage fails, and why? (Start with a quick design: `--design p1.yaml` or `p11.yaml`.)
2. Write a `# Role and Objective` and `# Mandatory Rules` for each agent. Turn every repeated
   mistake you see in the log into a rule.
3. Write `# Feedback` messages that tell the agent **how** to fix each failure, not only what failed.
4. Run again and compare with the baseline, then with the golden prompts in `solution/`.

**Things to think about**

- The single agent has to follow **all** the rules at once. Does it do better or worse than the team?
- Which agents can run on a small local model (2c), and which need a stronger one?
- What should a validator check that the simulator cannot (2d)? Is it worth the extra tokens?
- Do your rules generalize across designs (`--design p1.yaml`, `p5.yaml`, `p14.yaml` ...)?
- The flow says PASS. Does sign-off agree? How many planted bugs does the agent's testbench catch?

---

## The three kinds of files you can change

| What you want to change | File |
|---|---|
| Which run: mode, models per agent, validators, design, iterations, ... | `run_configs/*.yaml` |
| Which models (profiles) an agent can use, and its default one | `configs/<agent>/config.yaml` |
| An agent's instructions, rules and feedback messages | `configs/<agent>/Agent.md` |

### 1. Run configs: `run_configs/*.yaml`

| Section | Key | Meaning |
|---|---|---|
| `agents` | `mode` | `single` (one agent for everything) or `multi` (one agent per step) |
| | `default_profile` | Profile for every agent (`null` = each agent's `active_profile`) |
| | `<agent>.profile` | Profile for one agent, e.g. `"ollama-llama3.1"` (`null` = not set) |
| | `<agent>.enabled` | Turn the validators (and the MIPROv2 teacher) on/off |
| `design` | `design` | Spec in `../designs/`, e.g. `p8.yaml` |
| | `orfs_platform` | ORFS platform (`sky130hd`) |
| | `pdk_rtl_path` | Gate-level simulation models (`./PDK_files/`) |
| | `orfs_dir` | OpenROAD-flow-scripts folder (`null` = auto-detect) |
| `flow` | `verification_mode` | `RTL`, or `BOTH` to add post-synthesis (gate-level) simulation |
| | `skip_rtl_validator` | `true` skips the RTL validator even if it is enabled |
| | `iterative_optimization` | `true`: keep tuning `config.mk` after a successful layout (Part 3) |
| | `score_threshold` | Stop the optimization when the score reaches this value |
| | `enable_resynthesis` | `true`: regenerate the RTL when timing fails by far, WNS < -0.5 ns (Part 3) |
| | `max_resynthesis_attempts` | Maximum RTL regenerations because of timing |
| | `rtl_gen_dspy_mode` | `Simple Run` (default), `Optimize` / `Inference` (DSPy MIPROv2, multi mode) |
| `iterations` | `max_tb_gen_iters`, `max_rtl_gen_iters`, `max_sdc_gen_iters`, `max_physical_iters`, `max_single_agent_iters` | Iteration limits |
| `overrides` | `tb_path`, `sdc_path`, `rtl_path`, `config_path` | Use an existing file and skip that stage (multi mode) |
| `paths` | `results_dir`, `solutions_dir`, `log_file`, templates, ... | Where everything is read from / written to |

To create your own run, copy a run config, change it, and pass it with `--config`.

### 2. Agent model configs: `configs/<agent>/config.yaml`

Each file lists **profiles** (model + settings) and selects the default one with `active_profile`
(here `gemini_lite` for every agent):

```yaml
active_profile: "gemini_lite"

profiles:
  ollama-llama3.1:
    model: "ollama_chat/llama3.1"
    api_base: "http://localhost:11434"
    temperature: 0.0
    cache: true

  gemini_lite:
    model: "gemini/gemini-3.1-flash-lite"
    api_key: "$GEMINI_API_KEY"         # read from the environment
    cache: true
```

- `model` is required. Every other key is passed to `dspy.LM`, e.g. `api_base`, `api_key`,
  `temperature`, `cache`, `max_tokens`.
- **API keys** are never written in the configs: `api_key: "$NAME"` reads the environment
  variable `NAME`. Put your keys once in `scripts/api_keys.sh` and load them with
  `source /home/scripts/api_keys.sh` (see the main README). An empty `api_key` also falls back
  to the provider's standard variable.
- **Add a model:** add a profile to the agent's `config.yaml`, then select it in a run config.
- `cache: true` stores prompts and answers, so an identical request is not paid for twice.
  Use `cache: false` to get a fresh answer every time.
- The single agent writes four files in one answer. If its output gets cut off, add
  `max_tokens: 16000` to its profile.

### 3. Agent prompts: `configs/<agent>/Agent.md`

Same idea as Part 1. Every `Agent.md` has these sections:

```markdown
# Role and Objective      <- the agent's instructions
# Mandatory Rules         <- the rules the agent must follow
# Output Format           <- optional, appended to the rules
# Feedback                <- the messages sent back when a check fails
## syntax_error
Fix the following testbench syntax errors/warnings:
{errors}
```

- Write anything under the headings. `<!-- comments -->` are ignored, so use them for notes.
- **Keep the headings** (`# Role and Objective`, `# Mandatory Rules`, `# Feedback`) and the
  `## <key>` names: the flow looks them up by name.
- `{placeholders}` in a feedback message are filled in by the flow (logs, issues, ...).
  You choose where they go. A placeholder that you rename stays as literal text.
- **Empty sections are allowed.** An empty role or rules section means the agent gets no
  instructions or rules. An empty feedback message sends `Check failed: <key>` and the raw
  placeholder values. The flow prints a warning for each empty section.
- Special placeholders:

| Where | Placeholder | Replaced with |
|---|---|---|
| validator rules | `{tb_generator_rules}` / `{rtl_generator_rules}` | the generator's Mandatory Rules |
| any rules | `{<agent>_rules}` | that agent's Mandatory Rules |
| `config_mk_generator` / `single_agent` role | `{max_iters}` | the iteration limit of that loop |

**Feedback keys used by the flow:**

| Agent | `## key` → placeholders |
|---|---|
| `tb_generator` | `initial`, `syntax_error` → `{errors}`, `validator_mismatch` → `{issues}`, `missing_pass_message` |
| `sdc_generator` | `initial`, `structure_violation` → `{issues}`, `unfilled_placeholders` → `{placeholders}` |
| `rtl_generator` | `initial`, `timing_reminder`, `rtl_simulation_failed` → `{log}`, `synthesis_failed` → `{issues}`, `post_synthesis_failed` → `{log}`, `validator_issues` → `{report}`, `timing_resynthesis` → `{eval_log}` |
| `config_mk_generator` | `initial`, `unfilled_placeholders` → `{placeholders}`, `orfs_failed` → `{issues}`, `score_report` → `{score}` `{eval_log}`, `severe_timing_warning`, `optimize_further` |
| `single_agent` | `initial`, `stage_failed` → `{stage}` `{passed}` `{details}`, `tb_syntax_error` → `{errors}`, `tb_missing_pass_message`, `rtl_simulation_failed` → `{log}`, `sdc_structure_violation` → `{issues}`, `sdc_unfilled_placeholders` → `{placeholders}`, `synthesis_failed` → `{issues}`, `post_synthesis_failed` → `{log}`, `config_unfilled_placeholders` → `{placeholders}`, `orfs_failed` → `{issues}`, `timing_resynthesis` → `{eval_log}`, `score_report` → `{score}` `{eval_log}`, `severe_timing_warning`, `optimize_further` |

The validators have no feedback section. Their answer must start with `Match` or `Mismatch`.

> The testbench must print `PASS` / `FAIL` for every check: the flow decides whether the
> simulation passed by looking for these words in the log.

---

## Choosing models (profiles)

The profile of each agent is chosen in this order (the first one that is set wins):

1. `--agent-profile AGENT=PROFILE` (command line, one agent, repeatable)
2. `--profile PROFILE` (command line, every agent)
3. `agents.<agent>.profile` (run config)
4. `agents.default_profile` (run config)
5. `active_profile` (`configs/<agent>/config.yaml`)

```bash
# Run 2b with everything on the local model
python3 asic_autonomous_flow.py --config run_configs/2b_multi_agent.yaml --profile ollama-llama3.1

# Run 2c, but the config.mk agent on Gemini too
python3 asic_autonomous_flow.py --config run_configs/2c_multi_agent_mixed_models.yaml \
    --agent-profile config_mk_generator=gemini_lite

# Run 2a with another design
python3 asic_autonomous_flow.py --config run_configs/2a_single_agent.yaml --design p1.yaml
```

| Option | Overrides |
|---|---|
| `--config PATH` | The run config file |
| `--mode single\|multi` | `agents.mode` |
| `--design pX.yaml` | `design.design` |
| `--profile NAME` | The profile of every agent |
| `--agent-profile AGENT=NAME` | The profile of one agent |

The profile must exist in the agent's `config.yaml`. If it does not, the flow stops and lists
the available profiles.

---

## Outputs

Every run writes to its own folder, `runs/<run name>/`:

| Path | Content |
|---|---|
| `runs/<run>/asic_autonomous_flow.log` | Full log: every prompt, answer, tool output and score |
| `runs/<run>/token_usage.json` | Tokens (prompt / completion / total), time and TPM / TPS of every LM call, per agent and step |
| `runs/<run>/results/<design>/tb_gen_flow/` | Testbench of every iteration |
| `runs/<run>/results/<design>/rtl_gen_flow/` | RTL, simulation and Yosys logs of every iteration |
| `runs/<run>/results/<design>/sdc_gen_flow/` | SDC of every iteration |
| `runs/<run>/results/<design>/physical_flow/` | config.mk, ORFS logs and evaluation of every iteration |
| `runs/<run>/solution/<design>/` | Best result: `6_final.odb`, `6_final.sdc`, final RTL |

`runs/<run>/solution/<design>/` is emptied at the start of each run of that run config.

**Tokens and throughput.** As in Part 1, every LM call prints its tokens and throughput:

```
[TOKENS] rtl_generator | RTL generation, iteration 2 | gemini/gemini-3.1-flash-lite
Call Time:       6.41s
Tokens Used:     Prompt: 3512 | Completion: 1480 | Total: 4992
Throughput:      46,728.5 TPM (778.81 TPS)
```

At the end of the run (also when it stops early) a summary table shows the calls, tokens, LM time
and TPM **per agent**, followed by every step. The same data is saved in `runs/<run>/token_usage.json`,
so you can compare runs 2a–2d. A call answered from the cache (`cache: true`) is marked
`cached` and uses 0 tokens: set `cache: false` in the profiles for a fair token comparison.

---

## Troubleshooting

| Message | Fix |
|---|---|
| `Run the script from its own folder` | `cd` into `part2/problem` (or `part2/solution`) first |
| `flow config file not found` | Pass a run config: `--config run_configs/<run>.yaml` |
| `profile 'X' not found in configs/<agent>/config.yaml` | Add the profile to that file, or use one of the listed profiles |
| Authentication / API key errors, `environment variable ... is not set` | `source /home/scripts/api_keys.sh` (and check the key in `scripts/api_keys.sh`) |
| Ollama connection errors / model not found | `ollama pull llama3.1` (the server starts with the container) |
| Rate limit errors (free tier) | Wait a bit, or move some agents to the local model |
| `503 UNAVAILABLE` / "model is overloaded" / `429 RESOURCE_EXHAUSTED` (Gemini) | High demand on the Google API. Re-run the same command after a short wait. If it keeps failing, use `gemini_lite` instead of `gemini_preview` (`active_profile` in the agent's `config.yaml`), or move some agents to the local model |
| `OpenROAD evaluation failed` | Check `runs/<run>/results/<design>/physical_flow/*eval*.log`. Designs without reference results (`p11`–`p16` until you run `reference/make_reference.py`) are not scored |
| RTL keeps failing a simulation with values one cycle early/late | The testbench and the RTL disagree on the latency: both prompts must follow the spec's `timing` section |
| `Tool 'openroad' not found in PATH` | Run inside the Docker container |
