########################################################################
# Project: Autonomous ASIC Design Flow (DSPy + iVerilog + OpenROAD)    #
# Author: Monastiriotis Theodoros                                      #
#                                                                      #
# Description:                                                         #
# An automated, iterative hardware development framework that uses     #
# Language Models via DSPy to transform high-level YAML specs into     #
# verified, synthesizable RTL and physical ODB layouts.                #
#                                                                      #
# Everything that can be changed lives OUTSIDE this script:            #
#   asic_autonomous_flow_config.yaml : flow parameters (design, ORFS,  #
#                                      iterations, modes, paths, ...)  #
#   configs/<agent>/config.yaml      : model profile of every agent    #
#   configs/<agent>/Agent.md         : instructions, rules, feedback   #
#                                                                      #
# Agent modes:                                                         #
#   single : ONE agent writes TB + RTL + SDC + config.mk together.     #
#   multi  : separate TB / SDC / RTL / config.mk agents, with optional #
#            TB and RTL validators (each with its own model).          #
#                                                                      #
# Architecture (multi mode):                                           #
# 1. TB Flow: Generates and self-validates Verilog-2001 testbenches.   #
# 2. SDC Flow: Creates timing constraints based on spec targets.       #
# 3. RTL Flow: Iterative generation with functional and gate-level     #
#    simulation feedback loop (Icarus Verilog + Yosys).                #
# 4. Physical Flow: Automates the OpenROAD Flow Scripts (ORFS) to      #
#    produce final ODB artifacts for a specified platform.             #
#                                                                      #
# Run (from the folder of this script):                                #
#   python3 asic_autonomous_flow.py --config run_configs/<run>.yaml    #
#   python3 asic_autonomous_flow.py --config <run>.yaml --design p1.yaml
#   python3 asic_autonomous_flow.py --config <run>.yaml --profile gemini_lite
#   python3 asic_autonomous_flow.py --config <run>.yaml --agent-profile rtl_generator=ollama-llama3.1
# See README.md for all the details.                                   #
########################################################################

import argparse
import contextlib
import dspy
import os
import sys
import yaml
import json
import re
import time
import subprocess
import shutil
import tempfile
import threading
from pathlib import Path
from dspy.teleprompt import MIPROv2

# --- COMMAND LINE ---

DEFAULT_FLOW_CONFIG = Path("./asic_autonomous_flow_config.yaml")

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Autonomous ASIC design flow (DSPy + iVerilog + OpenROAD). "
                    "Every option overrides the matching value of the flow config file."
    )
    parser.add_argument("--config", type=Path, default=DEFAULT_FLOW_CONFIG,
                        help=f"Flow config file (default: {DEFAULT_FLOW_CONFIG})")
    parser.add_argument("--mode", choices=["single", "multi"],
                        help="Agent mode: one agent for the whole flow, or one agent per step")
    parser.add_argument("--design", help="Design spec inside problems_dir, e.g. p1.yaml")
    parser.add_argument("--profile",
                        help="Use this profile for EVERY agent (must exist in each agent's config.yaml)")
    parser.add_argument("--agent-profile", action="append", default=[], metavar="AGENT=PROFILE",
                        help="Use PROFILE for one AGENT, e.g. rtl_generator=claude-sonnet-5-5 (repeatable)")
    return parser.parse_args()

# --- FLOW CONFIG FILE (asic_autonomous_flow_config.yaml) ---

def load_flow_config(path: Path) -> dict:
    """Load the flow config YAML file."""

    path = Path(path)
    if not path.exists():
        raise SystemExit(f"Error: flow config file not found: {path}\n"
                         f"Pick one with --config, e.g. --config run_configs/<run>.yaml")
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

def cfg_get(cfg: dict, dotted_key: str, default=None):
    """Read a nested value such as 'iterations.max_tb_gen_iters' from the flow config."""

    node = cfg
    for part in dotted_key.split("."):
        if not isinstance(node, dict) or part not in node:
            return default
        node = node[part]
    return default if node is None and default is not None else node

def opt_path(value):
    """None/empty stays None, everything else becomes a Path."""

    return Path(value).expanduser() if value not in (None, "") else None

ARGS        = parse_args()
FLOW_CONFIG = load_flow_config(ARGS.config)

# --- AGENTS ---

# Agent mode: "single" (ONE agent for the whole flow) or "multi" (one agent per step)
AGENT_MODE = (ARGS.mode or cfg_get(FLOW_CONFIG, "agents.mode", "multi")).lower()
if AGENT_MODE not in ("single", "multi"):
    raise SystemExit(f"Error: agents.mode must be 'single' or 'multi', got '{AGENT_MODE}'.")

# Every agent has its own folder inside AGENTS_DIR:
#   configs/<agent>/config.yaml : model profiles (which LM / API the agent uses)
#   configs/<agent>/Agent.md    : instructions, rules and feedback messages of the agent
AGENTS_DIR = Path(cfg_get(FLOW_CONFIG, "agents.agents_dir", "./configs"))

# Agents of the multi-agent mode, and the single agent
MULTI_AGENT_NAMES = ["tb_generator", "tb_validator", "sdc_generator", "rtl_generator",
                     "rtl_validator", "config_mk_generator", "mipro_teacher"]
ALL_AGENT_NAMES   = MULTI_AGENT_NAMES + ["single_agent"]

# These agents may be disabled (enabled: false in the flow config)
OPTIONAL_AGENTS = ["tb_validator", "rtl_validator", "mipro_teacher"]

def _agent_cfg(name: str) -> dict:
    return cfg_get(FLOW_CONFIG, f"agents.{name}", {}) or {}

def _agent_enabled(name: str) -> bool:
    """Required agents are always enabled; the optional ones follow 'enabled' in the flow config."""
    if name not in OPTIONAL_AGENTS:
        return True
    return bool(_agent_cfg(name).get("enabled", False))

# config.yaml of every agent (None = disabled agent)
AGENT_CONFIGS = {
    name: (AGENTS_DIR / name / "config.yaml") if _agent_enabled(name) else None
    for name in ALL_AGENT_NAMES
}

# Agent.md of every agent. They are always loaded, because the DSPy signatures are built from them.
AGENT_MD_FILES = {name: AGENTS_DIR / name / "Agent.md" for name in ALL_AGENT_NAMES if name != "mipro_teacher"}
SINGLE_AGENT_MD = AGENT_MD_FILES["single_agent"]

# Profile of every agent. Priority (highest first):
#   1. --agent-profile AGENT=PROFILE   (command line)
#   2. --profile PROFILE               (command line, all agents)
#   3. agents.<agent>.profile          (flow config)
#   4. agents.default_profile          (flow config, all agents)
#   5. active_profile                  (configs/<agent>/config.yaml)
def _resolve_profiles() -> dict:
    per_agent_cli = {}
    for item in ARGS.agent_profile:
        if "=" not in item:
            raise SystemExit(f"Error: --agent-profile expects AGENT=PROFILE, got '{item}'.")
        agent, profile = (s.strip() for s in item.split("=", 1))
        if agent not in ALL_AGENT_NAMES:
            raise SystemExit(f"Error: unknown agent '{agent}' in --agent-profile. Agents: {', '.join(ALL_AGENT_NAMES)}")
        per_agent_cli[agent] = profile

    default_profile = cfg_get(FLOW_CONFIG, "agents.default_profile")
    profiles = {}
    for name in ALL_AGENT_NAMES:
        profiles[name] = (per_agent_cli.get(name) or ARGS.profile
                          or _agent_cfg(name).get("profile") or default_profile or None)
    return profiles

AGENT_PROFILES = _resolve_profiles()

# --- Agent config file loader ---
#
# A configs/<agent>/config.yaml file looks like this:
#
#   active_profile: "claude-haiku-4-5"
#   profiles:
#     ollama-llama3.1:
#       model: "ollama_chat/llama3.1"
#       api_base: "http://localhost:11434"
#       temperature: 0.0
#       cache: true
#     claude-haiku-4-5:
#       model: "anthropic/claude-haiku-4-5-20251001"
#       api_key: "$ANTHROPIC_API_KEY"
#       temperature: 0.0
#
# 'model' is required. Every other key of the profile is passed to dspy.LM
# (api_base, api_key, temperature, cache, max_tokens, num_ctx, ...).
# api_key: "$NAME" reads the key from the environment variable NAME.
# Empty values and api_keys that start with "YOUR_" are ignored, so the provider falls back
# to its own environment variable (GEMINI_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY, ...).

_LM_CACHE: dict = {}

