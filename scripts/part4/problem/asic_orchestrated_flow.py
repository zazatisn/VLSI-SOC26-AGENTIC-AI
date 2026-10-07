########################################################################
# Project: Orchestrated ASIC Design Flow (DSPy + iVerilog + OpenROAD)  #
#                                                                      #
# Part 4 of the VLSI-SoC 2026 tutorial.                                #
#                                                                      #
# A BIG model (the orchestrator) manages SMALL models (the workers):   #
#                                                                      #
#  1. PLAN     The orchestrator reads the YAML spec and splits the     #
#              fixed pipeline into subtasks:                           #
#                testbench -> sdc -> rtl -> config_mk (OpenROAD)       #
#              Every stage can have several subtasks ("analysis" notes #
#              and "deliverable" files). For EVERY subtask it writes   #
#              an Agent.md (role + rules) for a worker.                #
#  2. EXECUTE  A small worker model runs each subtask with its         #
#              generated Agent.md. Deliverables are checked by the     #
#              EDA tools (iverilog, Yosys, ORFS, PPA evaluation) and   #
#              the tool reports are fed back to the worker.            #
#  3. ESCALATE When a worker keeps failing, the orchestrator reads the #
#              logs and decides: rewrite the worker's Agent.md, give   #
#              it plain guidance, or send the flow back to an earlier  #
#              subtask (e.g. "the testbench is wrong, redo it").       #
#                                                                      #
# Files you can change:                                                #
#   run_configs/*.yaml              : models, limits, design, paths    #
#   configs/orchestrator/Agent.md   : HOW the orchestrator plans,      #
#                                     writes worker prompts, escalates #
#   configs/orchestrator/config.yaml, configs/worker/config.yaml       #
#                                   : model profiles                   #
#                                                                      #
# Run (from the folder of this script):                                #
#   python3 asic_orchestrated_flow.py --config run_configs/4a_orchestrator_claude.yaml
#   ... --design p1.yaml --orchestrator-profile claude-opus-5-5        #
#   ... --worker-profile ollama-llama3.1                               #
########################################################################

import argparse
import contextlib
import json
import os
import re
import shutil
import sys
import time
from pathlib import Path

import dspy
import yaml

import eda_tools as eda

# --- ANSI colors ---

Y  = "\033[33m"  # yellow -> Warnings
C  = "\033[36m"  # cyan   -> Flows headers
G  = "\033[32m"  # green  -> Success
RD = "\033[31m"  # red    -> Failure
M  = "\033[35m"  # magenta -> Orchestrator
B  = "\033[1m"   # bold
R  = "\033[0m"   # reset

# --- COMMAND LINE AND RUN CONFIG ---

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Orchestrated ASIC design flow: a big orchestrator model "
                                                 "plans subtasks and writes the prompts of small worker models.")
    parser.add_argument("--config", type=Path, default=Path("run_configs/4a_orchestrator_claude.yaml"),
                        help="Run config file (default: run_configs/4a_orchestrator_claude.yaml)")
    parser.add_argument("--design", help="Design spec inside problems_dir, e.g. p1.yaml")
    parser.add_argument("--orchestrator-profile", help="Profile of the orchestrator (configs/orchestrator/config.yaml)")
    parser.add_argument("--worker-profile", help="Profile of every worker (configs/worker/config.yaml)")
    return parser.parse_args()

def cfg_get(cfg: dict, dotted: str, default=None):
    node = cfg
    for part in dotted.split("."):
        if not isinstance(node, dict) or part not in node:
            return default
        node = node[part]
    return default if node is None and default is not None else node

ARGS = parse_args()
if not ARGS.config.exists():
    raise SystemExit(f"Error: run config not found: {ARGS.config}\nPick one with --config run_configs/<run>.yaml")
CFG = yaml.safe_load(ARGS.config.read_text(encoding="utf-8")) or {}

ORCH_CONFIG   = Path(cfg_get(CFG, "orchestrator.config", "./configs/orchestrator/config.yaml"))
ORCH_MD       = Path(cfg_get(CFG, "orchestrator.agent_md", "./configs/orchestrator/Agent.md"))
ORCH_PROFILE  = ARGS.orchestrator_profile or cfg_get(CFG, "orchestrator.profile")
WORKER_CONFIG = Path(cfg_get(CFG, "workers.config", "./configs/worker/config.yaml"))
WORKER_PROFILE = ARGS.worker_profile or cfg_get(CFG, "workers.profile")

MAX_SUBTASKS     = int(cfg_get(CFG, "limits.max_subtasks", 8))
MAX_PLAN_TRIES   = int(cfg_get(CFG, "limits.max_plan_attempts", 3))
WORKER_ATTEMPTS  = int(cfg_get(CFG, "limits.worker_attempts", 3))
INTERVENTIONS    = int(cfg_get(CFG, "limits.orchestrator_interventions", 3))
MAX_REPLANS      = int(cfg_get(CFG, "limits.max_replans", 2))
REPORT_CHARS     = int(cfg_get(CFG, "limits.report_chars", 4000))

DESIGN        = ARGS.design or cfg_get(CFG, "design.design", "p1.yaml")
ORFS_PLATFORM = cfg_get(CFG, "design.orfs_platform", "sky130hd")
PDK_RTL_PATH  = Path(cfg_get(CFG, "design.pdk_rtl_path", "./PDK_files/"))
ORFS_DIR      = cfg_get(CFG, "design.orfs_dir")
ORFS_DIR      = Path(ORFS_DIR).expanduser() if ORFS_DIR else None

VERIFICATION_MODE = str(cfg_get(CFG, "flow.verification_mode", "RTL")).upper()
SCORE_THRESHOLD   = cfg_get(CFG, "flow.score_threshold")   # None: accept the first successful layout

EVALUATION_DIR    = Path(cfg_get(CFG, "paths.evaluation_dir", "../evaluation/"))
PROBLEMS_DIR      = Path(cfg_get(CFG, "paths.problems_dir", "../problems/visible/"))
RUN_DIR           = Path(cfg_get(CFG, "paths.run_dir", "./runs/4a_orchestrator_claude")) / Path(DESIGN).stem
CONFIG_TEMPLATE   = Path(cfg_get(CFG, "paths.config_template", "./templates/config.mk"))
SDC_COMB_TEMPLATE = Path(cfg_get(CFG, "paths.sdc_comb_template", "./templates/constraint_comb.sdc"))
SDC_SEQ_TEMPLATE  = Path(cfg_get(CFG, "paths.sdc_seq_template", "./templates/constraint_seq.sdc"))

