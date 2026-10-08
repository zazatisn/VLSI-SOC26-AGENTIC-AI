# Environment regression

`regression.py` checks that the tutorial environment works, on any setup: the Docker Hub image,
an image built from `Dockerfile` / `Dockerfile.arm64`, or a local install. It runs small examples
whose correct result is known, so a failure means the **environment** is broken, not a prompt or a
model having a bad day. By default no LLM is called.

```bash
python3 /home/scripts/regression/regression.py            # ~3-5 min: includes a full OpenROAD flow
python3 /home/scripts/regression/regression.py --quick    # ~30 s: no OpenROAD flow
python3 /home/scripts/regression/regression.py --llm      # + the models: a one-line answer each (a few tokens)
python3 /home/scripts/regression/regression.py --all      # + a real agentic flow (Part 2, run 2b, design p11)
```

| # | Check | What it proves |
|---|---|---|
| 1 | `iverilog`, `vvp`, `yosys`, `openroad`, `klayout`, `make` | The tools are installed and run |
| 1 | `OPENROAD_EXE`, `YOSYS_EXE`, OpenROAD-flow-scripts + sky130hd | ORFS can find the tools and the platform |
| 1 | `dspy`, `pyyaml`, `ollama`; API keys | The agents can run; which cloud models are usable |
| 2 | `asic_autonomous_flow.py --help`, `asic_orchestrated_flow.py --help` | The tutorial scripts import and parse their arguments |
| 3 | Golden p11 and p8 with their reference testbenches, mutants | Icarus simulation works and gives the expected results |
| 3 | Yosys synthesis of p11 to sky130hd, gate-level simulation | Synthesis + the PDK cell models work |
| 3 | Full OpenROAD flow of the golden p11 (golden SDC and config.mk) | Floorplan to GDS works, KLayout writes the GDS |
| 3 | `evaluate_openroad.py` on that layout | Scoring works: the golden layout must score about 75–80 |
| 4 | `--llm`: Ollama server + `llama3.1`, and a one-line answer from `ollama-llama3.1`, `gemini_lite`, `claude-haiku-4-5` (if their keys are set) | The models answer through DSPy |
| 5 | `--agent`: `part2/solution`, run 2b on p11 | An agentic flow completes end to end |

Each check prints PASS / FAIL / SKIP; the exit code is 0 only when nothing failed. The output of
every step is in `regression/logs/` (`summary.json` has all results). SKIP is not an error: for
example `claude-haiku-4-5` is skipped when `ANTHROPIC_API_KEY` is not set.

Typical use:
- after building or pulling the image, or after a local install;
- on attendees' laptops at the start of the tutorial (`--quick` takes 30 s);
- before you upload a new image to Docker Hub (`--all`).