def load_lm(config_path, profile: str = None) -> "dspy.LM":
    """Build a dspy.LM from a profile of a YAML config file (default: its active_profile)."""

    path = Path(config_path)
    if not path.exists():
        raise SystemExit(f"Error: LM config file not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f) or {}

    profiles = cfg.get("profiles") or {}
    active = profile or cfg.get("active_profile")
    if active not in profiles:
        raise SystemExit(
            f"Error: profile '{active}' not found in {path}. "
            f"Available profiles: {', '.join(profiles) or 'none'}"
        )

    # The same file + profile always gives the same LM object
    key = (str(path.resolve()), active)
    if key in _LM_CACHE:
        return _LM_CACHE[key]

    kwargs = dict(profiles[active] or {})
    model = kwargs.pop("model", None)
    if not model:
        raise SystemExit(f"Error: profile '{active}' in {path} has no 'model'.")

    # Drop empty values so that the provider defaults / environment variables are used
    kwargs = {k: v for k, v in kwargs.items() if v not in ("", None)}

    api_key = kwargs.get("api_key")
    if isinstance(api_key, str) and api_key.startswith("$"):
        # Read the key from an environment variable
        env_name = api_key[1:]
        kwargs["api_key"] = os.getenv(env_name, "")
        if not kwargs["api_key"]:
            print(f"Warning: environment variable '{env_name}' ({path} [{active}]) is not set. "
                  f"Load your keys first: source /home/scripts/api_keys.sh")
            kwargs.pop("api_key")
    elif isinstance(api_key, str) and api_key.startswith("YOUR_"):
        # Ignore placeholder keys (use the provider's environment variable instead)
        print(f"Warning: {path} [{active}] has a placeholder api_key; using the provider's environment variable instead.")
        kwargs.pop("api_key")

    kwargs.setdefault("cache", False)

    lm = dspy.LM(model, **kwargs)
    print(f"[LM] {path.parent.name}/{path.name} -> profile '{active}' ({model})")
    _LM_CACHE[key] = lm
    return lm

def _load_agent_lm(name: str):
    """Load the LM of an agent with its selected profile, or None if the agent is disabled."""

    path = AGENT_CONFIGS.get(name)
    return load_lm(path, AGENT_PROFILES.get(name)) if path is not None else None

# --- Build the LMs of the selected mode ---

SINGLE_AGENT_LM        = None
TB_GENERATOR_LM        = None
TB_VALIDATOR_LM        = None
SDC_GENERATOR_LM       = None
RTL_GENERATOR_LM       = None
RTL_VALIDATOR_LM       = None
CONFIG_MK_GENERATOR_LM = None

if AGENT_MODE == "single":
    SINGLE_AGENT_LM = _load_agent_lm("single_agent")
    dspy.configure(lm=SINGLE_AGENT_LM)
else:
    TB_GENERATOR_LM        = _load_agent_lm("tb_generator")
    TB_VALIDATOR_LM        = _load_agent_lm("tb_validator")
    SDC_GENERATOR_LM       = _load_agent_lm("sdc_generator")
    RTL_GENERATOR_LM       = _load_agent_lm("rtl_generator")
    RTL_VALIDATOR_LM       = _load_agent_lm("rtl_validator")
    CONFIG_MK_GENERATOR_LM = _load_agent_lm("config_mk_generator")

    # Default dspy LM. It is used by the RTL Generator when "Optimize" mode is enabled.
    dspy.configure(lm=RTL_GENERATOR_LM)

# MIPROv2 optimization: the student is the RTL generator, the teacher is the MIPROv2 teacher
# (or the RTL generator itself if the teacher is disabled).
SLM = RTL_GENERATOR_LM
LLM = (_load_agent_lm("mipro_teacher") if AGENT_MODE == "multi" else None) or SLM

# --- FLOW CONFIGURATION (from the flow config file) ---

DESIGN        = ARGS.design or cfg_get(FLOW_CONFIG, "design.design", "p1.yaml")      # The specific spec
ORFS_PLATFORM = cfg_get(FLOW_CONFIG, "design.orfs_platform", "sky130hd")             # Target platform for ORFS
PDK_RTL_PATH  = Path(cfg_get(FLOW_CONFIG, "design.pdk_rtl_path", "./PDK_files/"))    # Verilog simulation models of the platform

# Path of the OpenROAD-flow-scripts directory. The ORFS_DIR environment variable (local installs)
# overrides the config. None: auto-detected from 'openroad' in PATH.
ORFS_DIR = opt_path(os.environ.get("ORFS_DIR") or cfg_get(FLOW_CONFIG, "design.orfs_dir"))

# Verification mode: "RTL" (RTL simulation only) or "BOTH" (RTL + post-synthesis gate-level simulation)
VERIFICATION_MODE = str(cfg_get(FLOW_CONFIG, "flow.verification_mode", "RTL")).upper()

# True: the RTL Validator is skipped even if it is enabled
SKIP_RTL_VALIDATOR = bool(cfg_get(FLOW_CONFIG, "flow.skip_rtl_validator", False))

# RTL generation DSPy mode (multi mode only): "Simple Run", "Optimize" or "Inference"
RTL_GEN_DSPY_MODE       = cfg_get(FLOW_CONFIG, "flow.rtl_gen_dspy_mode", "Simple Run")
RTL_TRAIN_DESIGNS       = list(cfg_get(FLOW_CONFIG, "flow.rtl_train_designs", []) or [])
OPTIMIZED_RTL_FLOW_PATH = Path(cfg_get(FLOW_CONFIG, "flow.optimized_rtl_flow_path", "../results/optimized_rtl_generator.json"))

# Iterative score optimization of the physical flow
ITERATIVE_OPTIMIZATION = bool(cfg_get(FLOW_CONFIG, "flow.iterative_optimization", True))
SCORE_THRESHOLD        = float(cfg_get(FLOW_CONFIG, "flow.score_threshold", 70.0))

# Resynthesis (regenerate the RTL) when timing is not met by far (WNS < -0.5 ns)
ENABLE_RESYNTHESIS       = bool(cfg_get(FLOW_CONFIG, "flow.enable_resynthesis", False))
MAX_RESYNTHESIS_ATTEMPTS = int(cfg_get(FLOW_CONFIG, "flow.max_resynthesis_attempts", 3))

# Maximum iterations of every flow
MAX_TB_GEN_ITERS       = int(cfg_get(FLOW_CONFIG, "iterations.max_tb_gen_iters", 10))
MAX_RTL_GEN_ITERS      = int(cfg_get(FLOW_CONFIG, "iterations.max_rtl_gen_iters", 10))
MAX_SDC_GEN_ITERS      = int(cfg_get(FLOW_CONFIG, "iterations.max_sdc_gen_iters", 10))
MAX_PHYSICAL_ITERS     = int(cfg_get(FLOW_CONFIG, "iterations.max_physical_iters", 10))
MAX_SINGLE_AGENT_ITERS = int(cfg_get(FLOW_CONFIG, "iterations.max_single_agent_iters", 10))

# Master counters of every flow (always start at iteration 1)
TB_GEN_ITER   = 1
RTL_GEN_ITER  = 1
SDC_GEN_ITER  = 1
PHYSICAL_ITER = 1

# Flow overrides (multi mode only): use the given file and skip the generation of that stage
TB_PATH     = opt_path(cfg_get(FLOW_CONFIG, "overrides.tb_path"))
SDC_PATH    = opt_path(cfg_get(FLOW_CONFIG, "overrides.sdc_path"))
RTL_PATH    = opt_path(cfg_get(FLOW_CONFIG, "overrides.rtl_path"))
CONFIG_PATH = opt_path(cfg_get(FLOW_CONFIG, "overrides.config_path"))

# Directories and templates
EVALUATION_DIR = Path(cfg_get(FLOW_CONFIG, "paths.evaluation_dir", "../evaluation/"))
PROBLEMS_DIR   = Path(cfg_get(FLOW_CONFIG, "paths.problems_dir", "../problems/visible/"))
RESULTS_DIR    = Path(cfg_get(FLOW_CONFIG, "paths.results_dir", "../results/visible")) / Path(DESIGN).stem
SOLUTIONS_DIR  = Path(cfg_get(FLOW_CONFIG, "paths.solutions_dir", "../solutions/visible")) / Path(DESIGN).stem

TB_GEN_DIR     = RESULTS_DIR / "tb_gen_flow"     # Results for tb generation flow
RTL_GEN_DIR    = RESULTS_DIR / "rtl_gen_flow"    # Results for rtl generation flow
SDC_GEN_DIR    = RESULTS_DIR / "sdc_gen_flow"    # Results for sdc generation flow
PHYSICAL_DIR   = RESULTS_DIR / "physical_flow"   # Results for physical flow

CONFIG_TEMPLATE   = Path(cfg_get(FLOW_CONFIG, "paths.config_template", "./templates/config.mk"))
SDC_COMB_TEMPLATE = Path(cfg_get(FLOW_CONFIG, "paths.sdc_comb_template", "./templates/constraint_comb.sdc"))
SDC_SEQ_TEMPLATE  = Path(cfg_get(FLOW_CONFIG, "paths.sdc_seq_template", "./templates/constraint_seq.sdc"))

LOG_FILE = cfg_get(FLOW_CONFIG, "paths.log_file", "asic_autonomous_flow.log")

# The PPA score needs reference results in <evaluation_dir>/visible/pN/pN.json.
# Designs without them (e.g. p11-p13) still run the whole flow, but the layout is not scored.
_PROBLEM = re.search(r"p(\d+)", Path(DESIGN).stem)
HAS_EVAL_REFERENCE = bool(_PROBLEM) and (EVALUATION_DIR / "visible" / f"p{_PROBLEM.group(1)}" / f"p{_PROBLEM.group(1)}.json").exists()

# --- TOKEN & THROUGHPUT TRACKING (same metrics as part1/utility_func.py) ---

def extract_tokens(entry: dict) -> tuple[int, int, int]:
    """Extract prompt, completion and total tokens from one LM history entry."""

    usage = entry.get("usage", {}) or {}
    if isinstance(usage, dict):
        p = usage.get("prompt_tokens") or usage.get("prompt_eval_count", 0) or 0
        c = usage.get("completion_tokens") or usage.get("eval_count", 0) or 0
        return p, c, usage.get("total_tokens") or (p + c)
    p = getattr(usage, "prompt_tokens", 0) or getattr(usage, "prompt_eval_count", 0) or 0
    c = getattr(usage, "completion_tokens", 0) or getattr(usage, "eval_count", 0) or 0
    return p, c, getattr(usage, "total_tokens", 0) or (p + c)

def get_token_stats(lm_instance, start_idx: int = 0, end_idx: int = None) -> dict:
    """Token usage of a range of LM history entries."""

    tot_p = tot_c = tot_t = 0
    for entry in lm_instance.history[start_idx:end_idx]:
        p, c, t = extract_tokens(entry)
        tot_p += p; tot_c += c; tot_t += t
    return {"prompt_tokens": tot_p, "completion_tokens": tot_c, "total_tokens": tot_t}

def compute_throughput(tokens: int, duration_sec: float) -> tuple[float, float]:
    """Tokens Per Second (TPS) and Tokens Per Minute (TPM)."""

    if duration_sec <= 0:
        return 0.0, 0.0
    tps = tokens / duration_sec
    return tps, tps * 60.0

class TokenTracker:
    """Records every LM call: which agent, which step, which model, tokens and time."""

    def __init__(self):
        self.calls: list[dict] = []
        self.start_time = time.perf_counter()

    def record(self, agent: str, step: str, model: str, tokens: dict, duration: float, n_entries: int = 1):
        tps, tpm = compute_throughput(tokens["total_tokens"], duration)
        # With 'cache: true' a repeated prompt is answered from the cache: no tokens are used
        cached = n_entries > 0 and tokens["total_tokens"] == 0
        self.calls.append({"agent": agent, "step": step, "model": model, **tokens, "cached": cached,
                           "duration_s": round(duration, 3), "tps": round(tps, 2), "tpm": round(tpm, 1)})
        print(f"\n[TOKENS] {agent} | {step} | {model}{' | cached answer (0 tokens)' if cached else ''}")
        print(f"Call Time:       {duration:.2f}s")
        print(f"Tokens Used:     Prompt: {tokens['prompt_tokens']} | "
              f"Completion: {tokens['completion_tokens']} | Total: {tokens['total_tokens']}")
        print(f"Throughput:      {tpm:,.1f} TPM ({tps:.2f} TPS)")

    def totals(self, calls: list[dict]) -> dict:
        t = {k: sum(c[k] for c in calls) for k in ("prompt_tokens", "completion_tokens", "total_tokens")}
        t["calls"] = len(calls)
        t["duration_s"] = round(sum(c["duration_s"] for c in calls), 3)
        t["tps"], t["tpm"] = (round(v, 2) for v in compute_throughput(t["total_tokens"], t["duration_s"]))
        return t

    def report(self, json_path: Path = None):
        """Print the per-agent summary (and per step) and save every call to a JSON file."""

        agents = {}
        for c in self.calls:
            agents.setdefault(c["agent"], []).append(c)
        wall = time.perf_counter() - self.start_time

        print("\n================ TOKENS & THROUGHPUT SUMMARY ================")
        if not self.calls:
            print("No LM calls were made.")
        header = f"{'Agent':<22}{'Calls':>6}{'Prompt':>10}{'Completion':>12}{'Total':>10}{'LM time':>10}{'TPM':>14}"
        print(header)
        print("-" * len(header))
        summary = {}
        for agent, calls in agents.items():
            t = self.totals(calls); summary[agent] = t
            print(f"{agent:<22}{t['calls']:>6}{t['prompt_tokens']:>10}{t['completion_tokens']:>12}"
                  f"{t['total_tokens']:>10}{t['duration_s']:>9.1f}s{t['tpm']:>14,.1f}")
        grand = self.totals(self.calls)
        print("-" * len(header))
        print(f"{'TOTAL':<22}{grand['calls']:>6}{grand['prompt_tokens']:>10}{grand['completion_tokens']:>12}"
              f"{grand['total_tokens']:>10}{grand['duration_s']:>9.1f}s{grand['tpm']:>14,.1f}")
        print(f"Script wall time: {wall:.1f}s (LM time is the part spent waiting for the models)")

        print("\nPer step:")
        for c in self.calls:
            print(f"  {c['agent']:<22} {c['step']:<40} {c['total_tokens']:>8} tokens  {c['duration_s']:>7.1f}s"
                  f"  {c['tpm']:>12,.1f} TPM{'  (cached)' if c['cached'] else ''}")
        print("=============================================================")

        if json_path is not None:
            Path(json_path).parent.mkdir(parents=True, exist_ok=True)
            Path(json_path).write_text(json.dumps(
                {"design": DESIGN, "agent_mode": AGENT_MODE, "wall_time_s": round(wall, 1),
                 "total": grand, "per_agent": summary, "calls": self.calls}, indent=2))
            print(f"Token usage saved to: {json_path}")

TOKENS = TokenTracker()

# Every run config writes its token report next to its log
TOKEN_REPORT = Path(LOG_FILE).parent / "token_usage.json"

@contextlib.contextmanager
def metered(agent: str, step: str, lm, set_context: bool = True):
    """Run LM calls inside this block with 'lm' and record their tokens and time."""

    start_idx = len(lm.history)
    start = time.perf_counter()
    try:
        if set_context:
            with dspy.context(lm=lm):
                yield
        else:
            yield
    finally:
        TOKENS.record(agent, step, getattr(lm, "model", "?"), get_token_stats(lm, start_idx),
                      time.perf_counter() - start, n_entries=len(lm.history) - start_idx)


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

# --- ANSI colors ---

Y  = "\033[33m"  # yellow -> Warnings
C  = "\033[36m"  # cyan   -> Flows headers
G  = "\033[32m"  # green  -> Success
RD = "\033[31m"  # red    -> Failure
B  = "\033[1m"   # bold
R  = "\033[0m"   # reset

# --- AGENT INSTRUCTIONS, RULES AND FEEDBACK (Agent.md files) ---
#
# An Agent.md file looks like this (same layout as the part1 Agent.md files):
#
#   ---                          <- optional front matter (ignored)
#   name: TBGenerator
#   ---
#   # Role and Objective         <- instructions of the agent (docstring of its DSPy signature)
#   ...
#   # Mandatory Rules            <- rules given to the agent as an input field
#   ...
#   # Output Format              <- optional, appended to the rules
#   ...
#   # Feedback                   <- feedback messages sent back to the agent, one '## <key>' each
#   ## syntax_error
#   Fix the following testbench syntax errors/warnings:
#   {errors}
#
# {name} placeholders are filled in by this script. Unknown {placeholders} are left untouched.
# Inside the rules, {<agent>_rules} is replaced with the Mandatory Rules of that agent
# (e.g. {tb_generator_rules}), so the validators always check the current generator rules.
# HTML comments (<!-- ... -->) are ignored, so they can be used for notes.

def _fill(template: str, values: dict) -> str:
    """Replace {name} placeholders that exist in values. Leave every other brace untouched."""

    return re.sub(r"\{(\w+)\}", lambda m: str(values[m.group(1)]) if m.group(1) in values else m.group(0), template)

class AgentSpec:
    """Instructions, rules and feedback messages of one agent, read from its Agent.md file."""

    def __init__(self, name: str, path: Path, sections: dict, feedback: dict):
        self.name = name
        self.path = path
        self.sections = sections   # lower-case heading -> text
        self.feedback_messages = feedback  # feedback key -> template

    @property
    def instructions(self) -> str:
        """'# Role and Objective' section."""
        return self.sections.get("role and objective", "")

    @property
    def rules(self) -> str:
        """'# Mandatory Rules' section, followed by the optional '# Output Format' section."""
        parts = [self.sections.get("mandatory rules", ""), self.sections.get("output format", "")]
        return "\n\n".join(p for p in parts if p)

    def feedback(self, key: str, **values) -> str:
        """Return the '## <key>' feedback message with its {placeholders} filled in."""

        template = self.feedback_messages.get(key, "")
        if not template.strip():
            # No message written for this key (e.g. a minimal Agent.md): send a generic line
            # and the raw values (logs, issues, ...) so the flow still works.
            if key == "initial":
                return "Initial attempt."
            raw = [str(v) for v in values.values() if str(v).strip()]
            return "\n".join([f"Check failed: {key}"] + raw)
        return _fill(template, values)

def load_agent_md(name: str, path: Path) -> AgentSpec:
    """Parse an Agent.md file into an AgentSpec. A missing file gives an empty AgentSpec."""

    path = Path(path)
    if not path.exists():
        return AgentSpec(name, path, {}, {})

    text = path.read_text(encoding="utf-8")
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)              # Drop HTML comments
    text = re.sub(r"\A\s*---\n.*?\n---\s*\n", "", text, flags=re.DOTALL) # Drop front matter

    sections: dict = {}
    feedback: dict = {}
    section, sub = None, None
    buffer: list[str] = []
    in_fence = False

    def flush():
        content = "\n".join(buffer).strip("\n").rstrip()
        if section == "feedback":
            if sub is not None:
                feedback[sub] = content
        elif section is not None:
            sections[section] = content
        buffer.clear()

    for line in text.splitlines():
        # Headings inside ``` code blocks are not section headings
        if line.strip().startswith("```"):
            in_fence = not in_fence
        if not in_fence and re.match(r"^# \S", line):
            flush()
            section, sub = line[2:].strip().lower(), None
            continue
        if not in_fence and section == "feedback" and re.match(r"^## \S", line):
            flush()
            sub = line[3:].strip()
            continue
        buffer.append(line)
    flush()

    return AgentSpec(name, path, sections, feedback)

def load_agents() -> dict:
    """Load every Agent.md file and resolve the {<agent>_rules} references between them."""

    agents = {name: load_agent_md(name, path) for name, path in AGENT_MD_FILES.items()}

    # Raw rules of every agent, e.g. {tb_generator_rules}
    rule_refs = {f"{name}_rules": spec.sections.get("mandatory rules", "") for name, spec in agents.items()}

    # Values for the {placeholders} of the instructions
    instruction_values = {
        "config_mk_generator": {"max_iters": MAX_PHYSICAL_ITERS},
        "single_agent"       : {"max_iters": MAX_SINGLE_AGENT_ITERS},
    }

    for name, spec in agents.items():
        for key in ("mandatory rules", "output format"):
            if key in spec.sections:
                spec.sections[key] = _fill(spec.sections[key], rule_refs)
        if "role and objective" in spec.sections:
            spec.sections["role and objective"] = _fill(spec.sections["role and objective"], instruction_values.get(name, {}))

    return agents

AGENTS = load_agents()

# Feedback messages every agent needs (checked in check_environment)
REQUIRED_FEEDBACK = {
    "tb_generator"       : ["initial", "syntax_error", "validator_mismatch", "missing_pass_message"],
    "sdc_generator"      : ["initial", "structure_violation", "unfilled_placeholders"],
    "rtl_generator"      : ["initial", "timing_reminder", "rtl_simulation_failed", "synthesis_failed",
                            "post_synthesis_failed", "validator_issues", "timing_resynthesis"],
    "config_mk_generator": ["initial", "unfilled_placeholders", "orfs_failed", "score_report",
                            "severe_timing_warning", "optimize_further"],
    "single_agent"       : ["initial", "stage_failed", "tb_syntax_error", "tb_missing_pass_message",
                            "rtl_simulation_failed", "sdc_structure_violation", "sdc_unfilled_placeholders",
                            "synthesis_failed", "post_synthesis_failed", "config_unfilled_placeholders",
                            "orfs_failed", "timing_resynthesis", "score_report", "severe_timing_warning",
                            "optimize_further"],
}

# --- SIGNATURES ---