STAGES = ["testbench", "sdc", "rtl", "config_mk"]   # fixed order of the pipeline
KINDS  = ["analysis", "deliverable"]

# --- SPEC TEXT FOR THE PROMPTS ---

class _SpecDumper(yaml.SafeDumper):
    pass

def _str_presenter(dumper, data):
    # Multi-line text (module signature, timing notes) as readable literal blocks
    if "\n" in data:
        data = "\n".join(line.rstrip() for line in data.split("\n"))
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)

_SpecDumper.add_representer(str, _str_presenter)

def spec_text(spec: dict) -> str:
    """The spec as YAML, in its original key order, with multi-line text kept readable."""
    return yaml.dump(spec, Dumper=_SpecDumper, sort_keys=False, allow_unicode=True, width=1000, default_flow_style=None)

# --- LM CONFIG LOADER (same format as Parts 2 and 3) ---

def load_lm(config_path: Path, profile: str = None) -> "dspy.LM":
    if not Path(config_path).exists():
        raise SystemExit(f"Error: LM config file not found: {config_path}")
    cfg = yaml.safe_load(Path(config_path).read_text(encoding="utf-8")) or {}
    profiles = cfg.get("profiles") or {}
    active = profile or cfg.get("active_profile")
    if active not in profiles:
        raise SystemExit(f"Error: profile '{active}' not found in {config_path}. "
                         f"Available profiles: {', '.join(profiles) or 'none'}")
    kwargs = {k: v for k, v in dict(profiles[active] or {}).items() if v not in ("", None)}
    model = kwargs.pop("model", None)
    if not model:
        raise SystemExit(f"Error: profile '{active}' in {config_path} has no 'model'.")
    key = kwargs.get("api_key")
    if isinstance(key, str) and key.startswith("$"):
        kwargs["api_key"] = os.getenv(key[1:], "")
        if not kwargs["api_key"]:
            print(f"Warning: environment variable '{key[1:]}' ({config_path} [{active}]) is not set. "
                  f"Load your keys first: source /home/scripts/api_keys.sh")
            kwargs.pop("api_key")
    elif isinstance(key, str) and key.startswith("YOUR_"):
        kwargs.pop("api_key")
    kwargs.setdefault("cache", False)
    # Retry temporary API errors (503 overloaded, 429 rate limit, timeouts) with backoff
    kwargs.setdefault("num_retries", 6)
    print(f"[LM] {Path(config_path).parent.name}/{Path(config_path).name} -> profile '{active}' ({model})")
    return dspy.LM(model, **kwargs)

ORCH_LM   = load_lm(ORCH_CONFIG, ORCH_PROFILE)
WORKER_LM = load_lm(WORKER_CONFIG, WORKER_PROFILE)
dspy.configure(lm=WORKER_LM)

# --- AGENT.MD PARSING (same format as Parts 1-3) ---

def parse_agent_md(text: str) -> dict:
    """Split an Agent.md text into {lower-case heading: content}. Comments and front matter are ignored."""

    text = re.sub(r"<!--.*?-->", "", text or "", flags=re.DOTALL)
    text = re.sub(r"\A\s*---\n.*?\n---\s*\n", "", text, flags=re.DOTALL)
    sections, current, buf, fence = {}, None, [], False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            fence = not fence
        if not fence and re.match(r"^# \S", line):
            if current is not None:
                sections[current] = "\n".join(buf).strip()
            current, buf = line[2:].strip().lower(), []
            continue
        buf.append(line)
    if current is not None:
        sections[current] = "\n".join(buf).strip()
    elif text.strip():
        sections["mandatory rules"] = text.strip()    # no headings: everything is rules
    return sections

def md_role(sections: dict) -> str:
    return sections.get("role and objective", "")

def md_rules(sections: dict) -> str:
    parts = [sections.get("mandatory rules", ""), sections.get("output format", "")]
    return "\n\n".join(p for p in parts if p)

ORCH_SECTIONS = parse_agent_md(ORCH_MD.read_text(encoding="utf-8")) if ORCH_MD.exists() else {}

# --- TOKEN & THROUGHPUT TRACKING (same metrics as part1/utility_func.py) ---

def extract_tokens(entry: dict) -> tuple[int, int, int]:
    usage = entry.get("usage", {}) or {}
    if isinstance(usage, dict):
        p = usage.get("prompt_tokens") or usage.get("prompt_eval_count", 0) or 0
        c = usage.get("completion_tokens") or usage.get("eval_count", 0) or 0
        return p, c, usage.get("total_tokens") or (p + c)
    p = getattr(usage, "prompt_tokens", 0) or getattr(usage, "prompt_eval_count", 0) or 0
    c = getattr(usage, "completion_tokens", 0) or getattr(usage, "eval_count", 0) or 0
    return p, c, getattr(usage, "total_tokens", 0) or (p + c)

def get_token_stats(lm_instance, start_idx: int = 0, end_idx: int = None) -> dict:
    tot_p = tot_c = tot_t = 0
    for entry in lm_instance.history[start_idx:end_idx]:
        p, c, t = extract_tokens(entry)
        tot_p += p; tot_c += c; tot_t += t
    return {"prompt_tokens": tot_p, "completion_tokens": tot_c, "total_tokens": tot_t}

def compute_throughput(tokens: int, duration_sec: float) -> tuple[float, float]:
    if duration_sec <= 0:
        return 0.0, 0.0
    tps = tokens / duration_sec
    return tps, tps * 60.0

