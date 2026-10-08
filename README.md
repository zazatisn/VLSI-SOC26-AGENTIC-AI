# VLSI-SoC 2026 Tutorial: Agentic AI in EDA

Hands-on material for the VLSI-SoC 2026 tutorial on **agentic AI for Electronic Design Automation**. The tutorial is split into parts, each with practical problems where you improve an AI agent's behavior by steering it with better prompts, rules, and training examples, and then measure the result.

> **Status:** Parts 1, 2, 3 and 4 are available.

---

## Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
  - [1. Build the Docker image](#1-build-the-docker-image)
  - [2. Run the container](#2-run-the-container)
  - [3. Open a second terminal](#3-open-a-second-terminal-optional)
  - [Alternative: local install (no Docker)](#alternative-local-install-no-docker)
- [What is in the image](#what-is-in-the-image)
- [Repository structure](#repository-structure)
- [Configuring the agent](#configuring-the-agent)
- [Part 1](#part-1)
  - [Problem 1: Sentiment Analysis](#problem-1-sentiment-analysis)
  - [Problem 2: Google Verification (ICLAD 2025)](#problem-2-google-verification-iclad-2025)
- [Part 2](#part-2)
- [Part 3](#part-3)
- [Part 4](#part-4)

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- Access to an LLM, either a hosted API (you will need an API key) or a local model served by Ollama (already included in the image)
- Enough disk space, memory and time for the first build: it builds OpenROAD (with Bazel) and Yosys from source, and clones OpenROAD-flow-scripts
- Basic EDA knowledge. No AI expertise is required!

## Setup

### 1. Build the Docker image

From the root of this repository (where the `Dockerfile` is):

**Windows (PowerShell):**

```bash
docker build --platform linux/amd64 -t vlsi-soc26-ai .
```

**Linux / macOS:**

```bash
docker build -t vlsi-soc26-ai .
```

The first build takes a long time (OpenROAD and Yosys are built from source) and needs plenty of RAM. You only build it once.

### 2. Run the container

**Windows (PowerShell):**

```powershell
docker run --rm -it -v .\scripts\:/home/scripts vlsi-soc26-ai
```

**Linux / macOS:**

```bash
docker run --rm -it -v "$(pwd)/scripts":/home/scripts vlsi-soc26-ai
```

This mounts the local `scripts/` folder into the container at `/home/scripts`, so anything you edit on your machine (for example `Agent.md` or `trainset.json`) is immediately visible inside the container, and anything the scripts write persists on your machine.

Once inside the container:

```bash
cd /home/scripts/part1
```

> `--rm` deletes the container when you exit. Your work is safe as long as it lives in the mounted `scripts/` folder.

### 3. Open a second terminal (optional)

To get another shell in the **same** running container without stopping it, give the container a name when you start it:

```powershell
docker run --rm -it --name vlsi -v .\scripts\:/home/scripts vlsi-soc26-ai
```

Then, from another terminal:

```powershell
docker exec -it vlsi bash
```

Closing the second shell does not affect the first. If you exit the original session, the container stops and all attached shells close.

### Alternative: local install (no Docker)

If you prefer to run the tutorial on your own machine, `install/` has scripts that install the
same tools as the Docker image under one folder (default `~/eda`, no files in `/home`):

| System | Script | Status |
| --- | --- | --- |
| Ubuntu 22.04 / 24.04 / 26.04 | `install/install_ubuntu.sh` | Full toolchain, all parts |
| macOS 14+ (Homebrew) | `install/install_macos.sh` | Best effort: OpenROAD has no official macOS support |

```bash
bash install/install_ubuntu.sh            # run as your user, it asks for sudo when needed
# options: --prefix DIR  --jobs N  --skip-openroad  --openroad-bin PATH  --skip-ollama  --no-model
```

The script installs:

- **apt packages and iverilog**;
- **Python**: a venv with `dspy`, `pyyaml` and `ollama` (this avoids the pip error of Ubuntu 24.04+);
- **EDA tools**: Yosys and OpenROAD built from source (Bazel), the KLayout `.deb` for your Ubuntu
  version (or the Ubuntu package), and a clone of OpenROAD-flow-scripts;
- **Ollama** with `llama3.1`.

It also writes `~/eda/vlsi_soc_env.sh` and loads it from `~/.bashrc`. That file:

- sets `OPENROAD_EXE`, `YOSYS_EXE` and `ORFS_DIR`, and puts `openroad` in the `PATH`;
- activates the venv;
- loads `scripts/api_keys.sh`;
- starts `ollama serve` if it is not running.

`ORFS_DIR` overrides `design.orfs_dir` of the run configs, so the configs work unchanged. Plan
for about 40 GB of disk, 16 GB of RAM (use `--jobs 2` with less) and 1 to 2 hours for the
OpenROAD build. You can re-run the script: finished steps are skipped.

Locally, replace `/home/scripts` in the commands of this README with `<repo>/scripts`:

```bash
source ~/eda/vlsi_soc_env.sh               # or open a new terminal
cd <repo>/scripts/part2/solution
python3 asic_autonomous_flow.py --config run_configs/2a_single_agent.yaml
```

On macOS, Homebrew provides:

- the tools: Icarus Verilog, Yosys, KLayout, Ollama;
- the GNU make, time, sed and coreutils that OpenROAD-flow-scripts needs.

The script then tries the OpenROAD Bazel build. If that build fails, Part 1 and the
testbench/RTL steps still run natively; for the full flows use the Docker image.

## What is in the image

| Tool | Purpose |
| --- | --- |
| Ubuntu 22.04 | Base system |
| [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) | Place and route (built from source with Bazel; `openroad` is in the `PATH`) |
| [Yosys](https://github.com/YosysHQ/yosys) | Logic synthesis (built from source, at `/usr/local/bin/yosys`) |
| [KLayout](https://www.klayout.de/) | Layout viewer, used by the flow to merge the final GDS |
| [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) | RTL-to-GDS flow (cloned in `/home`) |
| [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`, `vvp`) | Verilog simulation |
| [Ollama](https://ollama.com/) | Local LLM server, started automatically when the container starts |
| Python 3 + [DSPy](https://dspy.ai), `ollama`, `pyyaml` | Agent framework and utilities |

The `OPENROAD_EXE` and `YOSYS_EXE` environment variables are already set.

## Choosing a model

The tutorial works with both local and cloud models. All agents are built in Python with [DSPy](https://dspy.ai), which handles the model setup and lets us compose multi-agent systems. You pick the provider and model in each problem's `config.yaml`.

### Option A: Local SLMs with Ollama

Ollama is installed in the image and its server starts automatically when the container starts, so you only need to download a model. Inside the container:

```bash
ollama pull <model-name>
```

**Recommended models:**

| Model | Command |
| --- | --- |
| `llama3.1` | `ollama pull llama3.1` |
| `qwen2.5-coder:7b` | `ollama pull qwen2.5-coder:7b` |

Then select its profile in `config.yaml` (`active_profile`).

Notes:

- Local models run on your own machine, so they need no API key and no internet access after the download. Speed depends on your hardware, and a GPU helps a lot.
- Because the container is started with `--rm`, models downloaded inside it are deleted when you exit. To keep them between sessions, mount a volume for Ollama's model folder, for example `-v ollama-models:/home/.ollama` (the image sets `HOME=/home`).

### Option B: Cloud LLMs with API keys

You can also use hosted models by providing an API key.

**Recommended free option:** the [Google Gemini API](https://ai.google.dev/), which has a free tier suitable for this tutorial.

Then select the Gemini profile in `config.yaml`. Other providers supported by DSPy also work, using their own API key variable.

### API keys: one file for all parts

API keys are **never written in the config files**. Every config reads its key from an environment
variable (`api_key: "$GEMINI_API_KEY"`), and one script sets these variables for all parts:

1. Copy the template and fill in the keys you have (leave the others empty):

   ```bash
   cp scripts/api_keys.example.sh scripts/api_keys.sh
   ```

2. Start (or restart) the container. Every container shell loads `scripts/api_keys.sh`
   **automatically** and prints which keys are set. The same keys work for Parts 1, 2, 3 and 4.
   After you edit the file, reload it in the open shell:

   ```bash
   source /home/scripts/api_keys.sh
   ```

| Variable | Provider |
| --- | --- |
| `GEMINI_API_KEY` | Google Gemini |
| `ANTHROPIC_API_KEY` | Anthropic Claude |
| `OPENAI_API_KEY` | OpenAI |
| `GROQ_API_KEY` | Groq |

`scripts/api_keys.sh` is listed in `.gitignore`, so your keys are never committed.

> Free tiers have rate limits, so the iterative scripts may be slowed down or throttled. If that happens, wait a bit, reduce the number of runs, or switch to a local model.

> **Google API under high demand.** During busy hours (for example, when the whole room runs at
> once) the Gemini API can answer with `503 UNAVAILABLE` / "The model is overloaded" or
> `429 RESOURCE_EXHAUSTED`. This is on Google's side, not a bug in your prompt or setup:
> 1. **Re-run** the same command after a short wait.
> 2. If it keeps failing, use **Gemini Lite instead of Preview**. Set `active_profile: "gemini_lite"`
>    in the `config.yaml` of the agent, or pass `--orchestrator-profile gemini_lite` in Part 4.
>    `gemini-3-flash-preview` is a preview model with less capacity, so it is overloaded first.
> 3. Or move some agents to a local model (`ollama-llama3.1`).

## Repository structure

```
.
├── Dockerfile
├── README.md
├── install/               # local install without Docker (Ubuntu, macOS)
└── scripts/
    ├── part1/
    │   ├── sentiment_analysis/
    │   │   ├── problem/       # what you work on
    │   │   │   ├── Agent.md
    │   │   │   ├── config.yaml
    │   │   │   ├── trainset.json
    │   │   │   ├── testset.json
    │   │   │   └── main.py
    │   │   └── solution/      # reference solution
    │   └── google_verification/
    │       ├── problem/       # what you work on
    │       │   ├── Agent.md
    │       │   ├── config.yaml
    │       │   ├── single_pass.py
    │       │   └── iterative.py
    │       └── solution/      # reference solution
    ├── api_keys.example.sh    # template for your API keys (copy to api_keys.sh)
    ├── part2/
    │   ├── README.md          # full guide for Parts 2 and 3
    │   ├── problems/visible/  # YAML hardware specs
    │   ├── evaluation/        # PPA scoring
    │   ├── problem/           # what you work on
    │   │   ├── asic_autonomous_flow.py
    │   │   ├── run_configs/   # 2a, 2b, 2c, 2d
    │   │   └── configs/<agent>/
    │   │       ├── Agent.md
    │   │       └── config.yaml
    │   └── solution/          # reference solution
    ├── part3/                 # same layout as part2, run config 3
    └── part4/
        ├── README.md          # full guide for Part 4
        ├── problem/           # what you work on
        │   ├── asic_orchestrated_flow.py
        │   ├── run_configs/   # 4a (Claude), 4b (Gemini)
        │   └── configs/
        │       ├── orchestrator/   # Agent.md (your prompt) + config.yaml (big model)
        │       └── worker/         # config.yaml (small model), prompts are generated
        └── solution/          # reference solution
```

Each problem has a `problem/` folder (the starting point) and a `solution/` folder (a reference to compare against once you have tried it yourself).

## Configuring the agent

Every problem comes with two files that control the agent:

- **`config.yaml`** selects which API and model the agent uses (a hosted provider, or a local model through Ollama). Keys come from `api_keys.sh` (see [API keys](#api-keys-one-file-for-all-parts)).
- **`Agent.md`** contains the information and rules given to the agent. This is the main lever you will use to change the agent's behavior.

Load your keys (`source /home/scripts/api_keys.sh`) and set `active_profile` in `config.yaml` to a model you have access to, then work on the problem.

---

## Part 1

Part 1 introduces two ways of improving an agent without changing the model: refining its prompt from examples, and giving it better rules.

### Problem 1: Sentiment Analysis

**Goal:** build a training set that makes the refined agent **outperform the non-refined (baseline) agent** on a held-out test set.

**What you do**

1. Open `trainset.json` in `sentiment_analysis/problem/`.
2. Fill it with sentences and their sentiment labels.
3. Run the script (from the `problem/` folder):

   ```bash
   python3 main.py
   ```

The agent's prompt is refined using your training set, and the refined agent is then evaluated against the baseline on `testset.json`.

**Success criterion:** the refined agent scores higher than the baseline on `testset.json`.

**Things to think about**

- Which kinds of sentences does the baseline get wrong?
- Is your training set balanced across labels?
- Does your training set cover tricky cases (negation, sarcasm, mixed sentiment)?
- Avoid copying test sentences into the training set. The point is to generalize.

### Problem 2: Google Verification (ICLAD 2025)

This problem is based on the **ICLAD 2025** challenge.

**The task:** you are given a natural-language **specification** and **31 candidate RTL implementations** (mutants) of a design. Exactly one is correct. The agent must identify the correct RTL by:

1. Generating a **testbench** from the specification.
2. Compiling and simulating each candidate with `iverilog` and `vvp`.
3. Comparing the results to decide which RTL is correct.

**Available designs**

| Design | | |
| --- | --- | --- |
| `cdc_fifo_flops_push_credit` | `counter` | `credit_receiver` |
| `ecc_sed_encoder` | `enc_bin2gray` | `enc_bin2onehot` |
| `fifo_flops` | `lfsr` | `shift_left` |
| `shift_right` | | |

**Scripts**

| Script | Description |
| --- | --- |
| `single_pass.py` | The agent generates the testbench and decides in a single pass |
| `iterative.py` | The agent iterates: it refines its testbench and reasoning over multiple rounds |

**Run**

```bash
python3 <script> <design>
```

For example:

```bash
python3 single_pass.py counter
python3 iterative.py fifo_flops
```

**Your goal:** you do **not** modify the scripts. Instead, add rules to **`Agent.md`** so the agent performs better at this task: writing more discriminating testbenches and identifying the correct RTL more reliably.

**Things to think about**

- What makes a testbench good at telling a correct design from a subtly wrong one (corner cases, reset behavior, boundary values, ordering)?
- Which mistakes does the agent make repeatedly? Turn each into a rule.
- Do your rules generalize across designs, or are they specific to one? Rules that only fix one design will not help on the others.
- Compare `single_pass.py` and `iterative.py` with and without your rules.

---

## Part 2

Part 2 goes from a **YAML hardware specification** to a **placed-and-routed layout**, scored for
power, performance and area (PPA). Agents write the testbench, the RTL, the SDC constraints
and the OpenROAD `config.mk`. Icarus Verilog, Yosys and OpenROAD check every step, and every
failure is fed back to the agent that has to fix it.

**The runs** (from `part2/problem/` or `part2/solution/`). None of them use iterative PPA
optimization or resynthesis:

| Run | What it shows | Command |
| --- | --- | --- |
| 2a | **One agent** for the whole flow (Gemini Flash Lite) | `python3 asic_autonomous_flow.py --config run_configs/2a_single_agent.yaml` |
| 2b | **One agent per step**: TB, RTL, SDC, config.mk (Gemini Flash Lite) | `python3 asic_autonomous_flow.py --config run_configs/2b_multi_agent.yaml` |
| 2c | **Mixed models**: TB + RTL on Gemini Flash Lite, SDC + config.mk on local `llama3.1` | `python3 asic_autonomous_flow.py --config run_configs/2c_multi_agent_mixed_models.yaml` |
| 2d | As 2c, plus **validator agents** that review the TB and the RTL | `python3 asic_autonomous_flow.py --config run_configs/2d_multi_agent_mixed_models_validators.yaml` |

Before running: `source /home/scripts/api_keys.sh` and, for 2c/2d, `ollama pull llama3.1`.
Pick a design with `--design p1.yaml` (`p1`, `p5`, `p7`, `p8`, `p9` are scored; `p11`–`p13` are quick and unscored).

**Your goal:** you do **not** modify the script. As in Part 1, each agent has its own `Agent.md`
(`problem/configs/<agent>/Agent.md`). These start almost empty: write the role, the rules and
the feedback messages, then compare with the baseline and with the golden prompts in `solution/`.
Each agent's model is chosen in `configs/<agent>/config.yaml` and in the run config.

Like Part 1, every LM call prints its tokens and throughput (TPM / TPS). At the end, a summary
per agent and per step is printed and saved in `runs/<run>/token_usage.json`, so the runs can be compared.

See [`scripts/part2/README.md`](scripts/part2/README.md) for the full guide.

**Things to think about**

- Does one agent with all the rules do better or worse than a team of specialists?
- Which steps can a small local model handle, and which need a stronger model?
- Do the validators catch bugs earlier, and is it worth the extra tokens?

## Part 3

Part 3 makes the agents **collaborate in loops** (`part3/`, same layout as Part 2):

- **Iterative optimization:** after a successful layout, the `config.mk` agent gets the PPA
  report and keeps improving the score.
- **Resynthesis:** when timing fails by far, the physical flow sends the RTL agent back to
  restructure the design.

```bash
cd /home/scripts/part3/problem
python3 asic_autonomous_flow.py --config run_configs/3_multi_agent_collaboration.yaml
```

**Your goal:** write the rules and feedback that make the loops converge, mainly the
`config_mk_generator` and `rtl_generator` `Agent.md` files. See
[`scripts/part3/README.md`](scripts/part3/README.md).

## Part 4

In Part 4, a **big model orchestrates small models**. The orchestrator (Claude Sonnet by default,
or Gemini Flash preview) reads the spec and splits the pipeline (testbench → SDC → RTL → OpenROAD) into
subtasks. Each stage can have several subtasks, such as a test plan or a pipeline architecture
note. The orchestrator also **writes the `Agent.md` of every subtask**. Small worker models
(Claude Haiku by default, or Gemini Flash Lite) do the work, and the same EDA checks as in Parts 2 and 3 verify it. When a
worker keeps failing, the orchestrator reads the logs and does one of two things:

- rewrites the worker's prompt or gives it guidance;
- sends the flow back to an earlier subtask, e.g. to fix a wrong testbench.

```bash
cd /home/scripts/part4/problem
python3 asic_orchestrated_flow.py --config run_configs/4a_orchestrator_claude.yaml   # Claude Sonnet + Claude Haiku workers
python3 asic_orchestrated_flow.py --config run_configs/4b_orchestrator_gemini.yaml   # Gemini preview + Gemini Lite workers
```

**Your goal:** write only the orchestrator's `Agent.md` (`problem/configs/orchestrator/Agent.md`).
It decides how the orchestrator plans, how it prompts small models, and how it steps in when they
fail. Then read the prompts it generated (`runs/<run>/<design>/agents/`) and compare the token cost
of the big and the small models. See [`scripts/part4/README.md`](scripts/part4/README.md).

**Things to think about**

- Are the generated worker prompts better or worse than the ones you wrote in Part 2?
- Is a big model that only plans and corrects cheaper than a big model doing every step?
- Does a better orchestrator prompt reduce the worker attempts and interventions?
