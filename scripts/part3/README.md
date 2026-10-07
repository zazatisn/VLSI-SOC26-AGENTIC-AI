# Part 3: Multi-Agent Collaboration

In Part 2 every agent did its job **once**: the flow stopped at the first successful layout, and
timing problems never went back to the RTL. In Part 3 the agents **collaborate in loops**:

```
             ┌──────────────── resynthesis: "timing failed by far, rebuild the RTL" ───────────────┐
             ▼                                                                                     │
TB agent ─► RTL agent ─► SDC agent ─► config.mk agent ─► OpenROAD ─► PPA score ─────────────────────┤
                                            ▲                                                       │
                                            └──── iterative optimization: "score X/100, improve it" ┘
```

- **Iterative optimization** (`iterative_optimization: true`): after a successful layout, the
  `config.mk` agent receives the PPA report and tries to improve the score. It keeps going until
  the score reaches `score_threshold` (92) or `max_physical_iters` (10) runs out. The best
  layout is kept.
- **Resynthesis** (`enable_resynthesis: true`): if timing fails by far (WNS < -0.5 ns), no
  `config.mk` setting can save it. The physical flow sends the evaluation report back to the
  **RTL agent**, which must restructure the design (e.g. add pipelining) while still passing the
  testbench. This happens up to `max_resynthesis_attempts` (3) times.

Validators are off, and all agents use Gemini Flash Lite.

---

## Folder layout

Same as Part 2:

```
part3/
├── README.md
├── problems/visible/             # the YAML specs
├── evaluation/                   # PPA scoring scripts + reference results
├── problem/                      # ◄ what you work on (minimal Agent.md prompts)
│   ├── asic_autonomous_flow.py
│   ├── run_configs/3_multi_agent_collaboration.yaml
│   ├── configs/<agent>/          # config.yaml (model) + Agent.md (prompt)
│   ├── templates/
│   └── PDK_files/
└── solution/                     # reference: golden Agent.md prompts
```

Everything about the run configs, the agent model configs, the `Agent.md` format, choosing
models and the outputs works as in Part 2. See the [Part 2 README](../part2/README.md).

---

## How to run

```bash
cd /home/scripts/part3/problem          # or /home/scripts/part3/solution
source /home/scripts/api_keys.sh          # API keys, once per shell

python3 asic_autonomous_flow.py --config run_configs/3_multi_agent_collaboration.yaml
```

Pick another design with `--design p5.yaml` (also `p1`, `p7`, `p8`, `p9`). The pipelined designs
(`p5`, `p7`) and `p8` are where timing, and therefore resynthesis, matters most.

Outputs go to `runs/3_multi_agent_collaboration/` (log, every iteration, best layout, and
`token_usage.json` with the tokens of every agent and step).

---

## What you do (hands-on)

The collaboration only works if the agents understand each other's messages. In
`problem/configs/<agent>/Agent.md`, focus on the feedback between agents:

1. **`config_mk_generator`**
   - Rules: how to change each `config.mk` parameter from the ORFS errors (congestion,
     placement density, PDN straps) and from the missing timing / power / area score points.
   - Feedback: `score_report`, `severe_timing_warning` and `optimize_further`, the messages
     that drive the optimization loop.
2. **`rtl_generator`**
   - Rules: timing and pipelining (how to meet the clock period).
   - Feedback: `timing_resynthesis` (the physical flow asks for a new RTL) and
     `timing_reminder` (while fixing a bug, do not break the timing fix).
3. Run, read the log, and follow the score from iteration to iteration. Then compare with the
   golden prompts in `solution/`.

**Things to think about**

- How much does the score improve from the first accepted layout (where Part 2 stopped) to
  the best one?
- Does the `config.mk` agent explore in a sensible order, or does it change everything at once?
- When resynthesis happens, does the new RTL actually meet timing, and does it still pass the testbench?
- What is the cost (iterations, tokens, time) of each extra point of score? Compare the token
  summary at the end of the run with your Part 2 runs.
- Try `score_threshold`, `max_physical_iters` and `max_resynthesis_attempts` in the run config.