class TokenTracker:
    """Records every LM call: which agent, which step, which model, tokens and time."""

    def __init__(self):
        self.calls: list[dict] = []
        self.start_time = time.perf_counter()

    def record(self, agent, step, model, tokens, duration, n_entries=1):
        tps, tpm = compute_throughput(tokens["total_tokens"], duration)
        cached = n_entries > 0 and tokens["total_tokens"] == 0
        self.calls.append({"agent": agent, "step": step, "model": model, **tokens, "cached": cached,
                           "duration_s": round(duration, 3), "tps": round(tps, 2), "tpm": round(tpm, 1)})
        print(f"\n[TOKENS] {agent} | {step} | {model}{' | cached answer (0 tokens)' if cached else ''}")
        print(f"Call Time:       {duration:.2f}s")
        print(f"Tokens Used:     Prompt: {tokens['prompt_tokens']} | "
              f"Completion: {tokens['completion_tokens']} | Total: {tokens['total_tokens']}")
        print(f"Throughput:      {tpm:,.1f} TPM ({tps:.2f} TPS)")

    @staticmethod
    def totals(calls):
        t = {k: sum(c[k] for c in calls) for k in ("prompt_tokens", "completion_tokens", "total_tokens")}
        t["calls"] = len(calls)
        t["duration_s"] = round(sum(c["duration_s"] for c in calls), 3)
        t["tps"], t["tpm"] = (round(v, 2) for v in compute_throughput(t["total_tokens"], t["duration_s"]))
        return t

    def report(self, json_path: Path = None, extra: dict = None):
        groups = {}
        for c in self.calls:
            groups.setdefault(c["agent"], []).append(c)
        wall = time.perf_counter() - self.start_time
        print("\n================ TOKENS & THROUGHPUT SUMMARY ================")
        header = f"{'Agent':<30}{'Calls':>6}{'Prompt':>10}{'Completion':>12}{'Total':>10}{'LM time':>10}{'TPM':>14}"
        print(header); print("-" * len(header))
        per_agent = {}
        for agent, calls in groups.items():
            t = self.totals(calls); per_agent[agent] = t
            print(f"{agent:<30}{t['calls']:>6}{t['prompt_tokens']:>10}{t['completion_tokens']:>12}"
                  f"{t['total_tokens']:>10}{t['duration_s']:>9.1f}s{t['tpm']:>14,.1f}")
        # Big model vs small models
        roles = {"orchestrator (big model)": [c for c in self.calls if c["agent"] == "orchestrator"],
                 "workers (small model)": [c for c in self.calls if c["agent"] != "orchestrator"]}
        print("-" * len(header))
        for name, calls in roles.items():
            t = self.totals(calls)
            print(f"{name:<30}{t['calls']:>6}{t['prompt_tokens']:>10}{t['completion_tokens']:>12}"
                  f"{t['total_tokens']:>10}{t['duration_s']:>9.1f}s{t['tpm']:>14,.1f}")
        grand = self.totals(self.calls)
        print("-" * len(header))
        print(f"{'TOTAL':<30}{grand['calls']:>6}{grand['prompt_tokens']:>10}{grand['completion_tokens']:>12}"
              f"{grand['total_tokens']:>10}{grand['duration_s']:>9.1f}s{grand['tpm']:>14,.1f}")
        print(f"Script wall time: {wall:.1f}s (LM time is the part spent waiting for the models)")
        print("\nPer step:")
        for c in self.calls:
            print(f"  {c['agent']:<30} {c['step']:<40} {c['total_tokens']:>8} tokens  {c['duration_s']:>7.1f}s"
                  f"  {c['tpm']:>12,.1f} TPM{'  (cached)' if c['cached'] else ''}")
        print("=============================================================")
        if json_path is not None:
            Path(json_path).parent.mkdir(parents=True, exist_ok=True)
            Path(json_path).write_text(json.dumps(
                {"design": DESIGN, "wall_time_s": round(wall, 1), "total": grand, "per_agent": per_agent,
                 "per_role": {k: self.totals(v) for k, v in roles.items()}, "calls": self.calls, **(extra or {})},
                indent=2))
            print(f"Token usage saved to: {json_path}")

TOKENS = TokenTracker()

@contextlib.contextmanager
def metered(agent: str, step: str, lm):
    start_idx, start = len(lm.history), time.perf_counter()
    try:
        with dspy.context(lm=lm):
            yield
    finally:
        TOKENS.record(agent, step, getattr(lm, "model", "?"), get_token_stats(lm, start_idx),
                      time.perf_counter() - start, n_entries=len(lm.history) - start_idx)

# --- WHAT THE ORCHESTRATOR MUST KNOW ABOUT THE FLOW (fixed by the flow, not by Agent.md) ---

FLOW_CONSTRAINTS = f"""THE PIPELINE (fixed order of stages): testbench -> sdc -> rtl -> config_mk

Every subtask belongs to ONE stage and has ONE kind:
- "analysis"    : the worker writes notes (e.g. interface/timing analysis, test plan, architecture plan).
                  No tool checks it. Later subtasks receive it only if they list it in "uses".
- "deliverable" : the worker writes the stage's file. It is checked by the EDA tools. If a stage has
                  several deliverables, each one must pass; the last one is the final file of the stage
                  (a later deliverable receives the previous version and can refine it).
Subtasks run stage by stage in the order above; inside a stage, in the order you list them.
Every stage needs at least one deliverable.

What each deliverable must be, and how it is checked:
- testbench : complete self-checking Verilog-2001 testbench for the module signature (no `timescale).
              CHECK: compiles with iverilog -Wall against an empty stub of the DUT with NO warnings,
              and prints the word PASS (and FAIL on a mismatch). The flow decides pass/fail of every
              simulation ONLY by searching PASS/FAIL in the log: any FAIL, a timeout, or no PASS = failure.
- sdc       : one of the two SDC templates (sequential with a clock / combinational), with every
              <PLACEHOLDER> filled and NOTHING else changed. CHECK: line-by-line against the template.
- rtl       : synthesizable Verilog-2001 module that matches the module signature exactly.
              CHECK: RTL simulation with the final testbench must pass, then Yosys synthesis (ORFS)
              must show no latches, multi-drivers, non-synthesizable constructs or errors
              {"(then a gate-level simulation must pass too)" if VERIFICATION_MODE == "BOTH" else ""}.
              The worker automatically receives the final testbench.
- config_mk : the config.mk template with every <PLACEHOLDER> filled. CHECK: the full OpenROAD flow
              (floorplan, placement, CTS, routing) must finish, then the PPA evaluation gives a score
              out of 100{f" that must reach {SCORE_THRESHOLD}" if SCORE_THRESHOLD is not None else ""}.
              The worker automatically receives the template, the final RTL, and the ORFS errors /
              evaluation report of its previous attempt.

The sdc deliverable automatically receives both SDC templates. Every worker receives the YAML spec,
the module signature, its goal, its own Agent.md, the outputs listed in "uses", its previous output
and the feedback (tool reports and your guidance).

Workers are SMALL models ({getattr(WORKER_LM, 'model', '?')}): each worker sees ONLY its own Agent.md, never
the other subtasks' prompts. A worker gets {WORKER_ATTEMPTS} attempts with the tool reports before you are
asked to step in. You can step in {INTERVENTIONS} times per subtask, and send the flow back to an earlier
subtask at most {MAX_REPLANS} times in total. At most {MAX_SUBTASKS} subtasks."""

