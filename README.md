# VLSI-SoC 2026 Tutorial: Agentic AI in EDA

Hands-on material for the VLSI-SoC 2026 tutorial on **agentic AI for Electronic Design Automation**. The tutorial is split into parts, each with practical problems where you improve an AI agent's behavior by steering it with better prompts, rules, and training examples, and then measure the result.

> **Status:** Parts 1, 2, 3 and 4 are available.

> **How to use this README.** Chapters 1–6 are **one-time setup**. Do them in order, once. Parts 1–4
> are the **tasks** of the tutorial. The slides follow the same chapters and steps as this README.

---

## Contents

- [Prerequisites](#prerequisites)
- **Setup**
  - [Chapter 1: Get the repository](#chapter-1-get-the-repository)
  - [Chapter 2: Set up the environment](#chapter-2-set-up-the-environment)
    - [Option A: Pull the prebuilt Docker image (recommended)](#option-a-pull-the-prebuilt-docker-image-recommended)
    - [Option B: Build the image from the Dockerfile](#option-b-build-the-image-from-the-dockerfile)
    - [Option C: Install the tools locally (no Docker)](#option-c-install-the-tools-locally-no-docker)
    - [Run the container](#run-the-container)
    - [Open a second terminal (optional)](#open-a-second-terminal-optional)
  - [What is in the image](#what-is-in-the-image)
  - [Chapter 3: Download a local model (Ollama)](#chapter-3-download-a-local-model-ollama)
  - [Chapter 4: Get your API keys](#chapter-4-get-your-api-keys)
  - [Chapter 5: Check the environment](#chapter-5-check-the-environment)
  - [Repository structure](#repository-structure)
  - [Chapter 6: Configure the agent](#chapter-6-configure-the-agent)
- **Tasks**
  - [Part 1](#part-1)
    - [Task 1.1: Sentiment Analysis](#task-11-sentiment-analysis)
    - [Task 1.2: Google Verification (ICLAD 2025)](#task-12-google-verification-iclad-2025)
  - [Part 2](#part-2)
    - [Task 2.1: Single agent](#task-21-single-agent)
    - [Task 2.2: Multi-agent](#task-22-multi-agent)
    - [Task 2.3: Hybrid, cloud and local models](#task-23-hybrid-cloud-and-local-models)
    - [Task 2.4: Validator agents](#task-24-validator-agents)
  - [Part 3](#part-3)
    - [Task 3: Feedback loops](#task-3-feedback-loops)
  - [Part 4](#part-4)
    - [Task 4: Orchestrator](#task-4-orchestrator)
- [Before the tutorial (instructors)](#before-the-tutorial-instructors)

---

## Prerequisites

- [Git](https://git-scm.com/downloads), to clone this repository
- [Docker](https://docs.docker.com/get-docker/) installed and running (not needed for option C). Installing Docker Desktop is quick.
- Access to an LLM, either a hosted API (you will need an API key, see [Chapter 4](#chapter-4-get-your-api-keys)) or a local model served by Ollama (already included in the image)
- **RAM:** local models with Ollama need a lot of memory, about **14–16 GB**. With less, use a hosted API.
- Free disk space for the image (it is large: OpenROAD, Yosys, KLayout and OpenROAD-flow-scripts). Building it yourself (option B) or installing locally (option C) also needs about 40 GB of disk, 16 GB of RAM and 1–2 hours
- Basic EDA knowledge. No AI expertise is required!

**Approximate times**

| Step | Time |
| --- | --- |
| Install Docker Desktop | a few minutes |
| Pull the Docker image (option A) | about 30 minutes |
| Download a local model (`ollama pull`) | about 5 minutes |
| Build the image (option B) or install locally (option C) | 1–2 hours |

---

# Setup

## Chapter 1: Get the repository

Clone this repository and move into it:

```bash
git clone https://github.com/zazatisn/VLSI-SOC26-AGENTIC-AI.git
cd VLSI-SOC26-AGENTIC-AI
```

> **Important:** every command in the rest of this README is run **from the root of the cloned
> repository** (the `VLSI-SOC26-AGENTIC-AI` folder, which contains the `Dockerfile` and the
> `scripts/` folder). The `docker run` command mounts the local `scripts/` folder, so it only
> works from there.

## Chapter 2: Set up the environment

> The options **A, B and C below are only about how you get the tools**. Pick **one** of them,
> follow it, and then continue with [Chapter 3](#chapter-3-download-a-local-model-ollama). Nothing
> in the later chapters or in Parts 1–4 depends on which option you picked.

| | Option | Time | When |
| --- | --- | --- | --- |
| **A** | [Pull the prebuilt Docker image](#option-a-pull-the-prebuilt-docker-image-recommended) | ~30 min (download only) | **Recommended** on x86-64 (Windows, Linux, Intel Mac) |
| **B** | [Build the image from the Dockerfile](#option-b-build-the-image-from-the-dockerfile) | 1–2 hours | ARM (Apple Silicon), or if you want to build it yourself |
| **C** | [Install the tools locally](#option-c-install-the-tools-locally-no-docker) | 1–2 hours | No Docker (Ubuntu 22/24/26, macOS best effort) |

### Option A: Pull the prebuilt Docker image (recommended)

The image is on Docker Hub: [`kostasvarak/vlsi-soc26-ai`](https://hub.docker.com/r/kostasvarak/vlsi-soc26-ai).
It is the image of the `Dockerfile`, already built. The download takes about 30 minutes.

```bash
docker pull --platform linux/amd64 kostasvarak/vlsi-soc26-ai:latest
docker tag kostasvarak/vlsi-soc26-ai:latest vlsi-soc26-ai
```

The `docker tag` gives it the short name `vlsi-soc26-ai`, so every command in this README works
unchanged. Then go to [Run the container](#run-the-container).

> The prebuilt image is for x86-64 (amd64). On Apple Silicon or other ARM machines, use option B
> with `Dockerfile.arm64`. Docker Desktop can run the x86 image under emulation, but OpenROAD is
> then several times slower.

### Option B: Build the image from the Dockerfile

From the root of the cloned repository (where the `Dockerfile` is):

**Windows (PowerShell):**

```bash
docker build --platform linux/amd64 -t vlsi-soc26-ai .
```

**Linux / macOS (Intel):**

```bash
docker build -t vlsi-soc26-ai .
```

**ARM: Apple Silicon Macs (M1–M4), ARM Linux (Graviton, Ampere, ...):**

```bash
docker build -f Dockerfile.arm64 -t vlsi-soc26-ai .
# less than 16 GB of RAM for Docker? build OpenROAD with fewer parallel jobs:
docker build -f Dockerfile.arm64 --build-arg BAZEL_JOBS=2 -t vlsi-soc26-ai .
```

`Dockerfile.arm64` builds the same environment natively for ARM. Only two things differ:
- **Bazel:** the ARM build of bazelisk.
- **KLayout:** built from source, since there is no ARM package; if that build fails, Ubuntu's package is used.

The image has the same name, so every other command in this README is unchanged. Don't build
the x86 `Dockerfile` on an ARM machine (or the reverse) with `--platform`: emulation makes the
OpenROAD build take many hours.

The build takes 1–2 hours and plenty of RAM (OpenROAD and Yosys are built from source). You only build it once.
Then go to [Run the container](#run-the-container).

### Option C: Install the tools locally (no Docker)

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

With option C there is no container: skip the next two sections and go to
[Chapter 3](#chapter-3-download-a-local-model-ollama).

### Run the container

This is the same for options A and B. Run it **from the root of the cloned repository**.

**Windows (PowerShell):**

```powershell
docker run --rm -it -v .\scripts\:/home/scripts vlsi-soc26-ai
```

**Linux / macOS:**

```bash
docker run --rm -it -v "$(pwd)/scripts":/home/scripts vlsi-soc26-ai
```

This mounts the local `scripts/` folder into the container at `/home/scripts`, so anything you edit on your machine (for example `Agent.md` or `trainset.json`) is immediately visible inside the container, and anything the scripts write persists on your machine.

> `--rm` deletes the container when you exit. Your work is safe as long as it lives in the mounted `scripts/` folder.

### Open a second terminal (optional)

To get another shell in the **same** running container without stopping it, give the container a name when you start it:

```powershell
docker run --rm -it --name vlsi -v .\scripts\:/home/scripts vlsi-soc26-ai
```

Then, from another terminal:

```powershell
docker exec -it vlsi bash
```

Closing the second shell does not affect the first. If you exit the original session, the container stops and all attached shells close.

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

## Chapter 3: Download a local model (Ollama)

Do this **now**, before the tasks, so the model is ready when you need it. The download takes
about 5 minutes. Ollama is installed in the image and its server starts automatically when the
container starts. Inside the container:

```bash
ollama pull llama3.1
```

**Recommended models:**

| Model | Command | Profile in `config.yaml` |
| --- | --- | --- |
| `llama3.1` | `ollama pull llama3.1` (needed for Parts 2c and 2d) | `ollama-llama3.1` |
| `qwen2.5-coder:7b` | `ollama pull qwen2.5-coder:7b` | `ollama-qwen2.5-coder` |

Notes:

- Local models need about **14–16 GB of RAM**. With less memory, use a hosted API ([Chapter 4](#chapter-4-get-your-api-keys)).
- Local models run on your own machine, so they need no API key and no internet access after the download. Speed depends on your hardware, and a GPU helps a lot.
- Because the container is started with `--rm`, models downloaded inside it are deleted when you exit. To keep them between sessions, add a volume for Ollama's model folder to the `docker run` command, `-v ollama-models:/home/.ollama` (the image sets `HOME=/home`). For example, on Linux / macOS:

  ```bash
  docker run --rm -it -v "$(pwd)/scripts":/home/scripts -v ollama-models:/home/.ollama vlsi-soc26-ai
  ```

## Chapter 4: Get your API keys

Hosted (cloud) models need an API key. All agents are built in Python with [DSPy](https://dspy.ai),
which supports many providers. **Recommended free option:** the [Google Gemini API](https://ai.google.dev/),
which has a free tier suitable for this tutorial.

### Step 1: Create a Gemini API key

1. Open [Google AI Studio → API keys](https://aistudio.google.com/apikey).
2. Sign in with a Google account and accept the terms, if asked.
3. Click **Create API key**. If asked, select or create a Google Cloud project.
4. Copy the key that is shown. Keep it private: do not share it or commit it.

Other providers work the same way: create a key in their console and copy it.

| Variable | Provider | Where to create the key |
| --- | --- | --- |
| `GEMINI_API_KEY` | Google Gemini | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) (free tier) |
| `ANTHROPIC_API_KEY` | Anthropic Claude | [console.anthropic.com](https://console.anthropic.com/) → API keys (needs credits) |
| `OPENAI_API_KEY` | OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) (needs credits) |
| `GROQ_API_KEY` | Groq | [console.groq.com/keys](https://console.groq.com/keys) (free tier) |

### Step 2: Put the key in `scripts/api_keys.sh`

API keys are **never written in the config files**. Every config reads its key from an environment
variable (`api_key: "$GEMINI_API_KEY"`), and one file sets these variables for all parts.

1. On your machine, from the root of the cloned repository, copy the template:

   **Linux / macOS:**

   ```bash
   cp scripts/api_keys.example.sh scripts/api_keys.sh
   ```

   **Windows (PowerShell):**

   ```powershell
   Copy-Item scripts\api_keys.example.sh scripts\api_keys.sh
   ```

2. Open `scripts/api_keys.sh` in an editor and paste your key between the quotes of the matching
   line, for example:

   ```bash
   export GEMINI_API_KEY="paste-your-key-here"
   ```

   Leave the keys you do not have empty. On Windows, keep the file's **LF** line endings
   (in VS Code: bottom-right corner, it must show `LF`, not `CRLF`).

`scripts/api_keys.sh` is listed in `.gitignore`, so your keys are never committed. Put keys only
in `api_keys.sh`, never in `api_keys.example.sh`.

### Step 3: Load the keys

Start (or restart) the container. Every container shell loads `scripts/api_keys.sh`
**automatically** and prints which keys are set (`[set]` / `[not set]`). The same keys work for
Parts 1, 2, 3 and 4. After you edit the file, reload it in the open shell:

```bash
source /home/scripts/api_keys.sh
```

> Free tiers have rate limits, so the iterative scripts may be slowed down or throttled. If that happens, wait a bit, reduce the number of runs, or switch to a local model.

> **Google API under high demand.** During busy hours (for example, when the whole room runs at
> once) the Gemini API can answer with `503 UNAVAILABLE` / "The model is overloaded" or
> `429 RESOURCE_EXHAUSTED`. This is on Google's side, not a bug in your prompt or setup:
> 1. **Re-run** the same command after a short wait.
> 2. If it keeps failing, use **Gemini Lite instead of Preview**. Set `active_profile: "gemini_lite"`
>    in the `config.yaml` of the agent, or pass `--orchestrator-profile gemini_lite` in Part 4.
>    `gemini-3-flash-preview` is a preview model with less capacity, so it is overloaded first.
> 3. Or move some agents to a local model (`ollama-llama3.1`).

## Chapter 5: Check the environment

Inside the container (or after a local install), run the regression once:

```bash
python3 /home/scripts/regression/regression.py --quick   # 30 s: tools, Python, simulation, synthesis
python3 /home/scripts/regression/regression.py           # + a full OpenROAD flow and PPA score (a few minutes)
python3 /home/scripts/regression/regression.py --llm     # + one-line answers from the models (a few tokens)
```

Every check prints PASS / FAIL / SKIP. If anything fails, see `scripts/regression/README.md`.

> **SKIP is to be expected.** A check is skipped depending on the mode that the check is running.
> For example a model whose API key you did not set, or a local model you did not download. Skips
> are **not** a problem. You only need at least one working model (local or hosted) and no FAIL
> in the tool checks.

## Repository structure

```
.
├── Dockerfile
├── Dockerfile.arm64       # the same image for ARM (Apple Silicon, ARM Linux)
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
    │   ├── designs/           # YAML hardware specs
    │   ├── evaluation/        # PPA scoring
    │   ├── problem/           # what you work on
    │   │   ├── asic_autonomous_flow.py
    │   │   ├── run_configs/   # 2a, 2b, 2c, 2d
    │   │   └── configs/<agent>/
    │   │       ├── Agent.md
    │   │       └── config.yaml
    │   └── solution/          # reference solution
    ├── part3/                 # same layout as part2, run config 3
    ├── reference/             # golden RTL/SDC/config.mk per design, sign-off and testbench grading
    │   ├── check_designs.py   #   spec <-> golden RTL <-> reference TB, --rtl sign-off, --tb grading
    │   └── make_reference.py  #   generates the PPA references (pN.json) for p11-p16
    ├── rescue/                # record the tutorial runs in advance, replay them if a live run fails
    ├── regression/            # environment check: tools, simulation, synthesis, OpenROAD, models
    ├── profile/               # time, tokens and success rate per design and run (LLM vs EDA split)
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

## Chapter 6: Configure the agent

The tutorial works with both local and cloud models. Every problem comes with two files that
control the agent:

- **`config.yaml`** selects which API and model the agent uses (a hosted provider, or a local model through Ollama). Set `active_profile` to a model you have access to, for example:
  - `ollama-llama3.1` or `ollama-qwen2.5-coder` for a local model ([Chapter 3](#chapter-3-download-a-local-model-ollama));
  - `gemini_lite` or `gemini_preview` for Gemini, and `groq`, `openai`, `claude-haiku-4-5`, ... for the other providers. Keys come from `api_keys.sh` ([Chapter 4](#chapter-4-get-your-api-keys)).
- **`Agent.md`** contains the information and rules given to the agent. This is the main lever you will use to change the agent's behavior.

Before each exercise: load your keys (`source /home/scripts/api_keys.sh`), set `active_profile` in `config.yaml`, then work on the problem.

---

# Tasks

The tasks are numbered like the slides: **Task 1.1, 1.2, 2.1, 2.2, 2.3, 2.4, 3 and 4**. Every task works the same way:

1. **Our golden run.** We run the finished version from the `solution/` folder and look at the result together.
2. **Your turn.** You work in the `problem/` folder: each task says **where to change things** and **what to run**.

You never edit the Python scripts. You only change what the agent is told (`Agent.md`, `trainset.json`) or how the run is
set up (`run_configs/*.yaml`), and you measure whether it helped.

## Part 1

Part 1 introduces two ways of improving an agent without changing the model: refining its prompt from examples, and giving it better rules.

### Task 1.1: Sentiment Analysis

**Goal:** build a training set that makes the refined agent **outperform the non-refined (baseline) agent** on a held-out test set.

**What you do**

1. Go to the problem folder (inside the container):

   ```bash
   cd /home/scripts/part1/sentiment_analysis/problem
   ```

2. Open `trainset.json` (on your machine: `scripts/part1/sentiment_analysis/problem/trainset.json`).
3. Fill it with sentences and their sentiment labels.
4. Run the script:

   ```bash
   python3 main.py
   ```

5. Change the training set and run again, as many times as you like.

The agent's prompt is refined using your training set, and the refined agent is then evaluated against the baseline on `testset.json`.

**Success criterion:** the refined agent scores higher than the baseline on `testset.json`.

> A strong hosted model may already get every test sentence right without any training set, so
> there is nothing left to improve. Use a local model (`ollama-llama3.1`) to see the effect of
> your training set.

**Things to think about**

- Which kinds of sentences does the baseline get wrong?
- Is your training set balanced across labels?
- Does your training set cover tricky cases (negation, sarcasm, mixed sentiment)?
- Avoid copying test sentences into the training set. The point is to generalize.

### Task 1.2: Google Verification (ICLAD 2025)

This task is based on the **ICLAD 2025** challenge.

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

**Run:**

```bash
cd /home/scripts/part1/google_verification/problem
python3 <script> <design>
```

For example:

```bash
python3 single_pass.py enc_bin2gray
python3 iterative.py fifo_flops
```

The scripts skip a design that already has a `golden.tb` (a testbench that isolated exactly one
mutant). Add `--force` to run it again, e.g. `python3 single_pass.py enc_bin2gray --force`.

**Your goal:** Modify `scripts/part1/google_verification/problem/Agent.md` so the agent performs
better at this task: writing more discriminating testbenches and identifying the correct RTL more reliably.

> **Use a hosted LLM for this problem.** SLM's often take a very long time.

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

Part 2 has four tasks. They all use the same script and the quick design `p11.yaml` (an 8-bit counter):

| Task | Run config | What it shows |
| --- | --- | --- |
| 2.1 | `2a_single_agent.yaml` | **One agent** for the whole flow (Gemini Flash Lite) |
| 2.2 | `2b_multi_agent.yaml` | **One agent per step**: TB, RTL, SDC, config.mk (Gemini Flash Lite) |
| 2.3 | `2c_multi_agent_mixed_models.yaml` | **Mixed models**: TB + RTL on Gemini Flash Lite, SDC + config.mk on local `llama3.1` |
| 2.4 | `2d_multi_agent_mixed_models_validators.yaml` | As 2.3, plus **validator agents** that review the TB and the RTL |

Before every task: `source /home/scripts/api_keys.sh`, then go to the folder you work in:

```bash
cd /home/scripts/part2/problem      # your work   (our golden version: /home/scripts/part2/solution)
```

None of the four tasks use iterative PPA optimization or resynthesis (that is Part 3).
Change `--design` to try another spec. All 11 designs (`p1`, `p5`, `p7`, `p8`, `p9`, `p11`-`p16`) are scored against our golden run; `p11`-`p13` are the quick ones.
Without `--design`, the flow runs the default `p8.yaml` (fp16 multiplier, a hard one).

A run is successful when the log ends with `Agentic flow completed successfully` and a `Final Score`.
Every LM call prints its tokens and throughput (TPM / TPS). At the end, a summary per agent and per
step is printed and saved in `runs/<run>/token_usage.json`, so the tasks can be compared.

### Task 2.1: Single agent

**Where you change things:** `problem/configs/single_agent/Agent.md`. It has blanks marked `<Fill here>`
(`<Add more if you want>` is optional).

1. Open `scripts/part2/problem/configs/single_agent/Agent.md` on your machine and fill the blanks:
   - **Role and Objective:** who the agent is, and what it is given.
   - **Testbench, rule 2 (clock and reset):** what to generate, and what to assert at time 0.
   - **config.mk, starting values:** `CORE_UTILIZATION`, `PLACE_DENSITY`, `CORE_ASPECT_RATIO`, `CORE_MARGIN`.
2. Run it:

   ```bash
   python3 asic_autonomous_flow.py --config run_configs/2a_single_agent.yaml --design p11.yaml
   ```

3. Compare your prompt with the golden one: `solution/configs/single_agent/Agent.md`.

### Task 2.2: Multi-agent

**Where you change things:** nothing has to be filled in, every agent's prompt is complete. You improve
the prompt of the agent that fails.

1. Run it:

   ```bash
   python3 asic_autonomous_flow.py --config run_configs/2b_multi_agent.yaml --design p11.yaml
   ```

2. Read the log. Which message repeats (for example `RTL simulation failed`)? What would you fix by hand?
3. Open the prompt of that agent, `problem/configs/<agent>/Agent.md` (`tb_generator`, `rtl_generator`,
   `sdc_generator`, `config_mk_generator`), and write that knowledge in it: a rule under
   `# Mandatory Rules`, or a hint in a feedback section.
4. Run the same command again and compare: does it pass, with fewer iterations and fewer tokens?
5. Sign off the final RTL with our own testbench:

   ```bash
   cd /home/scripts/reference
   python3 check_designs.py -d p11 --rtl ../part2/problem/runs/2b_multi_agent/solution/p11/simple_8bit_counter.v
   ```

### Task 2.3: Hybrid, cloud and local models

**Where you change things:** the `profile:` lines of `problem/run_configs/2c_multi_agent_mixed_models.yaml`.
Each agent has one. They decide which model the agent uses.

1. Make sure the local model is there: `ollama list` must show `llama3.1`
   (see [Chapter 3](#chapter-3-download-a-local-model-ollama)).
2. Run it. The SDC and config.mk agents now run on your machine (`profile: "ollama-llama3.1"`):

   ```bash
   python3 asic_autonomous_flow.py --config run_configs/2c_multi_agent_mixed_models.yaml --design p11.yaml
   ```

3. Change the split: for example, give `rtl_generator` the profile `"ollama-llama3.1"` too. Run again.
4. Compare the time and the tokens per agent in `runs/2c_multi_agent_mixed_models/token_usage.json`.

### Task 2.4: Validator agents

**Where you change things:** `problem/configs/tb_validator/Agent.md` and `problem/configs/rtl_validator/Agent.md`.
Both have blanks marked `<Fill here>`.

1. Fill the role of the TB validator, and the role and the reference of the RTL validator.
2. Run it:

   ```bash
   python3 asic_autonomous_flow.py --config run_configs/2d_multi_agent_mixed_models_validators.yaml --design p11.yaml
   ```

3. Compare with Task 2.3: are bugs caught earlier, and how many more tokens does it cost?
4. Compare your prompts with the golden ones in `solution/configs/`.

> The validators add many model calls. On a free API tier the run can stop with a quota error
> (`You exceeded your current quota`): wait a minute and run it again.

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

### Task 3: Feedback loops

**Where you change things:** `problem/run_configs/3_multi_agent_collaboration.yaml`. In `problem/` both
loops start **switched off**.

1. Run it as it is. This is one pass, like Part 2. Write down the score:

   ```bash
   cd /home/scripts/part3/problem
   python3 asic_autonomous_flow.py --config run_configs/3_multi_agent_collaboration.yaml
   ```

2. Switch the loops on in the run config (section `flow`):
   `iterative_optimization: true` and `enable_resynthesis: true`.
3. Run the same command again and compare the score, the number of OpenROAD runs and the tokens.
4. Steer the loops: `score_threshold`, `max_resynthesis_attempts` and the iteration limits in the
   run config, and the feedback sections of the `config_mk_generator` and `rtl_generator` `Agent.md` files.

The golden run config is in `solution/run_configs/`. See
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

### Task 4: Orchestrator

**Where you change things:** `problem/configs/orchestrator/Agent.md`, the only prompt of Part 4. It is
given complete. It decides how the orchestrator plans, how it prompts small models, and how it steps in
when they fail.

1. Run the Gemini team, 4b (your free Gemini key is enough). The Claude team, 4a, needs a paid
   `ANTHROPIC_API_KEY`: you do **not** need to run it yourself, we show our recorded Claude runs in the session.
2. Read what the orchestrator decided, in `runs/<run>/<design>/`: `plan.json` (the subtasks) and
   `agents/<subtask>/Agent_v1.md` (the prompts it wrote for the small models).
3. Change one rule in the orchestrator's prompt: how to plan, how to prompt a small model, or when to step in.
4. Run again and compare the worker attempts, the interventions and the token cost of the big and the
   small models (`token_usage.json`). See [`scripts/part4/README.md`](scripts/part4/README.md).

**Things to think about**

- Are the generated worker prompts better or worse than the ones you wrote in Part 2?
- Is a big model that only plans and corrects cheaper than a big model doing every step?
- Does a better orchestrator prompt reduce the worker attempts and interventions?

---

## Before the tutorial (instructors)

Run these once in the container, a few days before the session:

0. **Check the environment** with everything, models included:
   ```bash
   python3 /home/scripts/regression/regression.py --all
   ```
   Run this also before you upload a new image to Docker Hub.
1. **Check the designs**:
   ```bash
   cd /home/scripts/reference && python3 check_designs.py --mutants --synth --gls
   ```
   This checks every spec, golden RTL and reference testbench, and that each testbench catches
   all of its planted bugs.
2. **Generate the missing PPA references**:
   ```bash
   python3 make_reference.py --keep-layout
   ```
   This makes p11–p16 scored. Commit the new `evaluation/visible/pN/pN.json` files.
3. **Record the rescue runs**:
   ```bash
   cd /home/scripts/rescue && python3 make_rescue.py --preset tutorial
   ```
   If a live run fails on the day, run `python3 show_rescue.py replay <run>`. See `scripts/rescue/README.md`.
4. **Profile the designs** (optional: how long each design and run takes, and where the time goes):
   ```bash
   cd /home/scripts/profile
   python3 profile_designs.py eda -r 3                         # golden designs through the tools, no LLM
   python3 profile_designs.py agent --runs 2b_multi_agent -d p11 -d p8 -r 3
   python3 profile_designs.py report                           # -> results/profile_report.md
   ```
   See `scripts/profile/README.md`.

   docker save kostasvarak/vlsi-soc26-ai:latest | & "C:\Program Files\7-Zip\7z.exe" a -si -tgzip D:\vlsi-soc26-ai.tar.gz