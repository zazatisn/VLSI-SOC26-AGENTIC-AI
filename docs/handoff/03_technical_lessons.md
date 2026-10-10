# 03 — Technical lessons (traps we already fell into)

## Specs, testbenches, verification

- **YAML 1.1 turns `[15:0]` into the number 900** (base-60 "sexagesimal"). Every prompt then said `type: [900]`.
  Quote bit ranges in specs, and check what the parser actually produced.
- **Testbench sampling races.** The p1 reference TB checked outputs `#0.1` after the clock edge, i.e. one cycle
  early: a correct FSM failed 10 RTL iterations. Sample on the opposite edge (negedge) or after a clear settle time.
- **Weak testbenches pass mutants.** The original p7/p8/p9 TBs missed 6 of 7 planted bugs. Every reference TB
  must fail every mutant in `mutants.yaml` (`check_designs.py --mutants`). p8 now uses 320 vectors.
- **Test data can hide bugs**: palindromic test bytes could not detect MSB-first vs LSB-first in the UART TB;
  a loop variable `i` shared between two tasks broke the p15 TB; the p5 reset check was vacuous. Use
  asymmetric data and independent loop variables, and check that each check can actually fail.
- **A flow PASS only means the RTL agrees with the agent's own testbench.** Real p8 run: the agent's TB expected
  −3 × 4 = −10; none of the 10 RTL iterations is correct against our TB (ITER_3 fails 63/320, all
  overflow/underflow; the final one fails 134). Always sign off with `check_designs.py -d pN --rtl <file>` and
  grade agent TBs with `--tb <file>`.
- **Missing latency contract**: TB and RTL agents disagreed on latency until every spec got a `timing:` section.
- **Contradicting rules**: a generic "a state must not loop to itself" FSM rule broke the 0011 detector.
- **A wrong rule is followed faithfully**: "raise CORE_MARGIN" for PDN-0185 made the agent go to 50; the real
  fix is lower CORE_UTILIZATION (small cores are too narrow for the power straps). Small designs start at 20%.

## Scoring (`evaluation/evaluate_openroad.py`)

- WNS 40 pts: 30 + 40 × (WNS − WNS_gold), capped ±10 (0.25 ns better = +10). The code comment "10 pts per
  −0.025 ns" is wrong.
- TNS 20: 15 ± 5 × relative change; if golden TNS = 0: 20 when TNS = 0, 10 with any violation.
- Power, area 20 each: 15 + 20 × (ref/sub − 1), capped ±5.
- Golden layout = 80 (75 for p9, p13). Max 100.
- Part 3 code: resynthesis triggers ONLY on WNS < −0.5 ns ("Severe timing violation"); a low score alone
  never triggers it; if iterations run out below the threshold, the best layout is kept. There is no warning
  for mild negative slack (−0.5 < WNS < 0) — only lower points.

## Agents / DSPy / runs

- **DSPy caches answers on disk**: cached calls report 0 tokens and near-zero latency. For any measurement
  (rescue recordings, profiling, paper runs) set a fresh `DSPY_CACHEDIR` per run (make_rescue and
  profile_designs do this).
- Part 1 Google scripts **skip everything if `golden.tb` exists** in the design folder: move it aside to re-run.
- The sentiment example has **no feedback loop**: the DSPy optimizer compiles trainset examples into the prompt
  once (black box). Don't describe it as an agent loop.
- Run status detection (make_rescue `summarize`): failure = "❌ Failure!", "Reached max iterations",
  "no orchestrator interventions left", or a Python traceback; success = "Agentic flow completed successfully" /
  "The team reached a scored layout" / "SUCCESS! Exactly 1 mutant isolated". Intermediate "Success!" lines don't count.
- Short runs are often failed runs (the RTL loop exhausts its 10 iterations in ~1–2 min).
- Measured (Oct 2026): runs take 1–3 min; LLM time is 50–95 % of wall time; golden OpenROAD 19–41 s for
  p11–p16, p8 41–88 s per run; Part 4 on p8 ~10.6 min / 218k tokens.
- **Never run two flows of the same design concurrently**: they share `ORFS/flow/designs/sky130hd/<module>`
  and `results/` folders. Different designs in parallel are fine.

## OpenROAD / tools / environment

- **KLayout must be ≥ 0.28** (tested 0.30): the final step `6_1_merged.gds` fails with 0.26 (Ubuntu 22.04 apt
  ships 0.26.2; 24.04 ships 0.28.15). `regression.py` checks this. On ARM build 0.30.12 from source:
  `./build.sh -without-qt -noruby -python python3 -prefix /opt/klayout -option -j$(nproc)` (needs qtbase5-dev,
  qt5-qmake), then a wrapper in /usr/local/bin that sets LD_LIBRARY_PATH.
- **ARM Docker build**: big git clones fail with "RPC failed / GnuTLS" — `Dockerfile.arm64` uses a `gclone`
  retry helper, blob-less clones (`--filter=blob:none`), clone and build in separate layers, bazel retries and
  `BAZEL_JOBS`. WSL needs memory: `%UserProfile%\.wslconfig` → `[wsl2] memory=12GB`, then `wsl --shutdown`.
- Small designs often fail PDN (PDN-0185) or placement with a default floorplan: `make_reference.py` retries
  with fallback floorplans (util/margin/density) and saves the one that worked.
- Env file generation in install scripts: escape `\$(...)` so it runs at source time; macOS bash 3.2 cannot
  `source <(...)` — use `eval "$(tr -d '\r' < file)"` (also strips Windows CRLF from api_keys.sh).
- From the agent's cloud sandbox, Docker Hub and conda are blocked: EDA measurements must be run by the owner
  in the container (give them a script + command, then analyse the CSV they produce).

## Checking your own work

- Run `regression.py`, `check_designs.py`, and render slides to images after edits.
- Re-read numbers you put in docs/slides against the data (the "RTL was right" story and "golden = 75" were
  both wrong in earlier drafts).