PLAN_SCHEMA = """ONLY a JSON object, no markdown fences, no text around it:
{"subtasks": [
  {"id": "snake_case_unique_id",
   "stage": "testbench | sdc | rtl | config_mk",
   "kind": "analysis | deliverable",
   "goal": "one or two sentences: what this worker must produce",
   "uses": ["ids of EARLIER subtasks whose output this worker receives"],
   "agent_md": "# Role and Objective\\n...\\n\\n# Mandatory Rules\\n1. ...\\n\\n# Output Format\\n..."}
]}"""

DECISION_SCHEMA = """ONLY a JSON object, no markdown fences, no text around it:
{"diagnosis": "root cause of the failure in one or two sentences",
 "action": "retry | redo | abort",
 "target": "for 'redo': id of an EARLIER subtask to run again (the flow continues from there); else empty",
 "agent_md": "for 'retry': the complete NEW Agent.md of the failing worker, or empty to keep the current one;
              for 'redo': optionally a complete new Agent.md for the target subtask, or empty",
 "feedback": "plain guidance sent to the worker that runs next (concrete: what to change and how)"}
retry = the same worker tries again with your new Agent.md and/or guidance.
redo  = the problem comes from an earlier subtask (e.g. the testbench expects the wrong values).
abort = the task cannot succeed."""

# --- SIGNATURES ---

ORCH_INSTRUCTIONS = md_role(ORCH_SECTIONS) or (
    "You are the orchestrator of a team of small language-model workers that take a hardware "
    "specification to a placed-and-routed layout.")

class OrchestratorPlan(dspy.Signature):
    __doc__ = ORCH_INSTRUCTIONS
    orchestrator_rules = dspy.InputField(desc="Your own rules: how to plan and how to write worker prompts")
    flow_constraints   = dspy.InputField(desc="Fixed pipeline, subtask kinds and how every deliverable is checked")
    yaml_spec          = dspy.InputField(desc="Hardware specification in YAML format")
    module_signature   = dspy.InputField(desc="Exact Verilog module port declaration")
    feedback           = dspy.InputField(desc="Problems found in your previous plan, or 'First plan.'")
    plan_json          = dspy.OutputField(desc=PLAN_SCHEMA)

class OrchestratorDecide(dspy.Signature):
    __doc__ = ORCH_INSTRUCTIONS
    orchestrator_rules = dspy.InputField(desc="Your own rules, including how to handle failing workers")
    flow_constraints   = dspy.InputField(desc="Fixed pipeline, subtask kinds and how every deliverable is checked")
    yaml_spec          = dspy.InputField(desc="Hardware specification in YAML format")
    plan_status        = dspy.InputField(desc="The plan: every subtask with its status")
    failing_subtask    = dspy.InputField(desc="The subtask that keeps failing (id, stage, kind, goal)")
    current_agent_md   = dspy.InputField(desc="The Agent.md the failing worker used")
    failure_report     = dspy.InputField(desc="The worker's last output and the tool reports of its attempts")
    decision_json      = dspy.OutputField(desc=DECISION_SCHEMA)

class Worker(dspy.Signature):
    """You are a worker in an ASIC design team. Follow your Agent.md."""
    yaml_spec        = dspy.InputField(desc="Hardware specification in YAML format")
    module_signature = dspy.InputField(desc="Exact Verilog module port declaration")
    goal             = dspy.InputField(desc="Your subtask")
    rules            = dspy.InputField(desc="Your Mandatory Rules and Output Format (from your Agent.md)")
    template         = dspy.InputField(desc="Template to fill in, or 'None'")
    context          = dspy.InputField(desc="Outputs of earlier subtasks and files you must work with")
    previous_output  = dspy.InputField(desc="Your output in the previous attempt, or 'None (first attempt)'")
    feedback         = dspy.InputField(desc="Tool reports and guidance about your previous attempt")
    output           = dspy.OutputField(desc="ONLY the deliverable: the raw file content with no markdown fences "
                                                "and no explanation; for an analysis subtask, concise notes")

# --- HELPERS ---

def clip(text: str, limit: int = None) -> str:
    """Keep the head and the tail of a long text (logs can be huge)."""

    limit = limit or REPORT_CHARS
    text = eda.strip_ansi(text or "")
    if len(text) <= limit:
        return text
    half = limit // 2
    return text[:half] + f"\n... [{len(text) - limit} characters cut] ...\n" + text[-half:]

def parse_json(raw: str):
    raw = eda.strip_fences(raw)
    m = re.search(r"\{.*\}", raw, re.DOTALL)
    return json.loads(m.group(0) if m else raw)

def setup_logging(filename: Path):
    class Logger:
        def __init__(self, terminal, log_file):
            self.terminal, self.log = terminal, log_file
        def write(self, message):
            self.terminal.write(message)
            self.log.write(eda.strip_ansi(message)); self.log.flush()
        def flush(self):
            self.terminal.flush(); self.log.flush()
    Path(filename).parent.mkdir(parents=True, exist_ok=True)
    sys.stdout = Logger(sys.stdout, open(filename, "w", encoding="utf-8"))
    sys.stderr = sys.stdout

def lm_failure(e: Exception) -> tuple[bool, str]:
    """(is_parse_error, message) for an exception raised by an LM call."""

    name = type(e).__name__
    text = clip(str(e), 600)
    if "Parse" in name or "parse" in str(e)[:200].lower():
        return True, (f"Your previous answer could not be read ({name}). It was probably cut off because it "
                      f"was too long, or a required field was missing. Answer again, more concisely, with "
                      f"every output field.")
    return False, f"The model call failed ({name}): {text}"

# --- THE ORCHESTRATED FLOW ---

class WorkerCallError(Exception):
    """The worker's model call failed (API error or unreadable answer)."""

class Subtask:
    def __init__(self, d: dict, order: int):
        self.id = d["id"]; self.stage = d["stage"]; self.kind = d["kind"]
        self.goal = d.get("goal", ""); self.uses = list(d.get("uses") or [])
        self.order = order
        self.agent_md_versions = [d.get("agent_md", "")]
        self.output = None
        self.status = "pending"
        self.attempts = 0
        self.interventions = 0
        self.guidance = ""          # orchestrator guidance for the next run of this subtask

    @property
    def agent_md(self) -> str:
        return self.agent_md_versions[-1]

    def describe(self) -> str:
        return f"id={self.id} | stage={self.stage} | kind={self.kind} | goal={self.goal}"

