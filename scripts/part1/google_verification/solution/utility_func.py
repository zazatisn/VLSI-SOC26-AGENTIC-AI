import os
import re
import subprocess


# --- 1. TOKEN METRICS & THROUGHPUT HELPERS ---
def extract_tokens(entry: dict) -> tuple[int, int, int]:
    """Extracts prompt, completion, and total token usage from an LM history entry."""
    usage = entry.get("usage", {})
    if isinstance(usage, dict):
        p = usage.get("prompt_tokens") or usage.get("prompt_eval_count", 0)
        c = usage.get("completion_tokens") or usage.get("eval_count", 0)
        return p, c, usage.get("total_tokens") or (p + c)
    p = getattr(usage, "prompt_tokens", 0) or getattr(usage, "prompt_eval_count", 0)
    c = getattr(usage, "completion_tokens", 0) or getattr(usage, "eval_count", 0)
    return p, c, getattr(usage, "total_tokens", 0) or (p + c)


def get_token_stats(lm_instance, start_idx: int = 0, end_idx: int = None) -> dict:
    """Calculates token usage statistics from a range of LM history entries."""
    entries = lm_instance.history[start_idx:end_idx]
    tot_p, tot_c, tot_t = 0, 0, 0
    for entry in entries:
        p, c, t = extract_tokens(entry)
        tot_p += p
        tot_c += c
        tot_t += t
    return {"prompt_tokens": tot_p, "completion_tokens": tot_c, "total_tokens": tot_t}


def compute_throughput(tokens: int, duration_sec: float) -> tuple[float, float]:
    """Calculates Tokens Per Second (TPS) and Tokens Per Minute (TPM)."""
    if duration_sec <= 0:
        return 0.0, 0.0
    tps = tokens / duration_sec
    return tps, tps * 60.0


# --- 2. AGENT RULES & FILE HELPERS ---
def load_agent_instructions(agent_filepath: str = "AGENT.md") -> str:
    """Loads agent rules and objectives directly from AGENT.md."""
    if not os.path.exists(agent_filepath):
        print(f"Warning: '{agent_filepath}' not found. Falling back to default rules.")
        return "Write standard Verilog-2001 self-checking testbench to isolate 1 correct RTL design."

    with open(agent_filepath, "r", encoding="utf-8") as f:
        content = f.read()

    match = re.search(r"# Mandatory Rules.*?\n(.*?)(?=\n#|\Z)", content, re.DOTALL)
    if match:
        return match.group(1).strip()

    match_role = re.search(r"# Role and Objective\n(.*?)(?=\n#|\Z)", content, re.DOTALL)
    return match_role.group(1).strip() if match_role else content.strip()


def get_file_content(path: str) -> str:
    """Reads and returns text file content if available."""
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    return ""


def clean_and_format_verilog(raw_code: str) -> str:
    """Strips Markdown code blocks and formats standard timescale headers."""
    raw = re.sub(r"^```\w*\n", "", raw_code.strip())
    raw = re.sub(r"\n```$", "", raw.strip())
    m = re.search(r"(module\s+\w+.*?endmodule)", raw, re.DOTALL)
    code = m.group(1).strip() if m else raw.strip()
    return "`timescale 1ns/1ps\n\n" + re.sub(r"`timescale\s+.*?\n", "", code).strip()


def save_as_golden_tb(tb_code: str, mutant_dir: str, filename: str = "golden.tb") -> str:
    """Saves the verified testbench code as golden.tb in the design subfolder."""
    clean_tb = clean_and_format_verilog(tb_code)
    golden_path = os.path.join(mutant_dir, filename)
    with open(golden_path, "w", encoding="utf-8") as f:
        f.write(clean_tb)
    return golden_path


# --- 3. EVALUATION RUNNER ---
def run_evaluator(tb_code: str, mutant_dir: str, root_dir: str) -> tuple[int, str]:
    """Writes testbench code to disk and executes mutant_evaluator.py."""
    clean_tb = clean_and_format_verilog(tb_code)
    tb_path = os.path.join(mutant_dir, "tb.v")

    with open(tb_path, "w", encoding="utf-8") as f:
        f.write(clean_tb)

    eval_script = f"python3 {os.path.join(root_dir, 'mutant_evaluator.py')}"

    try:
        res = subprocess.run(
            eval_script, shell=True, capture_output=True, text=True, cwd=mutant_dir, timeout=30
        )
        feedback = res.stdout + res.stderr
    except subprocess.TimeoutExpired:
        feedback = "Timeout during execution after 30 seconds."

    ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
    clean_feedback = ansi_escape.sub("", feedback)
    passed_mutants = re.findall(r"(mutant_\d+).*?PASSED", clean_feedback)
    return len(passed_mutants), clean_feedback