class TBGenerator(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["tb_generator"].instructions
    yaml_spec        = dspy.InputField(desc="Hardware specification in YAML format")
    module_signature = dspy.InputField(desc="DUT (Device Under Test) signature")
    simulation_rules = dspy.InputField(desc="MANDATORY simulation rules")
    previous_code    = dspy.InputField(desc="Testbench Verilog code from the last iteration (if any)")
    feedback         = dspy.InputField(desc="Errors from Icarus Verilog or logic mismatches")
    testbench_code   = dspy.OutputField(desc="Complete Verilog-2001 testbench, no explanation, no markdown, no timescale")

class TBValidator(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["tb_validator"].instructions
    yaml_spec        = dspy.InputField(desc="Hardware specification in YAML format")
    testbench_code   = dspy.InputField(desc="Testbench code to be validated")
    validation_rules = dspy.InputField(desc="Mandatory validation checklist and TB generation rules")
    validation       = dspy.OutputField(desc=("MUST start with 'Match' or 'Mismatch'. "
                                              "If 'Mismatch', provide a concise list ONLY of the missing edge cases, "
                                              "logical errors, or rule violations found. If 'Match', leave the list empty."))

class SDCGenerator(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["sdc_generator"].instructions
    yaml_spec    = dspy.InputField(desc="Hardware functional requirements in YAML format")
    sdc_rules    = dspy.InputField(desc="MANDATORY SDC generation rules")
    sdc_template = dspy.InputField(desc="Available SDC templates to fill in (Sequential vs Combinational)")
    previous_sdc = dspy.InputField(desc="SDC file from the last iteration (if any)")
    feedback     = dspy.InputField(desc="OpenROAD Flow Scripts errors from previous SDC attempts, or 'Initial attempt'.")
    sdc_content  = dspy.OutputField(desc="Complete SDC file content, no markdown, no explanation")

class RTLGenerator(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["rtl_generator"].instructions
    yaml_spec        = dspy.InputField(desc="Hardware functional requirements in YAML format")
    module_signature = dspy.InputField(desc="Exact Verilog module port declaration")
    rtl_rules        = dspy.InputField(desc="MANDATORY hardware rules")
    previous_code    = dspy.InputField(desc="Verilog code from the last iteration (if any)")
    feedback         = dspy.InputField(desc="Simulation/Synthesis error logs to fix")
    rtl_code         = dspy.OutputField(desc="Complete SYNTHESIZABLE Verilog-2001 code, no explanation, no markdown")

class RTLValidator(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["rtl_validator"].instructions
    yaml_spec        = dspy.InputField(desc="Hardware functional requirements in YAML format.")
    module_signature = dspy.InputField(desc="Exact Verilog module port declaration.")
    rtl_code         = dspy.InputField(desc="RTL code to be audited.")
    validation_rules = dspy.InputField(desc="Mandatory validation checklist and RTL generation rules.")
    feedback         = dspy.InputField(desc="Simulation/synthesis error logs from the evaluator.")
    audit_report     = dspy.OutputField(desc=("MUST start with exactly 'Match' or 'Mismatch' on the first line. "
                                              "If 'Mismatch', provide a concise numbered list of concrete fixes needed. "
                                              "Format each item as: '<issue description> -> FIX: <exact corrective action>. "
                                              "If 'Match', leave the list empty. Be specific and actionable."))

class ConfigMKGenerator(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["config_mk_generator"].instructions
    iteration_count = dspy.InputField(desc="Current iteration number and maximum iterations")
    yaml_spec       = dspy.InputField(desc="Hardware functional requirements in YAML format")
    config_rules    = dspy.InputField(desc="MANDATORY config.mk generation rules")
    rtl_code        = dspy.InputField(desc="Synthesized Verilog-2001 RTL")
    config_template = dspy.InputField(desc="config.mk template to fill in")
    previous_config = dspy.InputField(desc="config.mk file from the last iteration (if any)")
    feedback        = dspy.InputField(desc="Errors or Performance Metrics from previous attempts.")
    config_content  = dspy.OutputField(desc="Complete config.mk file content, no markdown, no explanation")

# --- MODULES (The Execution Flows) ---

class TBFlow(dspy.Module):
    def __init__(self):
        super().__init__()
        self.tb_generator = dspy.ChainOfThought(TBGenerator)
        self.tb_validator = dspy.ChainOfThought(TBValidator)
        self.feedback = None
        self.previous_tb = None

    def _clean_tb(self, raw: str) -> str:
        """Extract and sanitize TB from raw LM output."""
        
        # Strip any opening fence line (e.g. ```verilog, ```)
        raw = re.sub(r"^```\w*\n", "", raw.strip())
        # Strip any closing fence line
        raw = re.sub(r"\n```$", "", raw.strip())

        # If no module found after stripping fences, try to find module...endmodule directly
        m = re.search(r"(module\s+\w+.*?endmodule)", raw, re.DOTALL)
        code = m.group(1).strip() if m else raw.strip()

        # Remove stray backticks before comments (` // comment → // comment)
        # Valid Verilog directives start with `define `include `timescale etc.
        code = re.sub(r"`(?!(define|include|timescale|ifdef|ifndef|endif|else|undef)\b)", "", code)

        # Remove existing timescale lines (if any)
        # This matches `timescale followed by anything until the end of that line
        code = re.sub(r"`timescale\s+.*?\n", "", code).strip()

        # Manually add timescale and return the clean code
        return "`timescale 1ns/1ps\n\n" + code

    def forward(self, yaml_spec: str, module_signature: str, module_id: str) -> tuple[Path, str]:
        global TB_GEN_ITER

        # Check for cross-flow feedback before starting the iteration loop
        if self.feedback:
            feedback = self.feedback
            self.feedback = None  # Consume the feedback
        else:
            feedback = AGENTS["tb_generator"].feedback("initial")

        if self.previous_tb:
            previous_tb = self.previous_tb
            self.previous_tb = None  # Consume the TB
        else:
            previous_tb = "None (First Attempt)"

        # Start iterative process from the specifed starting iteration.
        while TB_GEN_ITER <= MAX_TB_GEN_ITERS:
            # Use the current counter value for 
            # logs/files, then increment immediately
            i = TB_GEN_ITER
            TB_GEN_ITER += 1

            print(f"\n{C}[TB GEN] Iteration {i}/{MAX_TB_GEN_ITERS}...{R}")
            
            # Generate the TB
            with metered("tb_generator", f"TB generation, iteration {i}", TB_GENERATOR_LM):
                result = self.tb_generator(
                    yaml_spec=yaml_spec, 
                    module_signature=module_signature, 
                    simulation_rules=AGENTS["tb_generator"].rules, 
                    previous_code=previous_tb, 
                    feedback=feedback
                )

            # Print lm input prompt, reasoning and output
            TB_GENERATOR_LM.inspect_history(n=1)
            
            # Save TB
            final_tb =  self._clean_tb(raw=result.testbench_code)
            previous_tb = final_tb
            save_file(TB_GEN_DIR, f"{module_id}_ITER_{i}_tb.v", final_tb)
            tb_path = save_file(TB_GEN_DIR, f"{module_id}_tb.v", final_tb)
            
            # Create the Stub as a temporary file
            with tempfile.NamedTemporaryFile(suffix=".v", mode="w", delete=True) as tmp_stub:
                stub_content = f"`timescale 1ns/1ps\n{module_signature}\nendmodule"
                tmp_stub.write(stub_content)
                tmp_stub.flush() # Ensure content is written to disk before iverilog runs

                # Syntax check with Icarus Verilog
                # tmp_stub.name provides the absolute path to the temp file
                check_cmd = ["iverilog", "-Wall", "-g2005", "-o", "tb_check.out", tb_path, tmp_stub.name]
                process = subprocess.run(check_cmd, capture_output=True, text=True)
                full_output = process.stdout + process.stderr

                # Cleanup the compiled output if it exists
                if Path("tb_check.out").exists():
                    Path("tb_check.out").unlink()

                print("\nCompiling testbench with Icarus Iverilog...")

                # Check for hard failure or warnings
                if process.returncode != 0 or full_output:
                    if process.returncode != 0:
                        print("Compilation failed.\n")
                    else:
                        print("Compilation succeeded with warnings.\n")
                    print(full_output)
                    print(f"{RD}❌ Testbench syntax error/warning. Feeding back errors to agent...{R}")
                    feedback = AGENTS["tb_generator"].feedback("syntax_error", errors=full_output)

                # Check if PASS string exists
                elif "PASS" in final_tb:
                    print("Compilation succeeded.")
                    print(f"\n{G}{B}✅ Success! Testbench syntax verified after {i} iterations.{R}")

                    if TB_VALIDATOR_LM is None:
                        print("\n[TB VALIDATOR] Skipped (TB Validator set to None)")
                        return tb_path, "PASS"

                    print(f"\n{C}[TB VALIDATE] Checking logic and protocol...{R}")
                    with metered("tb_validator", f"TB validation, iteration {i}", TB_VALIDATOR_LM):
                        result = self.tb_validator(
                            yaml_spec=yaml_spec, 
                            testbench_code=final_tb, 
                            validation_rules=AGENTS["tb_validator"].rules
                        )

                    # Print lm input prompt, reasoning and output
                    TB_VALIDATOR_LM.inspect_history(n=1)

                    if "Mismatch" in result.validation:
                        print(f"{RD}❌ Testbench logic mismatch found by Validator. Feeding back errors to Generator...{R}")
                        feedback = AGENTS["tb_generator"].feedback("validator_mismatch", issues=result.validation)
                    else:
                        print(f"{G}{B}✅ Success! Testbench validated after {i} iterations.{R}")
                        return tb_path, "PASS"
                
                else:
                    print("Compilation succeeded.")
                    print(f"\n{RD}❌ Testbench missing correct PASS message. Feeding back errors to agent...{R}")
                    feedback = AGENTS["tb_generator"].feedback("missing_pass_message")

        print(f"\n{RD}{B}Reached max iterations ({MAX_TB_GEN_ITERS}) without passing TB generation flow.{R}")

        return tb_path, "Fail"

class SDCFlow(dspy.Module):
    def __init__(self):
        super().__init__()
        self.sdc_generator = dspy.ChainOfThought(SDCGenerator)
        self.feedback = None
        self.previous_sdc = None

    def _clean_sdc(self, raw: str) -> str:
        """Extract and sanitize SDC from raw LM output."""

        # Strip any opening fence line (e.g. ```sdc, ```tcl, ```)
        raw = re.sub(r"^```\w*\n", "", raw.strip())
        # Strip any closing fence line
        raw = re.sub(r"\n```$", "", raw.strip())

        return raw.strip()

    def _verify_sdc_structure(self, template: str, generated: str) -> list[str]:
        """
        Compare the generated SDC against the template.
        Return a list of error messages for any missing, illegally 
        modified, or extra lines not present in the template.
        """

        # Remove placeholders from template to get the "static" parts
        static_template = re.sub(r"<[^>]+>", "", template).splitlines()
        static_template_lines = [l.strip() for l in static_template if l.strip()]

        generated_lines = [l.strip() for l in generated.splitlines() if l.strip()]

        issues = []

        # Missing or modified template lines
        for t_line in static_template_lines:
            if not any(t_line in g_line for g_line in generated_lines):
                issues.append(f"\nMissing or modified template line: '{t_line}'")

        # Extra lines not derived from the template.
        # Build a set of all non-placeholder template tokens for reverse lookup.
        for g_line in generated_lines:
            # Check if this generated line is "covered" by any template line.
            # A line is covered if it matches a static template line,
            # or if it corresponds to a placeholder-containing template line.
            covered = False

            for t_line in static_template_lines:
                if t_line in g_line or g_line in t_line:
                    covered = True
                    break

            # Also allow lines that correspond to placeholder lines in the original template
            if not covered:
                for raw_t_line in template.splitlines():
                    raw_stripped = raw_t_line.strip()
                    if not raw_stripped:
                        continue

                    # If the template line had a placeholder, it's a "variable" line.
                    # Accept the generated version loosely by checking the non-placeholder prefix.
                    static_prefix = re.split(r"<[^>]+>", raw_stripped)[0].strip()
                    if static_prefix and g_line.startswith(static_prefix):
                        covered = True
                        break

            if not covered:
                issues.append(f"\nExtra line not in template: '{g_line}'")

        return issues

    def forward(self, yaml_spec: str, module_id: str, orfs_design_path: Path) -> tuple[Path, str]:
        global SDC_GEN_ITER

        # Check for cross-flow feedback before starting the iteration loop
        if self.feedback:
            feedback = self.feedback
            self.feedback = None  # Consume the feedback
        else:
            feedback = AGENTS["sdc_generator"].feedback("initial")

        if self.previous_sdc:
            previous_sdc = self.previous_sdc
            self.previous_sdc = None  # Consume the SDC
        else:
            previous_sdc = "None (First Attempt)"

        # Load SDC templates
        with open(SDC_SEQ_TEMPLATE, "r") as f:
            sdc_seq_template = f.read()

        with open(SDC_COMB_TEMPLATE, "r") as f:
            sdc_comb_template = f.read()

        # Replace MODULE_NAME with the actual module name provided in the spec
        sdc_seq_template  = sdc_seq_template.replace("<MODULE_NAME>", module_id)
        sdc_comb_template = sdc_comb_template.replace("<MODULE_NAME>", module_id)

        # Pass BOTH templates to the agent
        template_options = f"OPTION A (Sequential):\n{sdc_seq_template}\n\nOPTION B (Combinational):\n{sdc_comb_template}"

        # Start iterative process from the specifed starting iteration.
        while SDC_GEN_ITER <= MAX_SDC_GEN_ITERS:
            # Use the current counter value for 
            # logs/files, then increment immediately
            i = SDC_GEN_ITER
            SDC_GEN_ITER += 1

            print(f"\n{C}[SDC GEN] Iteration {i}/{MAX_SDC_GEN_ITERS}...{R}")

            # Generate the SDC with current feedback
            with metered("sdc_generator", f"SDC generation, iteration {i}", SDC_GENERATOR_LM):
                result = self.sdc_generator(
                    yaml_spec=yaml_spec, 
                    sdc_rules=AGENTS["sdc_generator"].rules, 
                    sdc_template=template_options, 
                    previous_sdc=previous_sdc, 
                    feedback=feedback
                )

            # Print lm input prompt, reasoning and output
            SDC_GENERATOR_LM.inspect_history(n=1)

            # Clean the SDC
            final_sdc = self._clean_sdc(raw=result.sdc_content)
            previous_sdc = final_sdc

            # Save the SDC
            save_file(orfs_design_path, "constraint.sdc", final_sdc)
            save_file(SDC_GEN_DIR, f"{module_id}_ITER_{i}.sdc", final_sdc)
            sdc_path = save_file(SDC_GEN_DIR, f"{module_id}.sdc", final_sdc)

            # Determine which template to verify against by looking at the agent's output
            if "create_clock" in final_sdc:
                chosen_template = sdc_seq_template
            else:
                chosen_template = sdc_comb_template

            # Check if agent changed sdc structure
            structure_issues = self._verify_sdc_structure(chosen_template, final_sdc)
            if structure_issues:
                print(f"\n{RD}❌ SDC Structure Violation. Feeding back errors to agent...{R}")
                print(" ".join(structure_issues))
                feedback = AGENTS["sdc_generator"].feedback("structure_violation", issues=" ".join(structure_issues))
                continue

            # Check if agent filled in all template placeholders
            placeholders = re.findall(r"<[A-Z_]+>", final_sdc)
            if placeholders:
                print(f"\n{RD}❌ SDC generation failed due to unfilled placeholders: {placeholders}. Feeding back errors to agent...{R}")
                feedback = AGENTS["sdc_generator"].feedback("unfilled_placeholders", placeholders=placeholders)
                continue

            print(f"\n{G}{B}✅ Success! SDC successfully generated after {i} iterations.{R}")
            return sdc_path, "Success"

        print(f"\n{RD}{B}Reached max iterations ({MAX_SDC_GEN_ITERS}) without creating a correct sdc file.{R}")
        return sdc_path, "Fail"

class RTLFlow(dspy.Module):
    def __init__(self):
        super().__init__()
        self.rtl_generator = dspy.ChainOfThought(RTLGenerator)
        self.validator = dspy.Predict(RTLValidator)
        self.feedback = None
        self.timing_retry = False  # True when self.feedback comes from a failed timing closure
        self.previous_rtl = None

    def _log(self, msg: str):
        """Print a message of the RTL flow."""

        print(msg)

    def _clean_rtl(self, raw: str) -> str:
        """Extract and sanitize Verilog from raw LM output."""
        
        # Strip any opening fence line (e.g. ```verilog, ```)
        raw = re.sub(r"^```\w*\n", "", raw.strip())
        # Strip any closing fence line
        raw = re.sub(r"\n```$", "", raw.strip())

        # If no module found after stripping fences, try to find module...endmodule directly
        m = re.search(r"(module\s+\w+.*?endmodule)", raw, re.DOTALL)
        code = m.group(1).strip() if m else raw.strip()

        # Remove stray backticks before comments (` // comment → // comment)
        # Valid Verilog directives start with `define `include `timescale etc.
        code = re.sub(r"`(?!(define|include|timescale|ifdef|ifndef|endif|else|undef)\b)", "", code)

        # Fix module names starting with a digit - invalid Verilog identifier.
        # e.g. "module 8bit_counter" -> "module top_8bit_counter"
        code = re.sub(r"\bmodule\s+(\d\S*)", lambda m: f"module top_{m.group(1)}", code)

        # Fix reg signals driven by assign. Verilog rule: assign drives wire, not reg.
        # Find every signal name on the left-hand side of an assign statement,
        # then if that signal is declared as reg (or output reg), flip it to wire.
        assign_targets = re.findall(r"\bassign\s+(\w+)", code)
        for name in assign_targets:
            # "reg [n:0] name" or "reg name" -> "wire [n:0] name" / "wire name"
            code = re.sub(
                rf"\breg\b(\s+(?:\[[\w\s:]+\]\s+)?){re.escape(name)}\b",
                rf"wire\1{name}", code
            )
            # "output reg [n:0] name" -> "output wire [n:0] name"
            code = re.sub(
                rf"\boutput\s+reg\b(\s+(?:\[[\w\s:]+\]\s+)?){re.escape(name)}\b",
                rf"output wire\1{name}", code
            )

        # Remove existing timescale lines (if any)
        # This matches `timescale followed by anything until the end of that line
        code = re.sub(r"`timescale\s+.*?\n", "", code).strip()

        # Manually add timescale and return the clean code
        return "`timescale 1ns/1ps\n\n" + code

    def _run_simulation(self, testbench_path: Path, design_path: Path, mode: str = "rtl", timeout: int = 10) -> str:
        """
        Run RTL or netlist simulation.
        Args:
            testbench_path: Path to the generated or provided testbench.
            design_path: Path to the RTL (.v) or Netlist (.v) file.
            mode: 'rtl' for behavioral simulation, 'post_synth' for gate-level.
            timeout: Maximum seconds allowed for the simulation execution step.
        """

        logs = []
        output_exe = f"sim_{mode}.out"
        
        self._log(f"\n--- RUNNING {mode.upper()} SIMULATION ---")

        # Construct compilation command
        if mode == "rtl":
            # Standard RTL simulation
            compile_cmd = ["iverilog", "-Wall", "-g2005", "-o", output_exe, str(design_path), str(testbench_path)]
        else:
            # Post-synthesis requires the PDK library for gate definitions
            pdk_cells = sorted(PDK_RTL_PATH.glob("*.v"))
            compile_cmd = ["iverilog", "-Wall", "-Wno-timescale", "-g2005", "-o", output_exe, 
                           *[str(p) for p in pdk_cells], str(design_path), str(testbench_path)]

        print(f"Compiling: {' '.join(compile_cmd)}")
        logs.append(f"Compiling {mode}...\n")

        # Execute compilation
        comp_proc = subprocess.run(compile_cmd, capture_output=True, text=True)
        full_output = comp_proc.stdout + comp_proc.stderr

        if comp_proc.returncode != 0:
            error_msg = f"{mode.upper()} Compilation failed:\n{full_output}"
            print(error_msg)
            logs.append(f"{error_msg}\n")
            return "".join(logs)
        elif full_output.strip():
            warning_msg = f"Compilation succeeded with warnings:\n{full_output}"
            print(warning_msg)
            logs.append(f"{warning_msg}\n")
        else:
            print("Compilation succeeded.\n")
            logs.append("Compilation succeeded.\n")

        # Execute simulation (vvp)
        print(f"Executing {mode.upper()} simulation (vvp)...")
        logs.append(f"Executing {mode.upper()} simulation (vvp)...\n")
        
        sim_proc = subprocess.Popen(
            ["vvp", output_exe],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, # This merges the streams in order
            text=True,
            bufsize=1                 # Line buffering for real-time flow
        )

        # Reader thread: streams output to terminal and logs without blocking main thread
        def _reader(stream, logs):
            for line in iter(stream.readline, ""):
                print(line, end="", flush=True)
                logs.append(line)
            stream.close()

        reader_thread = threading.Thread(target=_reader, args=(sim_proc.stdout, logs))
        reader_thread.daemon = True
        reader_thread.start()
        reader_thread.join(timeout=timeout)

        if reader_thread.is_alive():
            # Simulation hung, kill it and wait for the reader to finish
            sim_proc.kill()
            sim_proc.wait()
            reader_thread.join()
            timeout_msg = f"Simulation timed out after {timeout} seconds.\n"
            print(timeout_msg)
            logs.append(timeout_msg)
        else:
            sim_proc.wait()

        # Cleanup
        if Path(output_exe).exists():
            Path(output_exe).unlink()

        return "".join(logs)
    
    def _run_yosys(self, orfs_design_path: Path) -> tuple[str, int]:
        """Run Yosys synthesis from OpenROAD."""

        print(f"\n--- RUNNING YOSYS SYNTHESIS ---")

        # Directory where the ORFS Makefile is located
        orfs_makefile_dir = Path(ORFS_DIR) / "flow"

        # Run ORFS for synthesis
        orfs_synth_proc = subprocess.run(
            ["make", "synth", f"DESIGN_CONFIG={orfs_design_path}/config.mk"],
            cwd=orfs_makefile_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,  # This merges the streams in order
            text=True,
        )

        return orfs_synth_proc.stdout, orfs_synth_proc.returncode

    def _extract_yosys_issues(self, yosys_log: str) -> str:
        """Extract issues from yosys log about non-synthesizable RTL."""
        
        issues = []

        # Check for "Zero Cell" optimization failure
        if re.search(r"Number of cells:\s+0\b", yosys_log):
            issues.append("--- CRITICAL SYNTHESIS ERROR: ZERO CELLS INFERRED ---")
            issues.append("ERROR: Yosys deleted your entire design (0 cells).")
            issues.append("CAUSE: Violation of RULE 1 (Multi-Driver Conflict).")
            issues.append("HINT: You likely assigned the SAME signal in different 'always' blocks or 'assign' statements.")

        # Capture Latches
        latch_matches = re.findall(r"Latch inferred for signal.*", yosys_log)
        if latch_matches:
            issues.append("--- INFERRED LATCHES DETECTED ---")
            issues.extend([m.strip() for m in latch_matches])

        # Capture Multi-driver conflicts
        driver_matches = re.findall(r"Warning: Driver-driver conflict.*", yosys_log)
        if driver_matches:
            issues.append("\n--- MULTI-DRIVER CONFLICTS ---")
            issues.extend([m.strip() for m in driver_matches])

        # Capture Non-Synthesizable Constructs
        synth_matches = re.findall(r"Warning: Ignoring call.*", yosys_log)
        if synth_matches:
            issues.append("\n--- NON-SYNTHESIZABLE CONSTRUCTS ---")
            issues.extend([m.strip() for m in synth_matches])

        # Capture Syntax/Parsing Errors
        syntax_errors = re.findall(r".*ERROR:.*", yosys_log)
        if syntax_errors:
            issues.append("\n--- FATAL SYNTAX/PARSING ERRORS ---")
            issues.extend([m.strip() for m in syntax_errors])

        return "\n".join(issues) if issues else ""

    def _run_validator(self, yaml_spec: str, module_signature: str, rtl_code: str, feedback: str) -> str:
        """Run the RTL validator and return updated feedback."""

        if SKIP_RTL_VALIDATOR or RTL_VALIDATOR_LM is None:
            print("\n[RTL VALIDATOR] Skipped")
            return feedback

        self._log("\n[RTL VALIDATOR] Auditing RTL against spec and rules...")
        with metered("rtl_validator", f"RTL validation, after RTL iteration {max(RTL_GEN_ITER - 1, 1)}", RTL_VALIDATOR_LM):
            val_res = self.validator(
                yaml_spec=yaml_spec,
                module_signature=module_signature,
                rtl_code=rtl_code,
                validation_rules=AGENTS["rtl_validator"].rules,
                feedback=feedback,
            )

        self._log("\n--- RTL VALIDATOR REPORT ---")
        self._log(val_res.audit_report)
        self._log("=" * 30 + "\n")

        # Append validator findings to feedback if mismatch found
        if "MISMATCH" in val_res.audit_report.upper().splitlines()[0]:
            feedback += "\n" + AGENTS["rtl_generator"].feedback("validator_issues", report=val_res.audit_report)

        return feedback

    def forward(self, yaml_spec: str, module_signature: str, module_id: str, tb_path: Path, orfs_design_path: Path, orfs_rtl_src_dir: Path, rtl_gen_dir: Path = None) -> tuple[Path, str]:
        global RTL_GEN_ITER

        # Make a local copy of the iterator for the Optimize mode, 
        # in case multiple RTLFlows are spawned
        if RTL_GEN_DSPY_MODE == "Optimize":
            # Reset for each call during optimization
            rtl_iter = 1
        else:
            rtl_iter = RTL_GEN_ITER

        rtl_gen_dir = rtl_gen_dir or RTL_GEN_DIR

        # Check for cross-flow feedback before starting the iteration loop
        timing_feedback = ""
        if self.feedback:
            feedback = self.feedback
            
            # Check for timing failure from previous attempts
            if self.timing_retry:
                timing_feedback = AGENTS["rtl_generator"].feedback("timing_reminder") + "\n\n"
                # Actual feedback will be concatenated after timing feedback

                if self.previous_rtl:
                    # Run validator on the previous RTL before entering 
                    # the RTL generation loop if timing issue occured
                    feedback = self._run_validator(
                        yaml_spec=yaml_spec,
                        module_signature=module_signature,
                        rtl_code=self.previous_rtl,
                        feedback=timing_feedback + feedback,
                    )

            self.feedback = None  # Consume the feedback
            self.timing_retry = False
        else:
            feedback = AGENTS["rtl_generator"].feedback("initial")

        if self.previous_rtl:
            previous_rtl = self.previous_rtl
            self.previous_rtl = None  # Consume the RTL
        else:
            previous_rtl = "None (First Attempt)"

        # Locate not yet created netlist file
        netlist_path = Path(ORFS_DIR) / "flow" / "results" / ORFS_PLATFORM / module_id / "base" / "1_2_yosys.v"

        # Start iterative process from the specifed starting iteration.
        while rtl_iter <= MAX_RTL_GEN_ITERS:
            # Use the current counter value for
            # logs/files, then increment immediately
            i = rtl_iter
            rtl_iter += 1
            RTL_GEN_ITER += 1

            self._log(f"\n{C}[RTL GEN] Iteration {i}/{MAX_RTL_GEN_ITERS}...{R}")

            if RTL_GEN_DSPY_MODE == "Optimize":

                # Run the RTL Generator using the dspy.context.lm (set by MIPROv2)
                current_lm = dspy.settings.lm
                with metered("rtl_generator", f"RTL generation (MIPROv2), iteration {i}", current_lm, set_context=False):
                    result = self.rtl_generator(
                        yaml_spec=yaml_spec, 
                        module_signature=module_signature, 
                        rtl_rules=AGENTS["rtl_generator"].rules,
                        previous_code=previous_rtl,
                        feedback=feedback
                    )

                # Print lm input prompt, reasoning and output
                current_lm.inspect_history(n=1)

            else:
                # Run the RTL Generator using the RTL_GENERATOR_LM
                with metered("rtl_generator", f"RTL generation, iteration {i}", RTL_GENERATOR_LM):
                    result = self.rtl_generator(
                        yaml_spec=yaml_spec, 
                        module_signature=module_signature, 
                        rtl_rules=AGENTS["rtl_generator"].rules,
                        previous_code=previous_rtl,
                        feedback=feedback
                    )

                # Print lm input prompt, reasoning and output
                RTL_GENERATOR_LM.inspect_history(n=1)

            final_rtl = self._clean_rtl(raw=result.rtl_code)
            previous_rtl = final_rtl

            # Save RTL into ORFS project and RTL generatation directory
            save_file(orfs_rtl_src_dir, f"{module_id}.v", final_rtl)
            save_file(rtl_gen_dir, f"{module_id}_ITER_{i}.v", final_rtl)
            rtl_path = save_file(rtl_gen_dir, f"{module_id}.v", final_rtl)

            # Run RTL simulation
            full_log = self._run_simulation(testbench_path=tb_path, design_path=rtl_path, mode="rtl")

            # Check RTL simulation success criteria
            if "PASS" in full_log.upper() and "FAIL" not in full_log.upper():
                self._log(f"\n{G}{B}✅ Success! RTL verified after {i} iterations.{R}")
                self._log(f"\n🚀 Starting synthesis for: {module_id}...")

                # Run synthesis and capture log and issues
                yosys_log, yosys_return_code = self._run_yosys(orfs_design_path=orfs_design_path)
                save_file(rtl_gen_dir, f"{module_id}_yosys_ITER_{i}.log", yosys_log)
                synthesis_issues = self._extract_yosys_issues(yosys_log=yosys_log)

                # Check Yosys success criteria
                if yosys_return_code != 0 or synthesis_issues:
                    self._log(f"{RD}❌ Synthesis issues found. Feeding back errors to agent...{R}")
                    feedback = timing_feedback
                    issues_text = synthesis_issues if synthesis_issues else "--- ISSUES IDENTIFIED ---\nFatal Syntax Error in RTL."

                    feedback += AGENTS["rtl_generator"].feedback("synthesis_failed", issues=issues_text)

                else:
                    self._log(f"{G}{B}✅ Success! Netlist saved at: {netlist_path}{R}")

                    # Check if verification mode is set to perform verification only on RTL
                    if VERIFICATION_MODE.upper() == "RTL":
                        self._log(f"\n{G}{B}✅ Success! Verification completed for RTL only (Post-synthesis verification skipped).{R}")
                        return dspy.Prediction(rtl_path=rtl_path, status="Success")

                    # Run post-synthesis simulation
                    post_log = self._run_simulation(testbench_path=tb_path, design_path=netlist_path, mode="post_synth")

                    # Check post synthesis simulation success criteria
                    if "PASS" in post_log.upper() and "FAIL" not in post_log.upper():
                        self._log(f"\n{G}{B}✅ Success! Post-synthesis simulation passed after {i} iterations.{R}")
                        # Return as prediction for the MiPROv2 optimization
                        return dspy.Prediction(rtl_path=rtl_path, status="Success")
                    else:
                        self._log(f"\n{RD}❌ Post-synthesis simulation failed. Feeding back errors to agent...{R}")
                        feedback = timing_feedback
                        feedback += AGENTS["rtl_generator"].feedback("post_synthesis_failed", log=post_log)

            else:
                # Update feedback for the next RTL generation iteration
                self._log(f"\n{RD}❌ RTL simulation failed. Feeding back errors to agent...{R}")
                feedback = timing_feedback
                feedback += AGENTS["rtl_generator"].feedback("rtl_simulation_failed", log=full_log)

            # RTL VALIDATOR - LLM (runs after every failed iteration)
            feedback = self._run_validator(
                yaml_spec=yaml_spec,
                module_signature=module_signature,
                rtl_code=final_rtl,
                feedback=feedback,
            )

        self._log(f"\n{RD}{B}Reached max iterations ({MAX_RTL_GEN_ITERS}) without passing RTL generation flow.{R}")
        # Return as prediction for the MiPROv2 optimization
        return dspy.Prediction(rtl_path=rtl_path, status="Fail")    

class PhysicalFlow(dspy.Module):
    def __init__(self):
        super().__init__()
        self.config_generator = dspy.ChainOfThought(ConfigMKGenerator)
        self.feedback = None
        self.previous_config = None

    def _clean_config(self, raw: str) -> str:
        """Extract and sanitize config.mk from raw LM output."""

        # Strip any opening fence line (e.g. ```makefile, ```mk, ```)
        raw = re.sub(r"^```\w*\n", "", raw.strip())
        # Strip any closing fence line
        raw = re.sub(r"\n```$", "", raw.strip())

        return raw.strip()
    
    def _run_openroad_flow(self, orfs_design_path: Path) -> tuple[str, int]:
        """Run OpenROAD flow. """

        # Directory where the ORFS Makefile is located
        orfs_makefile_dir = Path(ORFS_DIR) / "flow"
        start_time = time.time()

        print("\nCleaning previous ORFS results...")
        
        # Run make clean_all
        subprocess.run(
            ["make", "clean_all", f"DESIGN_CONFIG={orfs_design_path}/config.mk"], 
            cwd=orfs_makefile_dir, 
            stderr=subprocess.DEVNULL, # Ignore stderr clean logs
            stdout=subprocess.DEVNULL  # Ignore stdout clean logs
        )

        print(f"\n--- RUNNING OPENROAD FLOW ---")
        
        # Run ORFS
        orfs_proc = subprocess.run(
            ["make", f"DESIGN_CONFIG={orfs_design_path}/config.mk"],
            cwd=orfs_makefile_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,  # This merges the streams in order
            text=True,
        )

        print(f"⏱️  OpenROAD flow execution time: {time.time() - start_time:.2f} seconds")
        return orfs_proc.stdout, orfs_proc.returncode
    
    def _extract_orfs_issues(self, orfs_log: str, context_lines: int = 3) -> str:
        """Extract relevant issues from ORFS log with context lines around each error."""

        lines = orfs_log.splitlines()
        issues = []
        added_indices = set()   # To handle duplicate lines

        # Find all lines containing "error" (case-insensitive) ignoring makefile errors
        error_indices = [
            i for i, line in enumerate(lines)
            if re.search(r"error", line, re.IGNORECASE) and "***" not in line
        ]

        if error_indices:
            issues.append("--- LOGGED ERRORS ---")
            
            for idx in error_indices:
                # Capture +- context_lines arround error    
                start = max(0, idx - context_lines)
                end = min(len(lines) - 1, idx + context_lines)

                for i in range(start, end + 1):
                    # Add the context lines only if they
                    # are not makefile errors or duplicates
                    if i not in added_indices and "***" not in lines[i]:
                        issues.append(lines[i].strip())
                        added_indices.add(i)
        else:
            # Fall back to Makefile fatal errors ('***' lines) with context
            fatal_indices = [
                i for i, line in enumerate(lines)
                if "***" in line
            ]

            if fatal_indices:
                issues.append("--- MAKEFILE SYNTAX & FATAL ERRORS ---")

                for idx in fatal_indices:
                    # Cpature +- context_lines arround error    
                    start = max(0, idx - context_lines)
                    end = min(len(lines) - 1, idx + context_lines)
                    
                    for i in range(start, end + 1):
                        if i not in added_indices:
                            issues.append(lines[i].strip())
                            added_indices.add(i)

        # If any issues were found, also capture the design area line (up to u^2)
        if issues:
            for line in lines:
                match = re.search(r"(Design area\s+[\d\.]+\s+u\^2)", line, re.IGNORECASE)
                if match:
                    issues.append("\n--- DESIGN AREA INFO ---")
                    issues.append(match.group(1))
                    break

        return "\n".join(issues) if issues else ""

    def _run_openroad_evaluation(self, orfs_results_dir: Path) -> tuple[str, int]:
        """Run evaluate_openroad.py on the generated OpenROAD .odb and .sdc files."""

        problem_number = re.search(r'p(\d+)', DESIGN).group(1)

        # Construct evaluation command using -u flag 
        # to force unbuffered output from the child script
        eval_cmd = [
            "python3",
            "-u",
            str(EVALUATION_DIR / "evaluate_openroad.py"),
            "--odb",
            str(orfs_results_dir / "6_final.odb"),
            "--sdc",
            str(orfs_results_dir / "6_final.sdc"),
            "--flow_root",
            str(ORFS_DIR),
            "--problem",
            problem_number,
        ]

        print(f"\n--- RUNNING OPENROAD EVALUATION ---")
        print(" ".join(eval_cmd))

        process = subprocess.Popen(
            eval_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, # This merges the streams in order
            text=True,
            bufsize=1,                # Line buffering for real-time flow
        )

        logs = []
        if process.stdout:
            for line in iter(process.stdout.readline, ""):
                # Print to terminal immediately
                print(line, end="", flush=True)
                # Append to the log
                logs.append(line)
            process.stdout.close()

        process.wait()
        print()

        return "".join(logs), process.returncode

    def _copy_openroad_results(self, orfs_results_dir: Path, rtl_path: Path) -> Path:
        """Copy the OpenROAD results and RTL into the local solutions folder."""
        
        print(f"\n--- COPPING RESULTS TO SOLUTIONS DIRECTORY ---")

        # Copy final OpenROAD results
        for filename in ["6_final.odb", "6_final.sdc"]:            
            src = orfs_results_dir / filename
            if not src.exists():
                raise FileNotFoundError(f"OpenROAD result file not found: {src}")           
            dest = SOLUTIONS_DIR / filename
            shutil.copy(src, dest)
            print(f"✨ Copied {src} -> {dest}")

        # Copy final RTL
        rtl_dest = SOLUTIONS_DIR / Path(rtl_path).name
        shutil.copy(rtl_path, rtl_dest)
        print(f"✨ Copied {rtl_path} -> {rtl_dest}")

    def forward(self, yaml_spec: str, module_id: str, rtl_path: Path, orfs_design_path: Path, orfs_results_dir: Path) -> tuple[Path, str, str]:
        global PHYSICAL_ITER
        
        # Check for cross-flow feedback before starting the iteration loop       
        if self.feedback:
            feedback = self.feedback
            self.feedback = None  # Consume the feedback
        else:
            feedback = AGENTS["config_mk_generator"].feedback("initial")

        if self.previous_config:
            previous_config = self.previous_config
            self.previous_config = None  # Consume the config
        else:
            previous_config = "None (First Attempt)"

        # Track the best run
        best_score = -1.0
        best_config_path = None

        # Load config.mk template
        with open(CONFIG_TEMPLATE, "r") as f:
            config_template = f.read()

        config_template = config_template.replace("<DESIGN_NAME>", module_id)
        config_template = config_template.replace("<PLATFORM>", ORFS_PLATFORM)

        # Load RTL code
        with open(rtl_path, "r") as f:
            rtl_code = f.read()

        # Start iterative process from the specifed starting iteration.
        # Try to find the best config file for the best score.
        while PHYSICAL_ITER <= MAX_PHYSICAL_ITERS:
            # Use the current counter value for
            # logs/files, then increment immediately
            i = PHYSICAL_ITER
            PHYSICAL_ITER += 1

            if CONFIG_PATH is None:
                print(f"\n{C}[CONFIG GEN] Iteration {i}/{MAX_PHYSICAL_ITERS}...{R}")

                # Generate the config.mk with current feedback
                with metered("config_mk_generator", f"config.mk generation, iteration {i}", CONFIG_MK_GENERATOR_LM):
                    result_config = self.config_generator(
                        iteration_count = f"Iteration {i}/{MAX_PHYSICAL_ITERS}", 
                        yaml_spec=yaml_spec,
                        config_rules=AGENTS["config_mk_generator"].rules, 
                        rtl_code=rtl_code,
                        config_template=config_template,
                        previous_config=previous_config, 
                        feedback=feedback,
                    )

                # Print lm input prompt, reasoning and output
                CONFIG_MK_GENERATOR_LM.inspect_history(n=1)

                # Save config.mk
                final_config = self._clean_config(raw=result_config.config_content)
                iter_config_path = save_file(PHYSICAL_DIR, f"{module_id}_ITER_{i}_config.mk", final_config)
                config_path = save_file(PHYSICAL_DIR, f"{module_id}_config.mk", final_config)
            else:
                # Use already created config.mk
                print(f"\nConfig generation flow skipped.\nUsing: {CONFIG_PATH}")
                final_config = Path(CONFIG_PATH).read_text()
                iter_config_path = final_config
            
            save_file(orfs_design_path, "config.mk", final_config)
            previous_config = final_config

            # Check if agent filled in all template placeholders
            placeholders = re.findall(r"<[A-Z_]+>", final_config)
            if placeholders:
                print(f"\n{RD}❌ Config generation failed due to unfilled placeholders: {placeholders}. Feeding back errors to agent...{R}")
                feedback = AGENTS["config_mk_generator"].feedback("unfilled_placeholders", placeholders=placeholders)
                continue

            # Run OpenROAD flow
            orfs_log, orfs_error_code = self._run_openroad_flow(orfs_design_path=orfs_design_path)
            save_file(PHYSICAL_DIR, f"{module_id}_ORFS_ITER_{i}.log", orfs_log)
            orfs_issues = self._extract_orfs_issues(orfs_log=orfs_log)

            # Check ORFS success criteria
            if orfs_error_code != 0 or orfs_issues:
                if CONFIG_PATH is not None:
                    # If a config is provided stop in one iteration
                    print(f"{RD}❌ OpenROAD flow failed.{R}")
                    return CONFIG_PATH, "Fail", ""

                print(f"{RD}❌ OpenROAD flow failed. Feeding back errors to agent...{R}")
                feedback = AGENTS["config_mk_generator"].feedback(
                    "orfs_failed", issues=orfs_issues if orfs_issues else "Fatal ORFS issue in OpenROAD flow."
                )
                continue

            print(f"\n{G}{B}✅ Success! OpenROAD Flow completed successfully.{R}")

            # No reference results: the layout cannot be scored, accept it as it is
            if not HAS_EVAL_REFERENCE:
                print(f"{Y}⚠️  No reference results for {DESIGN} in {EVALUATION_DIR / 'visible'}: "
                      f"the layout is accepted without a score.{R}")
                self._copy_openroad_results(orfs_results_dir=orfs_results_dir, rtl_path=rtl_path)
                return CONFIG_PATH or iter_config_path, "Success", ""
            
            # Evaluate OpenRoad results
            eval_log, eval_error_code = self._run_openroad_evaluation(orfs_results_dir=orfs_results_dir)
            save_file(PHYSICAL_DIR, f"{module_id}_openroad_eval_ITER_{i}.log", eval_log)

            # Move evaluation output JSON file to physical directory
            design_base = re.sub(r'_v\d+$', '', Path(DESIGN).stem)
            json_src = Path.cwd() / f"{design_base}.json"
            if json_src.exists():
                save_file(PHYSICAL_DIR, f"{Path(DESIGN).stem}_ITER_{i}.json", json_src.read_text())
                json_src.unlink()

            if eval_error_code != 0:
                print(f"\n{RD}❌ OpenROAD evaluation failed. {B}Cannot recover from this, stopping physical flow.{R}")
                return CONFIG_PATH or config_path, "Fail", ""
            
            # Extract score
            score_match = re.search(r"Final Score: ([\d\.]+)", eval_log)
            current_score = float(score_match.group(1)) if score_match else 0.0

            # Keep track of the best score
            if current_score > best_score:
                print(f"{G}🏆 New Best Score: {current_score:.2f}/100 (Previous: {best_score:.2f}/100){R}")
                best_score = current_score
                best_config_path = iter_config_path
                # Save as the "Global Best" for the solutions folder
                self._copy_openroad_results(orfs_results_dir=orfs_results_dir, rtl_path=rtl_path)

            # Extract wns max
            severe_timing = False
            wns_match = re.search(r"wns max\s+(-?[\d\.]+)", eval_log)
            if wns_match:
                wns_value = float(wns_match.group(1))
                # If WNS is significantly negative, it's likely an RTL architectural issue
                if wns_value < -0.5:
                    print(f"\n{RD}❌ Severe timing violation detected: WNS = {wns_value}ns{R}")

                    if ENABLE_RESYNTHESIS:
                        print(f"{RD}❌ Physical flow cannot fix this. Requesting RTL architectural change...{R}")
                        return CONFIG_PATH or best_config_path, "Timing Fail" , eval_log

                    # Resynthesis is disabled: keep the RTL and rely on the config.mk parameters
                    severe_timing = True
                    print(f"{Y}⚠️  Resynthesis is disabled. Keeping the current RTL.{R}")

            # If a config is provided stop in one iteration
            if CONFIG_PATH is not None:
                if eval_error_code == 0:
                    print(f"\n{G}{B}✅ Success! Single-run completed successfully for provided config.{R}")
                    return CONFIG_PATH, "Success", ""

            # The physical flow is accepted (flow and evaluation succeeded)
            if not ITERATIVE_OPTIMIZATION:
                print(f"\n{G}{B}✅ Success! Physical flow accepted (iterative optimization disabled).{R}")
                print(f"{G}{B}🏆 Score: {current_score:.2f}/100 using {best_config_path}{R}")
                return CONFIG_PATH or best_config_path, "Success", ""

            if current_score >= SCORE_THRESHOLD:
                print(f"\n{G}{B}✅ Success! Score {current_score:.2f} reached the threshold ({SCORE_THRESHOLD}).{R}")
                print(f"{G}{B}🏆 Best Score: {best_score:.2f} using {best_config_path}{R}")
                return CONFIG_PATH or best_config_path, "Success", ""

            # Prepare Optimization Feedback for next iteration
            agent = AGENTS["config_mk_generator"]
            feedback_parts = [agent.feedback("score_report", score=f"{current_score:.2f}", eval_log=eval_log)]
            if severe_timing:
                feedback_parts.append(agent.feedback("severe_timing_warning"))
            feedback_parts.append(agent.feedback("optimize_further"))
            feedback = "\n\n".join(feedback_parts)

        if best_score != -1.0:
            print(f"\n{G}{B}✅ Success! Physical design flow completed successfully.{R}")
            print(f"{G}{B}🏆 Best Score: {best_score:.2f} using {best_config_path}{R}")
            return CONFIG_PATH or best_config_path, "Success", ""

        print(f"\n{RD}{B}Reached max iterations ({MAX_PHYSICAL_ITERS}) without completing physical design flow.{R}")
        return CONFIG_PATH or config_path, "Fail", ""

# --- SINGLE AGENT (ONE AGENT, ONE PROMPT) ---

class SingleAgent(dspy.Signature):
    # Instructions: '# Role and Objective' of its Agent.md
    __doc__ = AGENTS["single_agent"].instructions
    workflow_and_rules = dspy.InputField(desc="Complete workflow, rules and output format")
    yaml_spec          = dspy.InputField(desc="Hardware functional requirements in YAML format")
    module_signature   = dspy.InputField(desc="Exact Verilog module port declaration")
    sdc_template       = dspy.InputField(desc="Available SDC templates to fill in (Sequential vs Combinational)")
    config_template    = dspy.InputField(desc="config.mk template to fill in")
    iteration_count    = dspy.InputField(desc="Current iteration number and maximum iterations")
    previous_testbench = dspy.InputField(desc="Testbench from the last iteration (if any)")
    previous_rtl       = dspy.InputField(desc="RTL from the last iteration (if any)")
    previous_sdc       = dspy.InputField(desc="SDC from the last iteration (if any)")
    previous_config    = dspy.InputField(desc="config.mk from the last iteration (if any)")
    feedback           = dspy.InputField(desc="Errors or performance metrics from the previous iteration, or 'Initial attempt.'")
    testbench_code     = dspy.OutputField(desc="Complete Verilog-2001 testbench, no explanation, no markdown, no timescale")
    rtl_code           = dspy.OutputField(desc="Complete synthesizable Verilog-2001 RTL, no explanation, no markdown")
    sdc_content        = dspy.OutputField(desc="Complete SDC file content, no markdown, no explanation")
    config_content     = dspy.OutputField(desc="Complete config.mk file content, no markdown, no explanation")

class SingleAgentFlow:
    """
    ONE agent with ONE prompt (configs/single_agent/Agent.md) drives the whole flow.

    In every iteration the agent produces the testbench, the RTL, the SDC and the config.mk.
    The same tools as in the multi-agent flow then run in order (TB syntax check, RTL simulation,
    SDC check, Yosys synthesis, [post-synthesis simulation], OpenROAD flow, evaluation). The first
    stage that fails stops the iteration and its errors are fed back to the same agent.

    The iterative score optimization (ITERATIVE_OPTIMIZATION, SCORE_THRESHOLD) and the
    resynthesis switch (ENABLE_RESYNTHESIS) behave exactly as in the multi-agent flow.
    """

    def __init__(self):
        self.agent = dspy.ChainOfThought(SingleAgent)
        self.spec  = AGENTS["single_agent"]  # Instructions, rules and feedback (configs/single_agent/Agent.md)

        # Helper instances: only their tool-running and cleaning methods are used.
        # Their own agents (TB / SDC / RTL / config generators) are never called.
        self.tb_helper   = TBFlow()
        self.sdc_helper  = SDCFlow()
        self.rtl_helper  = RTLFlow()
        self.phys_helper = PhysicalFlow()

    # --- Helpers ---

    @staticmethod
    def _sim_passed(log: str) -> bool:
        """A simulation passes if it printed PASS, never printed FAIL, and did not time out."""

        upper = log.upper()
        return "PASS" in upper and "FAIL" not in upper and "TIMED OUT" not in upper

    def _fail(self, stage: str, details: str, passed: list[str]) -> str:
        """Print the failure and build the feedback for the agent ('## stage_failed' of Agent.md)."""

        print(f"\n{RD}❌ {stage} failed. Feeding back errors to agent...{R}")
        return self.spec.feedback(
            "stage_failed",
            stage=stage,
            passed=", ".join(passed) if passed else "none",
            details=details,
        )

    @staticmethod
    def _check_tb_syntax(tb_path: Path, module_signature: str) -> tuple[bool, str]:
        """Compile the testbench together with an empty stub of the DUT."""

        with tempfile.TemporaryDirectory() as tmp:
            stub_path = Path(tmp) / "stub.v"
            stub_path.write_text(f"`timescale 1ns/1ps\n{module_signature}\nendmodule")

            proc = subprocess.run(
                ["iverilog", "-Wall", "-g2005", "-o", str(Path(tmp) / "tb_check.out"), str(tb_path), str(stub_path)],
                capture_output=True, text=True,
            )

        output = proc.stdout + proc.stderr
        return (proc.returncode == 0 and not output.strip()), output

    # --- Main loop ---

    def run(self, yaml_spec: str, module_signature: str, module_id: str,
            orfs_design_path: Path, orfs_rtl_src_dir: Path, orfs_results_dir: Path) -> str:
        """Run the single-agent loop. Return 'Success', 'Timing Fail' or 'Fail'."""

        # Workflow + rules + output format of the single agent (its instructions are the signature docstring)
        workflow_and_rules = self.spec.rules

        # Templates
        sdc_seq_template  = Path(SDC_SEQ_TEMPLATE).read_text().replace("<MODULE_NAME>", module_id)
        sdc_comb_template = Path(SDC_COMB_TEMPLATE).read_text().replace("<MODULE_NAME>", module_id)
        sdc_templates     = f"OPTION A (Sequential):\n{sdc_seq_template}\n\nOPTION B (Combinational):\n{sdc_comb_template}"

        config_template = Path(CONFIG_TEMPLATE).read_text()
        config_template = config_template.replace("<DESIGN_NAME>", module_id).replace("<PLATFORM>", ORFS_PLATFORM)

        # Netlist produced by the synthesis step
        netlist_path = Path(ORFS_DIR) / "flow" / "results" / ORFS_PLATFORM / module_id / "base" / "1_2_yosys.v"

        none_yet = "None (First Attempt)"
        prev_tb = prev_rtl = prev_sdc = prev_cfg = none_yet
        feedback = self.spec.feedback("initial")

        best_score = -1.0
        best_iter = None
        resynthesis_attempts = 0
        timing_exhausted = False

        for i in range(1, MAX_SINGLE_AGENT_ITERS + 1):
            print(f"\n{C}[SINGLE AGENT] Iteration {i}/{MAX_SINGLE_AGENT_ITERS}...{R}")
            passed: list[str] = []

            # --- 1. ONE call produces all the files ---
            with metered("single_agent", f"All files, iteration {i}", SINGLE_AGENT_LM):
                result = self.agent(
                    workflow_and_rules=workflow_and_rules,
                    yaml_spec=yaml_spec,
                    module_signature=module_signature,
                    sdc_template=sdc_templates,
                    config_template=config_template,
                    iteration_count=f"Iteration {i}/{MAX_SINGLE_AGENT_ITERS}",
                    previous_testbench=prev_tb,
                    previous_rtl=prev_rtl,
                    previous_sdc=prev_sdc,
                    previous_config=prev_cfg,
                    feedback=feedback,
                )

            # Print lm input prompt, reasoning and output
            SINGLE_AGENT_LM.inspect_history(n=1)

            tb_code  = self.tb_helper._clean_tb(raw=result.testbench_code)
            rtl_code = self.rtl_helper._clean_rtl(raw=result.rtl_code)
            sdc_code = self.sdc_helper._clean_sdc(raw=result.sdc_content)
            cfg_code = self.phys_helper._clean_config(raw=result.config_content)
            prev_tb, prev_rtl, prev_sdc, prev_cfg = tb_code, rtl_code, sdc_code, cfg_code

            # Save every file (iteration copy + latest copy)
            save_file(TB_GEN_DIR, f"{module_id}_ITER_{i}_tb.v", tb_code)
            tb_path = save_file(TB_GEN_DIR, f"{module_id}_tb.v", tb_code)

            save_file(orfs_rtl_src_dir, f"{module_id}.v", rtl_code)
            save_file(RTL_GEN_DIR, f"{module_id}_ITER_{i}.v", rtl_code)
            rtl_path = save_file(RTL_GEN_DIR, f"{module_id}.v", rtl_code)

            save_file(SDC_GEN_DIR, f"{module_id}_ITER_{i}.sdc", sdc_code)
            save_file(SDC_GEN_DIR, f"{module_id}.sdc", sdc_code)
            save_file(PHYSICAL_DIR, f"{module_id}_ITER_{i}_config.mk", cfg_code)
            save_file(PHYSICAL_DIR, f"{module_id}_config.mk", cfg_code)

            # --- 2. Testbench syntax ---
            print("\n--- CHECKING TESTBENCH ---")
            tb_ok, tb_output = self._check_tb_syntax(tb_path=tb_path, module_signature=module_signature)
            if not tb_ok:
                print(tb_output)
                feedback = self._fail("Testbench compilation",
                                      self.spec.feedback("tb_syntax_error", errors=tb_output), passed)
                continue
            if "PASS" not in tb_code:
                feedback = self._fail("Testbench reporting",
                                      self.spec.feedback("tb_missing_pass_message"), passed)
                continue
            passed.append("testbench syntax check")

            # --- 3. RTL simulation (iverilog + vvp) ---
            sim_log = self.rtl_helper._run_simulation(testbench_path=tb_path, design_path=rtl_path, mode="rtl")
            save_file(RTL_GEN_DIR, f"{module_id}_sim_ITER_{i}.log", sim_log)
            if not self._sim_passed(sim_log):
                feedback = self._fail("RTL simulation",
                                      self.spec.feedback("rtl_simulation_failed", log=sim_log), passed)
                continue
            passed.append("RTL simulation")
            print(f"\n{G}{B}✅ RTL verified.{R}")

            # --- 4. SDC checks (synthesis reads constraint.sdc, so it is verified first) ---
            save_file(orfs_design_path, "constraint.sdc", sdc_code)
            chosen_template = sdc_seq_template if "create_clock" in sdc_code else sdc_comb_template

            structure_issues = self.sdc_helper._verify_sdc_structure(chosen_template, sdc_code)
            if structure_issues:
                print(" ".join(structure_issues))
                feedback = self._fail("SDC structure check",
                                      self.spec.feedback("sdc_structure_violation", issues=" ".join(structure_issues)), passed)
                continue

            placeholders = re.findall(r"<[A-Z_]+>", sdc_code)
            if placeholders:
                feedback = self._fail("SDC placeholders",
                                      self.spec.feedback("sdc_unfilled_placeholders", placeholders=placeholders), passed)
                continue
            passed.append("SDC check")

            # --- 5. Synthesis (default config.mk, the agent's config.mk comes later) ---
            generate_orfs_project(module_id=module_id, orfs_dir=ORFS_DIR, platform=ORFS_PLATFORM)

            print(f"\n🚀 Starting synthesis for: {module_id}...")
            yosys_log, yosys_return_code = self.rtl_helper._run_yosys(orfs_design_path=orfs_design_path)
            save_file(RTL_GEN_DIR, f"{module_id}_yosys_ITER_{i}.log", yosys_log)
            synthesis_issues = self.rtl_helper._extract_yosys_issues(yosys_log=yosys_log)

            if yosys_return_code != 0 or synthesis_issues:
                issues_text = synthesis_issues if synthesis_issues else "--- ISSUES IDENTIFIED ---\nFatal Syntax Error in RTL."
                feedback = self._fail("Synthesis",
                                      self.spec.feedback("synthesis_failed", issues=issues_text), passed)
                continue
            passed.append("synthesis")
            print(f"{G}{B}✅ Success! Netlist saved at: {netlist_path}{R}")

            # --- 6. Post-synthesis simulation (only if VERIFICATION_MODE = "BOTH") ---
            if VERIFICATION_MODE.upper() == "BOTH":
                post_log = self.rtl_helper._run_simulation(testbench_path=tb_path, design_path=netlist_path, mode="post_synth")
                if not self._sim_passed(post_log):
                    feedback = self._fail("Post-synthesis simulation",
                                          self.spec.feedback("post_synthesis_failed", log=post_log), passed)
                    continue
                passed.append("post-synthesis simulation")

            # --- 7. config.mk checks ---
            save_file(orfs_design_path, "config.mk", cfg_code)

            placeholders = re.findall(r"<[A-Z_]+>", cfg_code)
            if placeholders:
                feedback = self._fail("config.mk placeholders",
                                      self.spec.feedback("config_unfilled_placeholders", placeholders=placeholders), passed)
                continue
            passed.append("config.mk check")

            # --- 8. OpenROAD flow ---
            orfs_log, orfs_error_code = self.phys_helper._run_openroad_flow(orfs_design_path=orfs_design_path)
            save_file(PHYSICAL_DIR, f"{module_id}_ORFS_ITER_{i}.log", orfs_log)
            orfs_issues = self.phys_helper._extract_orfs_issues(orfs_log=orfs_log)

            if orfs_error_code != 0 or orfs_issues:
                feedback = self._fail("OpenROAD flow",
                                      self.spec.feedback("orfs_failed",
                                                         issues=orfs_issues if orfs_issues else "Fatal ORFS issue in OpenROAD flow."), passed)
                continue
            passed.append("OpenROAD flow")
            print(f"\n{G}{B}✅ Success! OpenROAD Flow completed successfully.{R}")

            # No reference results: the layout cannot be scored, accept it as it is
            if not HAS_EVAL_REFERENCE:
                print(f"{Y}⚠️  No reference results for {DESIGN} in {EVALUATION_DIR / 'visible'}: "
                      f"the layout is accepted without a score.{R}")
                self.phys_helper._copy_openroad_results(orfs_results_dir=orfs_results_dir, rtl_path=rtl_path)
                return "Success"

            # --- 9. Evaluation ---
            eval_log, eval_error_code = self.phys_helper._run_openroad_evaluation(orfs_results_dir=orfs_results_dir)
            save_file(PHYSICAL_DIR, f"{module_id}_openroad_eval_ITER_{i}.log", eval_log)

            # Move evaluation output JSON file to physical directory
            design_base = re.sub(r'_v\d+$', '', Path(DESIGN).stem)
            json_src = Path.cwd() / f"{design_base}.json"
            if json_src.exists():
                save_file(PHYSICAL_DIR, f"{Path(DESIGN).stem}_ITER_{i}.json", json_src.read_text())
                json_src.unlink()

            if eval_error_code != 0:
                print(f"\n{RD}❌ OpenROAD evaluation failed. {B}Cannot recover from this, stopping.{R}")
                return "Fail"

            score_match = re.search(r"Final Score: ([\d\.]+)", eval_log)
            current_score = float(score_match.group(1)) if score_match else 0.0

            # Keep track of the best score and save it in the solutions folder
            if current_score > best_score:
                print(f"{G}🏆 New Best Score: {current_score:.2f}/100 (Previous: {best_score:.2f}/100){R}")
                best_score = current_score
                best_iter = i
                self.phys_helper._copy_openroad_results(orfs_results_dir=orfs_results_dir, rtl_path=rtl_path)

            # --- 10. Timing: resynthesis (RTL change) or config-only recovery ---
            severe_timing = False
            wns_match = re.search(r"wns max\s+(-?[\d\.]+)", eval_log)
            if wns_match and float(wns_match.group(1)) < -0.5:
                wns_value = float(wns_match.group(1))
                print(f"\n{RD}❌ Severe timing violation detected: WNS = {wns_value}ns{R}")

                if ENABLE_RESYNTHESIS:
                    resynthesis_attempts += 1
                    if resynthesis_attempts > MAX_RESYNTHESIS_ATTEMPTS:
                        print(f"{RD}❌ Timing not met after {MAX_RESYNTHESIS_ATTEMPTS} resynthesis attempts. Stopping.{R}")
                        timing_exhausted = True
                        break

                    print(f"{Y}🔁 Resynthesis {resynthesis_attempts}/{MAX_RESYNTHESIS_ATTEMPTS}: asking the agent to fix timing...{R}")
                    feedback = self.spec.feedback("timing_resynthesis", eval_log=eval_log)
                    continue

                # Resynthesis is disabled: keep the RTL and rely on the config.mk parameters
                severe_timing = True
                print(f"{Y}⚠️  Resynthesis is disabled. Keeping the current RTL.{R}")

            # --- 11. The physical flow is accepted ---
            if not ITERATIVE_OPTIMIZATION:
                print(f"\n{G}{B}✅ Success! Physical flow accepted (iterative optimization disabled).{R}")
                print(f"{G}{B}🏆 Score: {current_score:.2f}/100{R}")
                return "Success"

            if current_score >= SCORE_THRESHOLD:
                print(f"\n{G}{B}✅ Success! Score {current_score:.2f} reached the threshold ({SCORE_THRESHOLD}).{R}")
                return "Success"

            # Feedback for the next optimization iteration
            feedback_parts = [self.spec.feedback("score_report", score=f"{current_score:.2f}", eval_log=eval_log)]
            if severe_timing:
                feedback_parts.append(self.spec.feedback("severe_timing_warning"))
            feedback_parts.append(self.spec.feedback("optimize_further"))
            feedback = "\n\n".join(feedback_parts)

        # --- End of the loop ---
        if best_score >= 0:
            print(f"\n{G}{B}🏆 Best Score: {best_score:.2f} (iteration {best_iter}){R}")
            return "Timing Fail" if timing_exhausted else "Success"

        print(f"\n{RD}{B}Reached max iterations ({MAX_SINGLE_AGENT_ITERS}) without completing the flow.{R}")
        return "Fail"

def run_single_agent_flow(yaml_spec: str, module_signature: str, module_id: str) -> str:
    """Create the ORFS project and run the single-agent flow."""

    orfs_design_path, orfs_rtl_src_dir, orfs_results_dir = generate_orfs_project(
        module_id=module_id, orfs_dir=ORFS_DIR, platform=ORFS_PLATFORM
    )

    flow = SingleAgentFlow()
    return flow.run(
        yaml_spec=yaml_spec,
        module_signature=module_signature,
        module_id=module_id,
        orfs_design_path=orfs_design_path,
        orfs_rtl_src_dir=orfs_rtl_src_dir,
        orfs_results_dir=orfs_results_dir,
    )

# --- OPTIMIZATION ---

def build_rtl_trainset() -> list[dspy.Example]:
    """
    Build a DSPy trainset from RTL_TRAIN_DESIGNS.
    For each design, paths are automatically resolved from RESULTS_DIR:
        - TB  : ../results/visible/<design>/tb_gen_flow/<module_id>_tb_golden.v
        - SDC : ../results/visible/<design>/sdc_gen_flow/<module_id>_sdc_golden.sdc
        - RTL : ../results/visible/<design>/rtl_gen_flow/<module_id>_rtl_golden.v  (optional)
    """

    print("\nBuilding RTL generation flow's trainset...")

    examples = []
    for yaml_file in RTL_TRAIN_DESIGNS:

        # Load YAML spec
        yaml_path = PROBLEMS_DIR / yaml_file
        if not yaml_path.exists():
            print(f"Skipping '{yaml_file}': YAML spec not found at {yaml_path}.")
            continue

        with open(yaml_path, "r") as f:
            yaml_data = yaml.safe_load(f)

        module_id    = list(yaml_data.keys())[0]
        spec_content = yaml_data[module_id]
        yaml_spec    = spec_text(spec_content)
        module_sig   = spec_content.get("module_signature", "module design(...);")

        # Auto-resolve paths for this design
        design_results_dir = RESULTS_DIR.parent / Path(yaml_file).stem
        tb_path  = design_results_dir / "tb_gen_flow"  / f"{module_id}_tb_golden.v"
        sdc_path = design_results_dir / "sdc_gen_flow" / f"{module_id}_sdc_golden.sdc"
        rtl_path = design_results_dir / "rtl_gen_flow" / f"{module_id}_rtl_golden.v"  # optional

        if not tb_path.exists():
            print(f"Skipping '{yaml_file}': testbench not found at {tb_path}.")
            continue

        if not sdc_path.exists():
            print(f"Skipping '{yaml_file}': SDC not found at {sdc_path}.")
            continue

        gold_rtl = rtl_path.read_text() if rtl_path.exists() else ""

        orfs_design_path, orfs_rtl_src_dir, _ = generate_orfs_project(module_id=module_id, orfs_dir=ORFS_DIR, platform=ORFS_PLATFORM)

        # Save the SDC into the ORFS project
        path = Path(orfs_design_path) / "constraint.sdc"
        path.write_text(sdc_path.read_text())

        ex = dspy.Example(
            yaml_spec        = yaml_spec,
            module_signature = module_sig,
            module_id        = module_id,
            tb_path          = str(tb_path),
            orfs_design_path = orfs_design_path,
            orfs_rtl_src_dir = orfs_rtl_src_dir,
            rtl_gen_dir      = RESULTS_DIR.parent / Path(yaml_file).stem / "rtl_gen_flow",
        )

        # Attach gold RTL if available so MIPROv2 can use it as a labeled demo
        if gold_rtl:
            ex["rtl_code"] = gold_rtl

        # Define the inputs that the forward() function actually accepts
        ex = ex.with_inputs("yaml_spec", "module_signature", "module_id", "tb_path", "orfs_design_path", "orfs_rtl_src_dir", "rtl_gen_dir")

        examples.append(ex)
        print(f"Added '{module_id}' ({yaml_file}) to RTL trainset (gold_rtl={'yes' if gold_rtl else 'no'})")

    return examples

def make_rtl_metric(flow: RTLFlow) -> callable:
    """
    Return a DSPy-compatible metric function for RTL generation.

    Scoring:
        1.0  -> RTL simulation passed  (PASS in log, no FAIL)
        0.5  -> RTL compiled but simulation failed
        0.0  -> RTL failed to compile
    """

    def rtl_metric(example: dspy.Example, prediction: dspy.Prediction, trace=None) -> float:
        
        rtl_gen_dir = example.get("rtl_gen_dir", None)
        module_id = example.get("module_id", None)
        tb_path_str = example.get("tb_path", "")
        
        if not rtl_gen_dir or not module_id or not tb_path_str:
            print("[Metric Error] Missing vital metadata keys in Example.")
            return 0.0
        
        # Check the testbench path
        tb_path = Path(tb_path_str)
        if not tb_path.exists():
            print(f"[Metric Error] Testbench not found: {tb_path}")
            return 0.0
        
        # Target the exact path where your RTLFlow saved this candidate's code
        rtl_path = Path(rtl_gen_dir) / f"{module_id}.v"
        if not rtl_path.exists():
            print(f"[Metric Error] RTL file not found at expected path: {rtl_path}")
            return 0.0

        # Evaluate the generated RTL file
        sim_log = flow._run_simulation(testbench_path=tb_path, design_path=rtl_path, mode="rtl")

        # Parse log output to assign score
        if "PASS" in sim_log.upper() and "FAIL" not in sim_log.upper():
            score = 1.0
        elif "Compilation failed" in sim_log:
            score = 0.0
        else:
            score = 0.5

        return score

    return rtl_metric

def run_mipro_optimization(flow: RTLFlow, trainset: list[dspy.Example]) -> dspy.Module:
    """
    Run MIPROv2 optimization on the RTL Generation Flow using the LLM as teacher.
    The optimized program is saved to 'optimized_rtl_generator.json'.
    """

    metric = make_rtl_metric(flow=flow)

    # Set up the optimizer
    teleprompter = MIPROv2(
        metric                 = metric,       # The judge used to grade the RTLs
        prompt_model           = LLM,          # The Teacher who writes new instructions
        task_model             = SLM,          # The Student who generates the code
        teacher_settings       = dict(lm=LLM), # Use LLM for the "heavy thinking" steps
        auto                   = None,         # Enable manual setting of num_candidates and num_trials
        num_candidates         = 3,            # How many different prompt versions prompt_model will generate (one of these is picked in each trial)
        max_bootstrapped_demos = 2,            # Number of successful traces to include in the prompt
        max_labeled_demos      = 1,            # Number of raw examples from trainset
        num_threads            = 1,            # Run one model instance at a time
        max_errors             = 5,            # Stop if 5 consecutive trials throw exceptions
        verbose                = True,         # Print everything to the screen
    )

    print("\n" + "="*60)
    print("Starting MIPROv2 RTL Prompt Optimization...")
    print(f"Teacher : {LLM.model} (proposes instructions + few-shot demos)")
    print(f"Student : {SLM.model} (executes — NO weight updates)")
    print("="*60 + "\n")

    # Start the training process
    optimized_flow = teleprompter.compile(
        flow,
        trainset                   = trainset, 
        num_trials                 = 3,        # Number of rounds (trials) to search for the best prompt-demo combination
        minibatch                  = True,     # Check minibatch_size designs in each trial
        minibatch_size             = 1,        # Check only 1 design from valset in each trial
    )

    # Save the optimized prompt program
    optimized_flow.save(str(OPTIMIZED_RTL_FLOW_PATH))
    print(f"\nOptimized RTL prompt program saved to: {OPTIMIZED_RTL_FLOW_PATH}")

    return optimized_flow

def load_optimized_rtl_flow(flow: RTLFlow) -> RTLFlow:
    """Load a previously optimized RTL prompt program into the RTLFlow."""

    if not OPTIMIZED_RTL_FLOW_PATH.exists():
        print(f"{RD}\nNo optimized RTL program found at {OPTIMIZED_RTL_FLOW_PATH}. Run optimization first.{R}")
        return flow

    flow.load(str(OPTIMIZED_RTL_FLOW_PATH))
    print(f"Loaded optimized RTL prompt program from: {OPTIMIZED_RTL_FLOW_PATH}")
    return flow

# --- UTILITIES ---

def save_file(directory: Path, filename: str, content: str) -> Path:
    """Save given content to filename into provided directory"""
    
    # Create folder if not exists
    Path(directory).mkdir(parents=True, exist_ok=True)

    # Save content
    path = Path(directory) / filename
    path.write_text(content)

    print(f"✨ File {filename} saved at : {path}")
    return path

def check_environment():
    """Verify all tools, directories, and required scripts are present."""

    global ORFS_DIR
    
    print(f"Checking environment...")
    all_ok = True

    # All relative paths are relative to the script's folder, so the script must be run from there
    script_dir = Path(__file__).resolve().parent
    if Path.cwd().resolve() != script_dir:
        print(f"{RD}❌ Error: Run the script from its own folder: cd {script_dir}{R}")
        print(f"Current directory: {Path.cwd()}")
        exit(1)

    # Check for required binaries (Tools)
    tools = ["iverilog", "vvp", "yosys", "openroad"]
    for tool in tools:
        if shutil.which(tool) is None:
            print(f"{RD}❌ Error: Tool '{tool}' not found in PATH.{R}")
            all_ok = False

    # Try to auto detect ORFS_DIR
    orfs_bin = shutil.which("openroad")
    if orfs_bin is not None and ORFS_DIR is None:
        # Walk up from the binary until finding the ORFS root (identified by the 'flow' subdirectory)
        ORFS_DIR = next(
            (p for p in Path(orfs_bin).resolve().parents if (p / "flow").is_dir()),
            None
        )
        if ORFS_DIR is None:
            print(f"{RD}❌ Error: Could not locate OpenROAD-flow-scripts root. Set ORFS_DIR manually.'{R}")
            all_ok = False

    # Check for required directories
    required_dirs = [EVALUATION_DIR, PROBLEMS_DIR, RESULTS_DIR, SOLUTIONS_DIR, PDK_RTL_PATH]
    if ORFS_DIR is not None:
        required_dirs.append(ORFS_DIR)
    
    for d in required_dirs:
        d = Path(d)
        if not d.exists():
            if d == RESULTS_DIR or d == SOLUTIONS_DIR:
                try:
                    d.mkdir(parents=True)
                    print(f"{Y}⚠️  Directory '{d}' created.{R}")
                except Exception as e:
                    print(f"{RD}❌ Error: Could not create directory '{d}': {e}{R}")
                    all_ok = False
            else:
                print(f"{RD}❌ Error: Required directory not found: '{d}'{R}")
                all_ok = False

    # Check for PDK cell files
    pdk_cells = sorted(PDK_RTL_PATH.glob("*.v"))
    if not pdk_cells:
        print(f"{RD}❌ Error: No PDK .v cell files found in: '{PDK_RTL_PATH}'{R}")
        all_ok = False

    # Check for Required Files
    required_files = {
        "Design Spec": PROBLEMS_DIR / DESIGN,
        "Combinational SDC Template": SDC_COMB_TEMPLATE,
        "Sequential SDC Template": SDC_SEQ_TEMPLATE,
        "Config Template": CONFIG_TEMPLATE,
        "OpenROAD Evaluation Python Script": EVALUATION_DIR / "evaluate_openroad.py",
        "OpenROAD Evaluation TCL Script": EVALUATION_DIR / "report_metrics.tcl"
    }

    # Add override files if provided
    if TB_PATH is not None:
        required_files["Testbench Override"] = Path(TB_PATH)
    if SDC_PATH is not None:
        required_files["SDC Override"] = Path(SDC_PATH)
    if RTL_PATH is not None:
        required_files["RTL Override"] = Path(RTL_PATH)
    if CONFIG_PATH is not None:
        required_files["Config Override"] = Path(CONFIG_PATH)

    for label, path in required_files.items():
        if not Path(path).exists():
            print(f"{RD}❌ Error: {label} not found at: {path}{R}")
            all_ok = False

    # RTL trainset validation 
    if RTL_GEN_DSPY_MODE == "Optimize":
        for yaml_file in RTL_TRAIN_DESIGNS:
            yaml_path = PROBLEMS_DIR / yaml_file
            if not yaml_path.exists():
                print(f"{RD}❌ Error: Trainset spec '{yaml_file}' not found at {yaml_path}.{R}")
                all_ok = False
                continue

            # Parse YAML safely to get the internal top module_id
            try:
                with open(yaml_path, "r") as f:
                    yaml_data = yaml.safe_load(f)
                module_id = list(yaml_data.keys())[0]
            except Exception as e:
                print(f"{RD}❌ Error: Failed to parse trainset spec '{yaml_file}': {e}{R}")
                all_ok = False
                continue

            # Check for golden assets matching the structure in build_rtl_trainset
            design_results_dir = RESULTS_DIR.parent / Path(yaml_file).stem
            tb_path = design_results_dir / "tb_gen_flow" / f"{module_id}_tb_golden.v"
            sdc_path = design_results_dir / "sdc_gen_flow" / f"{module_id}_sdc_golden.sdc"
            
            if not tb_path.exists():
                print(f"{RD}❌ Error: Golden testbench missing for trainset design '{yaml_file}' at {tb_path}{R}")
                all_ok = False
            if not sdc_path.exists():
                print(f"{RD}❌ Error: Golden SDC missing for trainset design '{yaml_file}' at {sdc_path}{R}")
                all_ok = False

    elif RTL_GEN_DSPY_MODE == "Inference":
        if not OPTIMIZED_RTL_FLOW_PATH.exists():
            print(f"{RD}❌ Error: No optimized RTL program found at {OPTIMIZED_RTL_FLOW_PATH}. Run optimization first.{R}")
            all_ok = False

    # Agent.md checks: every agent used in this mode needs its Agent.md with
    # instructions, rules and all the feedback messages the flow sends back to it
    if AGENT_MODE == "single":
        md_agents = ["single_agent"]
    else:
        md_agents = ["tb_generator", "sdc_generator", "rtl_generator", "config_mk_generator"]
        if AGENT_CONFIGS.get("tb_validator") is not None:
            md_agents.append("tb_validator")
        if AGENT_CONFIGS.get("rtl_validator") is not None and not SKIP_RTL_VALIDATOR:
            md_agents.append("rtl_validator")

    for agent_name in md_agents:
        spec = AGENTS[agent_name]
        if not spec.path.exists():
            print(f"{RD}❌ Error: Agent.md of '{agent_name}' not found: '{spec.path}'{R}")
            all_ok = False
            continue
        # Empty sections are allowed (e.g. a minimal Agent.md to fill in), but reported
        if not spec.instructions:
            print(f"{Y}⚠️  '{agent_name}': '# Role and Objective' is empty in '{spec.path}' (DSPy default instructions are used).{R}")
        if not spec.rules:
            print(f"{Y}⚠️  '{agent_name}': '# Mandatory Rules' is empty in '{spec.path}' (the agent gets no rules).{R}")
        missing = [k for k in REQUIRED_FEEDBACK.get(agent_name, []) if not spec.feedback_messages.get(k, "").strip()]
        if missing:
            print(f"{Y}⚠️  '{agent_name}': no feedback message for {', '.join('## ' + k for k in missing)} "
                  f"(only the raw logs/issues are sent back).{R}")

    # Flow config value checks
    if VERIFICATION_MODE not in ("RTL", "BOTH"):
        print(f"{RD}❌ Error: flow.verification_mode must be 'RTL' or 'BOTH', got '{VERIFICATION_MODE}'.{R}")
        all_ok = False
    if RTL_GEN_DSPY_MODE not in ("Simple Run", "Optimize", "Inference"):
        print(f"{RD}❌ Error: flow.rtl_gen_dspy_mode must be 'Simple Run', 'Optimize' or 'Inference', got '{RTL_GEN_DSPY_MODE}'.{R}")
        all_ok = False

    # Agent mode checks
    if AGENT_MODE == "single":

        if RTL_GEN_DSPY_MODE != "Simple Run":
            print(f"{RD}❌ Error: flow.rtl_gen_dspy_mode = '{RTL_GEN_DSPY_MODE}' is not supported in single-agent mode. Use 'Simple Run'.{R}")
            all_ok = False

        overrides = {"TB_PATH": TB_PATH, "SDC_PATH": SDC_PATH, "RTL_PATH": RTL_PATH, "CONFIG_PATH": CONFIG_PATH}
        for name, value in overrides.items():
            if value is not None:
                print(f"{RD}❌ Error: overrides.{name.lower()} is not supported in single-agent mode. Set it to null.{R}")
                all_ok = False
    else:
        required_agents = ["tb_generator", "sdc_generator", "rtl_generator", "config_mk_generator"]

        for agent_name in required_agents:
            if AGENT_CONFIGS.get(agent_name) is None:
                print(f"{RD}❌ Error: Agent '{agent_name}' needs a config file (it cannot be disabled).{R}")
                all_ok = False

    # Clean previous solution files
    if SOLUTIONS_DIR.exists():
        for f in SOLUTIONS_DIR.iterdir():
            if f.is_file():
                f.unlink()

    if not all_ok:
        print(f"\n{RD}{B}CRITICAL: Environment check failed. Fix the errors above before running.{R}")
        exit(1)
    
    iterative_label = (
        f"ON (exit when score >= {SCORE_THRESHOLD})" if ITERATIVE_OPTIMIZATION
        else "OFF (exit at the first accepted physical flow)"
    )
    resynthesis_label = (
        f"ON (max {MAX_RESYNTHESIS_ATTEMPTS} attempts)" if ENABLE_RESYNTHESIS
        else "OFF (the RTL is never regenerated because of timing)"
    )

    print(f"System is ready!\n")
    print(f"Flow config file                   : {C}{ARGS.config}{R}")
    print(f"Starting Agentic ASIC flow for     : {C}{DESIGN}...{R}")
    print(f"Agent mode                         : {C}{AGENT_MODE.upper()}{R}")
    print(f"Verification mode                  : {C}{VERIFICATION_MODE}{R}")
    print(f"PPA scoring                        : {C}{'ON' if HAS_EVAL_REFERENCE else 'OFF (no reference results for this design: the layout is not scored)'}{R}")
    print(f"Iterative score optimization       : {C}{iterative_label}{R}")
    print(f"Resynthesis if timing is not met   : {C}{resynthesis_label}{R}")

    if AGENT_MODE == "single":
        print(f"Single agent model selected        : {C}{SINGLE_AGENT_LM.model}{R}")
        print(f"Single agent prompt                : {C}{SINGLE_AGENT_MD}{R}\n")
        return

    tb_val_str    = TB_VALIDATOR_LM.model if TB_VALIDATOR_LM is not None else "Disabled (None)"
    rtl_val_str   = RTL_VALIDATOR_LM.model if (RTL_VALIDATOR_LM is not None and not SKIP_RTL_VALIDATOR) else "Disabled (None)"

    print(f"RTL generation DSPy mode           : {C}{RTL_GEN_DSPY_MODE}{R}")
    print(f"TB  Generator model selected       : {C}{TB_GENERATOR_LM.model}{R}")
    print(f"TB  Validator model selected       : {C}{tb_val_str}{R}")
    print(f"SDC Generator model selected       : {C}{SDC_GENERATOR_LM.model}{R}")
    print(f"RTL Generator model selected       : {C}{RTL_GENERATOR_LM.model}{R}")
    print(f"RTL Validator model selected       : {C}{rtl_val_str}{R}")
    print(f"Config MK Generator model selected : {C}{CONFIG_MK_GENERATOR_LM.model}{R}\n")

def setup_logging(filename="asic_autonomous_flow.log"):
    """Redirect stdout and stderr to terminal (with color) and log file (clean text)."""
    
    class Logger(object):
        def __init__(self, terminal, log_file):
            self.terminal = terminal
            self.log = log_file
            # Regex to match ANSI escape sequences (colors)
            self.ansi_escape = re.compile(r'\x1b\[[0-9;]*[mK]')

        def write(self, message):
            # Write the original message (with colors) to the terminal
            self.terminal.write(message)
            
            # Strip colors and write to the log file
            clean_message = self.ansi_escape.sub('', message)
            self.log.write(clean_message)
            self.log.flush()

        def flush(self):
            self.terminal.flush()
            self.log.flush()

    # Open the log file
    Path(filename).parent.mkdir(parents=True, exist_ok=True)
    f = open(filename, "w", encoding="utf-8")
    
    # Replace stdout and stderr
    sys.stdout = Logger(sys.stdout, f)
    sys.stderr = sys.stdout

def generate_orfs_project(module_id: str, orfs_dir: Path, platform: str) -> tuple[Path, Path, Path]:
    '''
    Generate the OpenROAD Flow Scripts (ORFS) project, given the top module name, the ORFS directory and the target platform.
    Returns:
        orfs_design_dir  : Path to the ORFS design directory  (.../flow/designs/<platform>/<module_id>/)
        orfs_rtl_src_dir : Path to the ORFS RTL source directory (.../flow/designs/src/<module_id>/)
        orfs_results_dir : Path to the ORFS base results directory (.../flow/results/<platform>/<module_id>/base/)
    '''

    orfs_path        = Path(orfs_dir)
    orfs_design_dir  = orfs_path / "flow" / "designs" / platform / module_id
    orfs_rtl_src_dir = orfs_path / "flow" / "designs" / "src" / module_id
    orfs_results_dir = orfs_path / "flow" / "results" / platform / module_id
    config_path      = orfs_design_dir / "config.mk"

    # Create design dir (fail if it already exists)
    orfs_design_dir.mkdir(parents=True, exist_ok=True)
    # Create verilog src dir (fail if it already exists)
    orfs_rtl_src_dir.mkdir(parents=True, exist_ok=True)
    # Results dir will be created by the flow, but ensure parent exists
    orfs_results_dir.parent.mkdir(parents=True, exist_ok=True)

    # Populate config.mk from the template and write it into the design directory.
    # This config will be used for the synthesis proccess.
    # For the physical flow a new one will be generated from the Agent.
    with open(CONFIG_TEMPLATE, "r") as f:
        config_contents = f.read()

    # Define settings for the initial config to default values
    openroad_settings = {
        "<DESIGN_NAME>": module_id,
        "<PLATFORM>": platform,
        "<UTILIZATION_PERCENTAGE>": "50",
        "<ASPECT_RATIO_FLOAT>": "1.0",
        "<CORE_MARGIN_FLOAT>": "1.0",
        "<PLACEMENT_DENSITY_FLOAT>": "0.6",
        "<ROUTING_LAYER_ADJUSTMENT_FLOAT>": "0.5",
        "<ABC_AREA_0_OR_1>": "0",
        "<RESYNTH_TIMING_RECOVER_0_OR_1>": "0",
        "<RECOVER_POWER_PERCENTAGE>": "0"
    }

    # Apply to file content
    for tag, value in openroad_settings.items():
        config_contents = config_contents.replace(tag, value)

    with open(config_path, "w") as f:
        f.write(config_contents)

    return orfs_design_dir, orfs_rtl_src_dir, orfs_results_dir / "base"

# --- MAIN EXECUTION ---

def main():
    initial_start_time = time.time()
    setup_logging(LOG_FILE)
    check_environment()

    # Load the Spec
    design_spec = PROBLEMS_DIR / DESIGN
    with open(design_spec, "r") as f:
        yaml_data = yaml.safe_load(f)

    # Get the design in the YAML
    module_id = list(yaml_data.keys())[0]
    spec_content = yaml_data[module_id]
    signature_prompt = spec_content.get('module_signature', 'module design(...);')

    # Configure RTL generation flow based on RTL_GEN_DSPY_MODE
    if RTL_GEN_DSPY_MODE == "Optimize":
        start_time = time.time()
        trainset = build_rtl_trainset()
        if not trainset:
            print("RTL trainset is empty. Check your trainset configuration.")
            return

        rtl_flow = RTLFlow()
        rtl_flow = run_mipro_optimization(flow=rtl_flow, trainset=trainset)

        print(f"⏱️  MIPROv2 optimization time: {time.time() - start_time:.2f} seconds")
        return

    # Single-agent mode: ONE agent and ONE prompt (configs/single_agent/Agent.md) for the whole flow
    if AGENT_MODE == "single":
        print(f"\n{B}{'='*70}{R}")
        print(f"\n🚀 Starting single-agent flow for: {module_id}...")
        start_time = time.time()

        status = run_single_agent_flow(
            yaml_spec=spec_text(spec_content),
            module_signature=signature_prompt,
            module_id=module_id,
        )

        print(f"⏱️  Single-agent flow time: {time.time() - start_time:.2f} seconds")
        print(f"\n{B}{'='*70}{R}")

        if status == "Success":
            print(f"\n{G}{B}✅ Success! Agentic flow completed successfully.{R}")
        elif status == "Timing Fail":
            print(f"\n{RD}{B}❌ Failure! Timing could not be met (best result was saved).{R}")
        else:
            print(f"\n{RD}{B}❌ Failure! Agentic flow failed to complete.{R}")

        print(f"⏱️  Total Agentic flow time: {time.time() - initial_start_time:.2f} seconds")
        return

    print(f"\n{B}{'='*70}{R}")

    if TB_PATH is None:
        # Initialize and run the TB Flow
        print(f"\n🚀 Starting testbench generation flow for: {module_id}...")
        start_time = time.time()

        tb_flow = TBFlow()
        tb_path, status = tb_flow(yaml_spec=spec_text(spec_content), module_signature=signature_prompt, module_id=module_id)
        print(f"⏱️  TB generation time: {time.time() - start_time:.2f} seconds")

        # TB generation failed
        if status == "Fail":
            return
    else:
        # Use already created testbench
        tb_path = TB_PATH
        print(f"\nTestbench generation flow skipped.\nUsing: {tb_path}")

    print(f"\n{B}{'='*70}{R}")
    orfs_design_path, orfs_rtl_src_dir, orfs_results_dir = generate_orfs_project(module_id=module_id, orfs_dir=ORFS_DIR, platform=ORFS_PLATFORM)

    if SDC_PATH is None:
        # Initialize and run the SDC Flow
        print(f"\n🚀 Starting SDC generation flow for: {module_id}...")
        start_time = time.time()
        
        sdc_flow = SDCFlow()
        _, status = sdc_flow(yaml_spec=spec_text(spec_content), module_id=module_id, orfs_design_path=orfs_design_path)
        print(f"⏱️  SDC generation time: {time.time() - start_time:.2f} seconds")

        # SDC generation failed
        if status == "Fail":
            return
    else:
        # Use already created SDC
        print(f"\nSDC generation flow skipped.\nUsing: {SDC_PATH}")
        save_file(orfs_design_path, "constraint.sdc", Path(SDC_PATH).read_text())

    print(f"\n{B}{'='*70}{R}")

    # Initialize RTL and Physical flow
    rtl_flow_loaded = False
    rtl_flow = RTLFlow()
    physical_flow = PhysicalFlow()

    # Number of times the RTL was regenerated because of timing (resynthesis)
    resynthesis_attempts = 0

    # Loop: RTL Flow -> Physical Flow -> RTL Flow (if timing fails by far)
    # The loop back to the RTL Flow only happens when ENABLE_RESYNTHESIS = True.
    while True:
       # Check if there is any specified feedback from physical flow results
        has_feedback = any([rtl_flow.feedback, rtl_flow.previous_rtl])

        if RTL_PATH is None or has_feedback:
            # Run the RTL Flow
            print(f"\n🚀 Starting synthesizable RTL generation flow for: {module_id}...")
            start_time = time.time()

            if RTL_GEN_DSPY_MODE == "Inference" and rtl_flow_loaded == False:
                rtl_flow = load_optimized_rtl_flow(flow=rtl_flow)
                rtl_flow_loaded = True

            prediction = rtl_flow(
                yaml_spec=spec_text(spec_content), 
                module_signature=signature_prompt, 
                module_id=module_id, 
                tb_path=tb_path, 
                orfs_design_path=orfs_design_path, 
                orfs_rtl_src_dir=orfs_rtl_src_dir
            )

            rtl_path = prediction.rtl_path
            status   = prediction.status
            
            print(f"⏱️  RTL generation time: {time.time() - start_time:.2f} seconds")

            # RTL generation failed
            if status == "Fail":
                break
        else:
            # Use already created RTL
            rtl_path = RTL_PATH
            print(f"\nRTL generation flow skipped.\nUsing: {rtl_path}")
            save_file(orfs_rtl_src_dir, f"{module_id}.v", Path(rtl_path).read_text())

        print(f"\n{B}{'='*70}{R}")

        # Run the Physical Flow
        print(f"\n🚀 Starting physical flow for: {module_id}...")
        start_time = time.time()

        _, status, eval_log = physical_flow(
            yaml_spec=spec_text(spec_content), 
            module_id=module_id, 
            rtl_path=rtl_path, 
            orfs_design_path=orfs_design_path, 
            orfs_results_dir=orfs_results_dir
        )

        print(f"⏱️  Physical flow time: {time.time() - start_time:.2f} seconds")
        print(f"\n{B}{'='*70}{R}")

        if status == "Fail":
            print(f"\n{RD}{B}❌ Failure! Agentic flow failed to complete.{R}")
            break
        elif status == "Timing Fail":
            if not ENABLE_RESYNTHESIS:
                print(f"\n{Y}⚠️  Timing not met, but resynthesis is disabled. Stopping.{R}")
                break

            resynthesis_attempts += 1
            if resynthesis_attempts > MAX_RESYNTHESIS_ATTEMPTS:
                print(f"\n{RD}❌ Timing not met after {MAX_RESYNTHESIS_ATTEMPTS} resynthesis attempts. Stopping.{R}")
                break

            print(f"\n{Y}🔁 Resynthesis {resynthesis_attempts}/{MAX_RESYNTHESIS_ATTEMPTS}: regenerating the RTL to fix timing...{R}")
            rtl_flow.previous_rtl = Path(rtl_path).read_text()
            rtl_flow.feedback = AGENTS["rtl_generator"].feedback("timing_resynthesis", eval_log=eval_log)
            rtl_flow.timing_retry = True
            continue  # Trigger RTL generation again with timing feedback
        else:
            print(f"\n{G}{B}✅ Success! Agentic flow completed successfully.{R}")
            break

    print(f"⏱️  Total Agentic flow time: {time.time() - initial_start_time:.2f} seconds")

if __name__ == "__main__":
    try:
        main()
    finally:
        # Always print the token report, also when the flow stops early
        TOKENS.report(TOKEN_REPORT)