class OrchestratedFlow:
    def __init__(self, yaml_spec: str, module_signature: str, module_id: str):
        self.yaml_spec = yaml_spec
        self.module_signature = module_signature
        self.module_id = module_id
        self.planner = dspy.ChainOfThought(OrchestratorPlan)
        self.decider = dspy.ChainOfThought(OrchestratorDecide)
        self.plan: list[Subtask] = []
        self.replans = 0
        self.escalations = 0
        self.best_score = None
        self.final_files: dict[str, Path] = {}
        self.history: list[dict] = []

        seq = SDC_SEQ_TEMPLATE.read_text().replace("<MODULE_NAME>", module_id)
        comb = SDC_COMB_TEMPLATE.read_text().replace("<MODULE_NAME>", module_id)
        self.sdc_seq, self.sdc_comb = seq, comb
        self.sdc_templates = f"OPTION A (Sequential):\n{seq}\n\nOPTION B (Combinational):\n{comb}"
        self.config_template = CONFIG_TEMPLATE.read_text().replace("<DESIGN_NAME>", module_id).replace("<PLATFORM>", ORFS_PLATFORM)

        self.orfs_design, self.orfs_src, self.orfs_results = eda.generate_orfs_project(
            module_id, ORFS_DIR, ORFS_PLATFORM, CONFIG_TEMPLATE)
        self.problem_number = re.search(r"p(\d+)", DESIGN).group(1)

    # ---------- 1. PLAN ----------

    def validate_plan(self, data) -> tuple[list[Subtask], list[str]]:
        errors = []
        items = data.get("subtasks") if isinstance(data, dict) else None
        if not isinstance(items, list) or not items:
            return [], ["The JSON must have a non-empty 'subtasks' list."]
        if len(items) > MAX_SUBTASKS:
            errors.append(f"{len(items)} subtasks, the maximum is {MAX_SUBTASKS}.")
        seen, tasks = set(), []
        for i, d in enumerate(items):
            if not isinstance(d, dict):
                errors.append(f"Subtask #{i + 1} is not an object."); continue
            sid = str(d.get("id", "")).strip()
            if not re.fullmatch(r"[A-Za-z0-9_\-]+", sid or "-"):
                errors.append(f"Subtask #{i + 1}: invalid id '{sid}' (use snake_case).")
            if sid in seen:
                errors.append(f"Duplicate id '{sid}'.")
            seen.add(sid)
            if d.get("stage") not in STAGES:
                errors.append(f"Subtask '{sid}': stage must be one of {STAGES}.")
            if d.get("kind") not in KINDS:
                errors.append(f"Subtask '{sid}': kind must be one of {KINDS}.")
            if not str(d.get("agent_md", "")).strip():
                errors.append(f"Subtask '{sid}': agent_md is empty. Write the worker's Agent.md.")
            d["id"] = sid
            tasks.append(d)
        if errors:
            return [], errors

        # Run order: by stage, then as listed
        ordered = sorted(tasks, key=lambda d: STAGES.index(d["stage"]))
        position = {d["id"]: n for n, d in enumerate(ordered)}
        for d in ordered:
            for u in d.get("uses") or []:
                if u not in position:
                    errors.append(f"Subtask '{d['id']}' uses unknown subtask '{u}'.")
                elif position[u] >= position[d["id"]]:
                    errors.append(f"Subtask '{d['id']}' uses '{u}', which does not run before it.")
        for stage in STAGES:
            if not any(d["stage"] == stage and d["kind"] == "deliverable" for d in ordered):
                errors.append(f"Stage '{stage}' has no deliverable subtask.")
        return ([Subtask(d, n) for n, d in enumerate(ordered)] if not errors else []), errors

    def make_plan(self) -> bool:
        feedback = "First plan."
        for attempt in range(1, MAX_PLAN_TRIES + 1):
            print(f"\n{M}{B}[ORCHESTRATOR] Planning (attempt {attempt}/{MAX_PLAN_TRIES})...{R}")
            try:
                with metered("orchestrator", f"plan, attempt {attempt}", ORCH_LM):
                    res = self.planner(orchestrator_rules=md_rules(ORCH_SECTIONS) or "None.",
                                       flow_constraints=FLOW_CONSTRAINTS, yaml_spec=self.yaml_spec,
                                       module_signature=self.module_signature, feedback=feedback)
            except Exception as e:
                is_parse, msg = lm_failure(e)
                print(f"{RD}❌ Planning call failed: {msg}{R}")
                if not is_parse and attempt < MAX_PLAN_TRIES:
                    time.sleep(30 * attempt)   # the API is overloaded: wait before trying again
                feedback = msg
                continue
            ORCH_LM.inspect_history(n=1)
            try:
                plan, errors = self.validate_plan(parse_json(res.plan_json))
            except (json.JSONDecodeError, ValueError) as e:
                plan, errors = [], [f"The plan is not valid JSON: {e}"]
            if plan:
                self.plan = plan
                self.save_plan()
                self.print_plan()
                return True
            feedback = "Your plan was rejected:\n- " + "\n- ".join(errors) + "\nReturn a corrected plan."
            print(f"{RD}❌ Plan rejected:{R}\n- " + "\n- ".join(errors))
        return False

    def save_plan(self):
        for t in self.plan:
            for v, md in enumerate(t.agent_md_versions, 1):
                eda.save_file(RUN_DIR / "agents" / t.id, f"Agent_v{v}.md", md)
        eda.save_file(RUN_DIR, "plan.json", json.dumps(
            [{"id": t.id, "stage": t.stage, "kind": t.kind, "goal": t.goal, "uses": t.uses,
              "agent_md_versions": len(t.agent_md_versions), "status": t.status, "attempts": t.attempts,
              "interventions": t.interventions} for t in self.plan], indent=2))

    def print_plan(self):
        print(f"\n{M}{B}[ORCHESTRATOR] Plan ({len(self.plan)} subtasks){R}")
        for n, t in enumerate(self.plan, 1):
            uses = f" (uses: {', '.join(t.uses)})" if t.uses else ""
            print(f"  {n}. [{t.stage:<9}] {t.kind:<11} {t.id}: {t.goal}{uses}")
        print(f"  Worker prompts saved in: {RUN_DIR / 'agents'}")

    def plan_status(self) -> str:
        return "\n".join(f"{n}. {t.describe()} | status={t.status} | attempts={t.attempts}"
                         for n, t in enumerate(self.plan, 1))

    # ---------- 2. EXECUTE ----------

    def final_deliverable(self, stage: str, before: int = None) -> str:
        """Latest passed deliverable of a stage (optionally only from subtasks before index 'before')."""

        for t in reversed(self.plan[:before] if before is not None else self.plan):
            if t.stage == stage and t.kind == "deliverable" and t.status == "passed" and t.output:
                return t.output
        return ""

    def worker_inputs(self, t: Subtask) -> tuple[str, str]:
        parts = []
        for u in t.uses:
            src = next(x for x in self.plan if x.id == u)
            parts.append(f"--- OUTPUT OF '{u}' ({src.stage} {src.kind}) ---\n{src.output or '(not available)'}")
        template = "None"
        if t.kind == "deliverable":
            earlier = self.final_deliverable(t.stage, before=t.order)
            if earlier:
                parts.append(f"--- CURRENT {t.stage.upper()} FILE (from an earlier subtask, refine it) ---\n{earlier}")
            if t.stage == "sdc":
                template = self.sdc_templates
            elif t.stage == "rtl":
                parts.append(f"--- TESTBENCH (your RTL must pass it) ---\n{self.final_deliverable('testbench')}")
            elif t.stage == "config_mk":
                template = self.config_template
                parts.append(f"--- FINAL RTL ---\n{self.final_deliverable('rtl')}")
        return template, ("\n\n".join(parts) or "None")

    def check(self, t: Subtask, output: str, attempt_tag: str) -> tuple[bool, str, str]:
        """Run the EDA checks of a deliverable. Returns (ok, cleaned output, report)."""

        out_dir = RUN_DIR / "subtasks" / t.id
        if t.kind == "analysis":
            text = output.strip()
            eda.save_file(out_dir, f"{attempt_tag}.md", text)
            return (bool(text), text, "Notes written." if text else "The notes are empty.")

        if t.stage == "testbench":
            code = eda.clean_verilog(output)
            path = eda.save_file(out_dir, f"{attempt_tag}_tb.v", code)
            ok, rep = eda.check_testbench(path, self.module_signature)
            if ok:
                self.final_files["testbench"] = eda.save_file(RUN_DIR / "final", f"{self.module_id}_tb.v", code)
            return ok, code, rep

        if t.stage == "sdc":
            sdc = eda.strip_fences(output)
            eda.save_file(out_dir, f"{attempt_tag}.sdc", sdc)
            ok, rep = eda.check_sdc(sdc, self.sdc_seq, self.sdc_comb)
            if ok:
                eda.save_file(self.orfs_design, "constraint.sdc", sdc)
                self.final_files["sdc"] = eda.save_file(RUN_DIR / "final", f"{self.module_id}.sdc", sdc)
            return ok, sdc, rep

        if t.stage == "rtl":
            code = eda.clean_verilog(output, fix_rtl=True)
            rtl_path = eda.save_file(out_dir, f"{attempt_tag}_{self.module_id}.v", code)
            tb_path = self.final_files.get("testbench")
            sim = eda.run_simulation(tb_path, rtl_path, "rtl")
            eda.save_file(out_dir, f"{attempt_tag}_sim.log", sim)
            if not eda.sim_passed(sim):
                return False, code, ("RTL simulation with the testbench FAILED (the bug can be in the RTL or in the "
                                     f"testbench's expected values):\n{clip(sim)}")
            # Synthesis with the default config.mk
            eda.save_file(self.orfs_src, f"{self.module_id}.v", code)
            eda.generate_orfs_project(self.module_id, ORFS_DIR, ORFS_PLATFORM, CONFIG_TEMPLATE)
            print(f"\n🚀 Synthesis (Yosys) for {self.module_id}...")
            ylog, rc = eda.run_yosys(ORFS_DIR, self.orfs_design / "config.mk")
            eda.save_file(out_dir, f"{attempt_tag}_yosys.log", ylog)
            issues = eda.extract_yosys_issues(ylog)
            if rc != 0 or issues:
                return False, code, f"RTL simulation passed, but synthesis FAILED:\n{issues or clip(ylog)}"
            if VERIFICATION_MODE == "BOTH":
                netlist = Path(ORFS_DIR) / "flow" / "results" / ORFS_PLATFORM / self.module_id / "base" / "1_2_yosys.v"
                post = eda.run_simulation(tb_path, netlist, "post_synth", pdk_path=PDK_RTL_PATH)
                eda.save_file(out_dir, f"{attempt_tag}_post_synth_sim.log", post)
                if not eda.sim_passed(post):
                    return False, code, ("RTL simulation and synthesis passed, but the gate-level simulation FAILED: "
                                         f"the synthesizer interpreted the RTL differently.\n{clip(post)}")
            self.final_files["rtl"] = eda.save_file(RUN_DIR / "final", f"{self.module_id}.v", code)
            return True, code, "RTL simulation passed and synthesis is clean."

        # config_mk
        cfg = eda.strip_fences(output)
        eda.save_file(out_dir, f"{attempt_tag}_config.mk", cfg)
        placeholders = re.findall(r"<[A-Z_]+>", cfg)
        if placeholders:
            return False, cfg, f"Unfilled placeholders in config.mk: {placeholders}"
        eda.save_file(self.orfs_design, "config.mk", cfg)
        print(f"\n🚀 OpenROAD flow for {self.module_id}...")
        olog, rc = eda.run_openroad_flow(ORFS_DIR, self.orfs_design / "config.mk")
        eda.save_file(out_dir, f"{attempt_tag}_orfs.log", olog)
        issues = eda.extract_orfs_issues(olog)
        if rc != 0 or issues:
            return False, cfg, f"OpenROAD flow FAILED:\n{issues or 'Fatal ORFS error.'}"
        if not (EVALUATION_DIR / "visible" / f"p{self.problem_number}" / f"p{self.problem_number}.json").exists():
            # No reference results (e.g. p11-p13): the layout is accepted without a score
            (RUN_DIR / "final").mkdir(parents=True, exist_ok=True)
            for f in ["6_final.odb", "6_final.sdc"]:
                shutil.copy(self.orfs_results / f, RUN_DIR / "final" / f)
            self.final_files["config_mk"] = eda.save_file(RUN_DIR / "final", f"{self.module_id}_config.mk", cfg)
            return True, cfg, "OpenROAD flow finished. No reference results for this design: the layout is not scored."
        elog, erc = eda.run_evaluation(EVALUATION_DIR, self.orfs_results, ORFS_DIR, self.problem_number)
        print(elog)
        eda.save_file(out_dir, f"{attempt_tag}_evaluation.log", elog)
        metrics = Path.cwd() / f"p{self.problem_number}.json"
        if metrics.exists():
            eda.save_file(out_dir, f"{attempt_tag}_metrics.json", metrics.read_text()); metrics.unlink()
        if erc != 0:
            return False, cfg, f"The PPA evaluation failed:\n{clip(elog)}"
        score, wns = eda.parse_score(elog)
        if self.best_score is None or score > self.best_score:
            self.best_score = score
            (RUN_DIR / "final").mkdir(parents=True, exist_ok=True)
            for f in ["6_final.odb", "6_final.sdc"]:
                shutil.copy(self.orfs_results / f, RUN_DIR / "final" / f)
            self.final_files["config_mk"] = eda.save_file(RUN_DIR / "final", f"{self.module_id}_config.mk", cfg)
            print(f"{G}🏆 New best score: {score:.2f}/100{R}")
        timing = f" Worst negative slack: {wns} ns." if wns is not None else ""
        if SCORE_THRESHOLD is not None and score < float(SCORE_THRESHOLD):
            severe = " Timing fails by far (WNS < -0.5 ns): config.mk alone may not fix it." if wns is not None and wns < -0.5 else ""
            return False, cfg, (f"The OpenROAD flow finished with score {score:.2f}/100, below the required "
                                f"{SCORE_THRESHOLD}.{timing}{severe}\nEvaluation report:\n{clip(elog)}")
        return True, cfg, f"OpenROAD flow finished. Score {score:.2f}/100.{timing}"

    def run_worker(self, t: Subtask, feedback: str, previous: str) -> str:
        sections = parse_agent_md(t.agent_md)
        signature = Worker.with_instructions(md_role(sections) or Worker.__doc__)
        worker = dspy.ChainOfThought(signature)
        template, context = self.worker_inputs(t)
        t.attempts += 1
        step = f"attempt {t.attempts} (Agent.md v{len(t.agent_md_versions)})"
        print(f"\n{C}[WORKER {t.id}] {t.stage}/{t.kind} | {step}{R}")
        try:
            with metered(f"worker/{t.id}", step, WORKER_LM):
                res = worker(yaml_spec=self.yaml_spec, module_signature=self.module_signature, goal=t.goal,
                             rules=md_rules(sections) or "None.", template=template, context=context,
                             previous_output=previous or "None (first attempt)", feedback=feedback)
        except Exception as e:
            is_parse, msg = lm_failure(e)
            if not is_parse:
                time.sleep(20)   # give an overloaded API some time
            raise WorkerCallError(msg) from e
        WORKER_LM.inspect_history(n=1)
        return res.output or ""

    def run_subtask(self, t: Subtask) -> tuple[str, str, str]:
        """Run one subtask until it passes. Returns (result, redo_target, redo_feedback).
        result: 'passed' | 'redo' | 'failed'."""

        t.status = "running"
        previous = t.output if t.output else ""
        feedback = "First attempt." + (f"\n\nGUIDANCE FROM THE ORCHESTRATOR:\n{t.guidance}" if t.guidance else "")
        while True:
            reports = []
            for _ in range(WORKER_ATTEMPTS):
                try:
                    output = self.run_worker(t, feedback, previous)
                except WorkerCallError as e:
                    report = str(e)
                    print(f"{RD}❌ {t.id}: {report}{R}")
                    reports.append(f"--- ATTEMPT {t.attempts} ---\n{report}")
                    feedback = report + (f"\n\nGUIDANCE FROM THE ORCHESTRATOR:\n{t.guidance}" if t.guidance else "")
                    continue
                ok, cleaned, report = self.check(t, output, f"attempt_{t.attempts}")
                previous = cleaned
                self.history.append({"subtask": t.id, "attempt": t.attempts, "agent_md_version": len(t.agent_md_versions),
                                     "passed": ok, "report": clip(report, 1000)})
                if ok:
                    print(f"{G}{B}✅ {t.id}: {report}{R}")
                    t.output, t.status, t.guidance = cleaned, "passed", ""
                    return "passed", "", ""
                print(f"{RD}❌ {t.id}: {clip(report, 1500)}{R}")
                reports.append(f"--- ATTEMPT {t.attempts} ---\n{report}")
                feedback = report + (f"\n\nGUIDANCE FROM THE ORCHESTRATOR:\n{t.guidance}" if t.guidance else "")

            # ---------- 3. ESCALATE ----------
            if t.interventions >= INTERVENTIONS:
                t.status = "failed"
                print(f"{RD}{B}❌ {t.id}: no orchestrator interventions left.{R}")
                return "failed", "", ""
            t.interventions += 1
            self.escalations += 1
            print(f"\n{M}{B}[ORCHESTRATOR] Worker '{t.id}' keeps failing. Intervention {t.interventions}/{INTERVENTIONS}...{R}")
            failure = (f"--- LAST OUTPUT OF THE WORKER ---\n{clip(previous)}\n\n" +
                       clip("\n\n".join(reports), REPORT_CHARS * 2))
            try:
                with metered("orchestrator", f"intervention {t.interventions} on '{t.id}'", ORCH_LM):
                    res = self.decider(orchestrator_rules=md_rules(ORCH_SECTIONS) or "None.",
                                       flow_constraints=FLOW_CONSTRAINTS, yaml_spec=self.yaml_spec,
                                       plan_status=self.plan_status(), failing_subtask=t.describe(),
                                       current_agent_md=t.agent_md, failure_report=failure)
                ORCH_LM.inspect_history(n=1)
                d = parse_json(res.decision_json)
            except (json.JSONDecodeError, ValueError):
                d = {"action": "retry", "feedback": "", "agent_md": "", "diagnosis": "(unreadable decision)"}
            except Exception as e:
                _, msg = lm_failure(e)
                print(f"{RD}❌ Orchestrator call failed: {msg}{R}")
                d = {"action": "retry", "feedback": "", "agent_md": "", "diagnosis": "(orchestrator call failed)"}
            action = str(d.get("action", "retry")).lower()
            print(f"{M}  Diagnosis: {d.get('diagnosis', '')}\n  Decision : {action}"
                  f"{' -> ' + str(d.get('target')) if action == 'redo' else ''}{R}")

            if action == "abort":
                t.status = "failed"
                return "failed", "", ""

            if action == "redo":
                target = next((x for x in self.plan if x.id == d.get("target") and x.order < t.order), None)
                if target is None:
                    print(f"{Y}⚠️  Invalid redo target '{d.get('target')}'. Retrying '{t.id}' instead.{R}")
                elif self.replans >= MAX_REPLANS:
                    print(f"{Y}⚠️  No replans left ({MAX_REPLANS}). Retrying '{t.id}' instead.{R}")
                else:
                    self.replans += 1
                    if str(d.get("agent_md", "")).strip():
                        target.agent_md_versions.append(d["agent_md"])
                    target.guidance = d.get("feedback", "")
                    t.status = "pending"
                    self.save_plan()
                    return "redo", target.id, target.guidance

            # retry (also the fallback of an invalid redo)
            if str(d.get("agent_md", "")).strip() and action == "retry":
                t.agent_md_versions.append(d["agent_md"])
                print(f"{M}  New Agent.md for '{t.id}' (v{len(t.agent_md_versions)}).{R}")
            t.guidance = d.get("feedback", "")
            feedback = (reports[-1] if reports else "") + \
                       (f"\n\nGUIDANCE FROM THE ORCHESTRATOR:\n{t.guidance}" if t.guidance else "")
            self.save_plan()

    def run(self) -> str:
        if not self.make_plan():
            print(f"{RD}{B}❌ The orchestrator could not produce a valid plan.{R}")
            return "Fail"
        i = 0
        while i < len(self.plan):
            t = self.plan[i]
            result, target, _ = self.run_subtask(t)
            self.save_plan()
            if result == "passed":
                i += 1
            elif result == "redo":
                j = next(n for n, x in enumerate(self.plan) if x.id == target)
                print(f"\n{M}{B}[ORCHESTRATOR] Going back to '{target}' (replan {self.replans}/{MAX_REPLANS}).{R}")
                for x in self.plan[j:]:
                    x.status = "pending"   # later outputs must be rebuilt on the new upstream result
                i = j
            else:
                return "Fail"
        return "Success"

    def summary(self) -> dict:
        print("\n================ ORCHESTRATED FLOW SUMMARY ================")
        print(f"{'Subtask':<28}{'Stage':<11}{'Kind':<13}{'Status':<9}{'Attempts':>9}{'Interv.':>9}{'Agent.md':>10}")
        for t in self.plan:
            print(f"{t.id:<28}{t.stage:<11}{t.kind:<13}{t.status:<9}{t.attempts:>9}{t.interventions:>9}"
                  f"{'v' + str(len(t.agent_md_versions)):>10}")
        print(f"Orchestrator interventions: {self.escalations} | replans: {self.replans}/{MAX_REPLANS}")
        print(f"Best score: {self.best_score:.2f}/100" if self.best_score is not None else "Best score: -")
        print(f"Final files: {RUN_DIR / 'final'}")
        print("===========================================================")
        return {"best_score": self.best_score, "interventions": self.escalations, "replans": self.replans,
                "subtasks": [{"id": t.id, "stage": t.stage, "kind": t.kind, "status": t.status, "attempts": t.attempts,
                              "interventions": t.interventions, "agent_md_versions": len(t.agent_md_versions)}
                             for t in self.plan]}

