# VLSI-SoC 2026 Tutorial: Agentic AI in EDA

Hands-on material for the VLSI-SoC 2026 tutorial on **agentic AI for Electronic Design Automation**. The tutorial is split into parts, each with practical problems where you improve an AI agent's behavior by steering it with better prompts, rules, and training examples, and then measure the result.

> **Status:** Part 1 is available. Parts 2, 3 and 4 will be added.

---

## Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
  - [1. Build the Docker image](#1-build-the-docker-image)
  - [2. Run the container](#2-run-the-container)
  - [3. Open a second terminal](#3-open-a-second-terminal-optional)
- [What is in the image](#what-is-in-the-image)
- [Repository structure](#repository-structure)
- [Configuring the agent](#configuring-the-agent)
- [Part 1](#part-1)
  - [Problem 1: Sentiment Analysis](#problem-1-sentiment-analysis)
  - [Problem 2: Google Verification (ICLAD 2025)](#problem-2-google-verification-iclad-2025)
- [Parts 2, 3 and 4](#parts-2-3-and-4)

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- Access to an LLM, either a hosted API (you will need an API key) or a local model served by Ollama (already included in the image)
- Enough disk space and time for the first build: it compiles Yosys from source, downloads OpenROAD binary and uses OpenROAD flow scripts
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

The first build takes a while because Yosys is built from source.

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

## What is in the image

| Tool | Purpose |
| --- | --- |
| Ubuntu 22.04 | Base system |
| [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) | Place and route (prebuilt binary, at `/bin/openroad`) |
| [Yosys](https://github.com/YosysHQ/yosys) | Logic synthesis (built from source, at `/usr/local/bin/yosys`) |
| [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) | RTL-to-GDS flow (cloned in `/home`) |
| [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`, `vvp`) | Verilog simulation |
| [Ollama](https://ollama.com/) | Local LLM server, started automatically when the container starts |
| Python 3 + [DSPy](https://dspy.ai), `ollama`, `pyyaml` | Agent framework and utilities |

The `OPENROAD_EXE` and `YOSYS_EXE` environment variables are already set.

## Choosing a model

The tutorial works with both local and cloud models. All agents are built in Python with [DSPy](https://dspy.ai), which handles the model setup and lets us compose multi-agent systems. You pick the provider and model in each problem's `config.json`.

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

Then set the model in `config.json` to the one you pulled.

Notes:

- Local models run on your own machine, so they need no API key and no internet access after the download. Speed depends on your hardware, and a GPU helps a lot.
- Because the container is started with `--rm`, models downloaded inside it are deleted when you exit. To keep them between sessions, mount a volume for Ollama's model folder, for example `-v ollama-models:/home/.ollama` (the image sets `HOME=/home`).

### Option B: Cloud LLMs with API keys

You can also use hosted models by providing an API key.

**Recommended free option:** the [Google Gemini API](https://ai.google.dev/), which has a free tier suitable for this tutorial.

Then set the Gemini model in `config.json`. Other providers supported by DSPy also work, using their own API key variable.

> Free tiers have rate limits, so the iterative scripts may be slowed down or throttled. If that happens, wait a bit, reduce the number of runs, or switch to a local model.

## Repository structure

```
.
├── Dockerfile
├── README.md
└── scripts/
    ├── part1/
    │   ├── sentiment_analysis/
    │   │   ├── problems/      # what you work on
    │   │   │   ├── Agent.md
    │   │   │   ├── config.json
    │   │   │   ├── trainset.json
    │   │   │   ├── testset.json
    │   │   │   └── main.py
    │   │   └── solutions/     # reference solution
    │   └── google_verification/
    │       ├── problems/      # what you work on
    │       │   ├── Agent.md
    │       │   ├── config.json
    │       │   ├── single_pass.py
    │       │   └── iterative.py
    │       └── solutions/     # reference solution
    ├── part2/                 # coming soon
    ├── part3/                 # coming soon
    └── part4/                 # coming soon
```

Each problem has a `problems/` folder (the starting point) and a `solutions/` folder (a reference to compare against once you have tried it yourself).

## Configuring the agent

Every problem comes with two files that control the agent:

- **`config.json`** selects which API and model the agent uses (a hosted provider, or a local model through Ollama).
- **`Agent.md`** contains the information and rules given to the agent. This is the main lever you will use to change the agent's behavior.

Edit `config.json` first to point at the model you have access to, then work on the problem.

---

## Part 1

Part 1 introduces two ways of improving an agent without changing the model: refining its prompt from examples, and giving it better rules.

### Problem 1: Sentiment Analysis

**Goal:** build a training set that makes the refined agent **outperform the non-refined (baseline) agent** on a held-out test set.

**What you do**

1. Open `trainset.json` in `sentiment_analysis/problems/`.
2. Fill it with sentences and their sentiment labels.
3. Run the script (from the `problems/` folder):

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

## Parts 2, 3 and 4

Coming soon.