# --- ENVIRONMENT CHECK AND MAIN ---

def check_environment():
    global ORFS_DIR
    script_dir = Path(__file__).resolve().parent
    if Path.cwd().resolve() != script_dir:
        print(f"{RD}❌ Error: Run the script from its own folder: cd {script_dir}{R}")
        sys.exit(1)
    ok = True
    for tool in eda.which_missing():
        print(f"{RD}❌ Error: Tool '{tool}' not found in PATH.{R}"); ok = False
    if ORFS_DIR is None and shutil.which("openroad"):
        ORFS_DIR = next((p for p in Path(shutil.which("openroad")).resolve().parents if (p / "flow").is_dir()), None)
    for d in [EVALUATION_DIR, PROBLEMS_DIR, PDK_RTL_PATH, ORFS_DIR]:
        if d is None or not Path(d).exists():
            print(f"{RD}❌ Error: Required directory not found: '{d}'{R}"); ok = False
    for f in [PROBLEMS_DIR / DESIGN, CONFIG_TEMPLATE, SDC_SEQ_TEMPLATE, SDC_COMB_TEMPLATE,
              EVALUATION_DIR / "evaluate_openroad.py"]:
        if not Path(f).exists():
            print(f"{RD}❌ Error: File not found: '{f}'{R}"); ok = False
    if not ORCH_MD.exists():
        print(f"{RD}❌ Error: Orchestrator Agent.md not found: '{ORCH_MD}'{R}"); ok = False
    elif not md_role(ORCH_SECTIONS) or not md_rules(ORCH_SECTIONS):
        print(f"{Y}⚠️  The orchestrator Agent.md has an empty '# Role and Objective' or '# Mandatory Rules'.{R}")
    if not (EVALUATION_DIR / "visible" / Path(DESIGN).stem).exists():
        print(f"{Y}⚠️  No reference results for {DESIGN} in {EVALUATION_DIR / 'visible'}: the layout cannot be scored.{R}")
    if not ok:
        print(f"\n{RD}{B}CRITICAL: Environment check failed.{R}"); sys.exit(1)
    # Start from a clean run folder (the log of this run is kept)
    for sub in ["final", "subtasks", "agents"]:
        if (RUN_DIR / sub).exists():
            shutil.rmtree(RUN_DIR / sub)

    print("System is ready!\n")
    print(f"Run config            : {C}{ARGS.config}{R}")
    print(f"Design                : {C}{DESIGN}{R}")
    print(f"Orchestrator (big)    : {C}{ORCH_LM.model}{R}  prompt: {ORCH_MD}")
    print(f"Workers (small)       : {C}{WORKER_LM.model}{R}  prompts: written by the orchestrator")
    print(f"Limits                : {MAX_SUBTASKS} subtasks, {WORKER_ATTEMPTS} worker attempts, "
          f"{INTERVENTIONS} interventions/subtask, {MAX_REPLANS} replans")
    print(f"Score threshold       : {SCORE_THRESHOLD if SCORE_THRESHOLD is not None else 'none (first successful layout)'}")
    print(f"Outputs               : {RUN_DIR}\n")

def main() -> dict:
    start = time.time()
    setup_logging(RUN_DIR / "asic_orchestrated_flow.log")
    check_environment()

    data = yaml.safe_load((PROBLEMS_DIR / DESIGN).read_text())
    module_id = list(data.keys())[0]
    spec = data[module_id]

    flow = OrchestratedFlow(spec_text(spec), spec.get("module_signature", "module design(...);"), module_id)
    status = flow.run()
    summary = flow.summary()
    eda.save_file(RUN_DIR, "history.json", json.dumps(flow.history, indent=2))

    if status == "Success":
        print(f"\n{G}{B}✅ Success! The team reached a scored layout.{R}")
    else:
        print(f"\n{RD}{B}❌ Failure! The orchestrated flow did not complete.{R}")
    print(f"⏱️  Total flow time: {time.time() - start:.2f} seconds")
    return {"status": status, **summary}

if __name__ == "__main__":
    RESULT = {}
    try:
        RESULT = main()
    finally:
        TOKENS.report(RUN_DIR / "token_usage.json", extra={"flow": RESULT})
