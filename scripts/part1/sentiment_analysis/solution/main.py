import dspy
from dspy.teleprompt import BootstrapFewShot
import json
import os
import re
import time
from lm_loader import load_configured_lm

# 1. Dynamically configure DSPy from config.yaml
lm = load_configured_lm("config.yaml")
dspy.configure(lm=lm)


# 2. Helper Functions to Load External Agent Data & Datasets
def load_agent_instructions(agent_filepath="AGENT.md"):
    """Extracts instructions and data source references from AGENT.md."""
    with open(agent_filepath, "r", encoding="utf-8") as f:
        content = f.read()

    docstring_match = re.search(r"# Role and Objective\n(.*?)(?=\n#|\Z)", content, re.DOTALL)
    instructions = docstring_match.group(1).strip() if docstring_match else "Analyze sentiment."

    data_match = re.search(r"data_source:\s*(.+)", content)
    data_file = data_match.group(1).strip() if data_match else "trainset.json"

    return instructions, data_file


def load_dataset(json_filepath):
    """Loads JSON data and formats it for DSPy."""
    with open(json_filepath, "r", encoding="utf-8") as f:
        raw_data = json.load(f)
    
    examples = [dspy.Example(**item) for item in raw_data]
    return [x.with_inputs('sentence') for x in examples]


# 3. Token & Performance Tracking Helpers
def extract_tokens_from_entry(entry):
    """Safely extracts prompt, completion, and total tokens from a single history item."""
    usage = entry.get("usage", {})
    if isinstance(usage, dict):
        p_tokens = usage.get("prompt_tokens") or usage.get("prompt_eval_count", 0)
        c_tokens = usage.get("completion_tokens") or usage.get("eval_count", 0)
        t_tokens = usage.get("total_tokens") or (p_tokens + c_tokens)
        return p_tokens, c_tokens, t_tokens
    
    p_tokens = getattr(usage, "prompt_tokens", 0) or getattr(usage, "prompt_eval_count", 0)
    c_tokens = getattr(usage, "completion_tokens", 0) or getattr(usage, "eval_count", 0)
    t_tokens = getattr(usage, "total_tokens", 0) or (p_tokens + c_tokens)
    return p_tokens, c_tokens, t_tokens


def get_token_stats(start_idx=0, end_idx=None):
    """Calculates cumulative token usage across a slice of lm.history."""
    entries = lm.history[start_idx:end_idx]
    tot_p, tot_c, tot_t = 0, 0, 0
    for entry in entries:
        p, c, t = extract_tokens_from_entry(entry)
        tot_p += p
        tot_c += c
        tot_t += t
    return {"prompt_tokens": tot_p, "completion_tokens": tot_c, "total_tokens": tot_t}


def compute_throughput(tokens, duration_sec):
    """Computes Tokens Per Second (TPS) and Tokens Per Minute (TPM)."""
    if duration_sec <= 0:
        return 0.0, 0.0
    tps = tokens / duration_sec
    tpm = tps * 60.0
    return tps, tpm


# 4. Dynamic Signature Creation
instructions, dataset_path = load_agent_instructions("AGENT.md")
trainset = load_dataset(dataset_path)

class DynamicSentimentAnalysis(dspy.Signature):
    __doc__ = instructions
    sentence = dspy.InputField(desc="The text to analyze")
    sentiment = dspy.OutputField(desc="Must be exactly: Positive, Negative, or Neutral")


# 5. DSPy Module Definition
class SentimentClassifier(dspy.Module):
    def __init__(self):
        super().__init__()
        self.classifier = dspy.ChainOfThought(DynamicSentimentAnalysis)
        
    def forward(self, sentence):
        return self.classifier(sentence=sentence)


# 6. Metric Function
def exact_match_metric(reference, prediction, trace=None): 
    ref_sentiment = reference.sentiment.strip().lower()
    pred_sentiment = prediction.sentiment.strip().lower()
    return ref_sentiment == pred_sentiment


# 7. Load External Hard Test Dataset
testset_path = "testset.json"
testset = load_dataset(testset_path)


# 8. Custom Evaluator Engine (with Per-Prompt TPM & TPS Logging)
def evaluate_pipeline(model, dataset, name="Model"):
    """Evaluates model, tracks latency and TPM per call, and logs performance."""
    print(f"\n==================================================")
    print(f"   EVALUATING: {name}")
    print(f"==================================================")
    
    correct_count = 0
    total_count = len(dataset)
    start_history_len = len(lm.history)
    phase_start_time = time.perf_counter()

    for idx, ex in enumerate(dataset, 1):
        prev_call_count = len(lm.history)
        
        # Measure call duration
        prompt_start_time = time.perf_counter()
        prediction = model(sentence=ex.sentence)
        prompt_duration = time.perf_counter() - prompt_start_time
        
        is_correct = exact_match_metric(ex, prediction)
        call_tokens = get_token_stats(prev_call_count)
        
        # Calculate throughput for this individual prompt
        call_tps, call_tpm = compute_throughput(call_tokens["total_tokens"], prompt_duration)
        
        status = "✅ PASS" if is_correct else "❌ FAIL"
        if is_correct:
            correct_count += 1

        print(f"\n[{idx}/{total_count}] {status}")
        print(f"Sentence:   \"{ex.sentence}\"")
        print(f"Expected:   {ex.sentiment}")
        print(f"Predicted:  {prediction.sentiment}")
        print(f"Reasoning:  {getattr(prediction, 'reasoning', 'N/A')}")
        print(f"Latency:    {prompt_duration:.2f}s")
        print(f"Tokens:     In: {call_tokens['prompt_tokens']} | Out: {call_tokens['completion_tokens']} | Total: {call_tokens['total_tokens']}")
        print(f"Throughput: {call_tpm:,.1f} TPM ({call_tps:.2f} TPS)")
        print("-" * 50)

    phase_duration = time.perf_counter() - phase_start_time
    accuracy = (correct_count / total_count) * 100
    phase_tokens = get_token_stats(start_history_len)
    phase_tps, phase_tpm = compute_throughput(phase_tokens["total_tokens"], phase_duration)
    
    phase_stats = {
        "tokens": phase_tokens,
        "duration": phase_duration,
        "tps": phase_tps,
        "tpm": phase_tpm
    }
    
    print(f"\n>>> Final Accuracy ({name}): {correct_count}/{total_count} ({accuracy:.1f}%)")
    print(f">>> Phase Performance ({name}): {phase_tokens['total_tokens']} tokens in {phase_duration:.2f}s | Avg Throughput: {phase_tpm:,.1f} TPM ({phase_tps:.2f} TPS)\n")
    return accuracy, phase_stats


# 9. Execution Pipeline with Global Time & Throughput Audit

script_start_time = time.perf_counter()

# STEP A: Evaluate Baseline (Untrained Model)
baseline_classifier = SentimentClassifier()
baseline_score, baseline_stats = evaluate_pipeline(baseline_classifier, testset, name="Baseline (Untrained)")

# STEP B: Compile Pipeline with Optimizer
print(f"Loaded {len(trainset)} training examples from {dataset_path}")
print("Compiling pipeline with BootstrapFewShot...")

compile_start_idx = len(lm.history)
compile_start_time = time.perf_counter()

optimizer = BootstrapFewShot(
    metric=exact_match_metric,
    max_bootstrapped_demos=3,
    max_labeled_demos=3
)
compiled_classifier = optimizer.compile(SentimentClassifier(), trainset=trainset)

compile_duration = time.perf_counter() - compile_start_time
compile_tokens = get_token_stats(compile_start_idx)
compile_tps, compile_tpm = compute_throughput(compile_tokens["total_tokens"], compile_duration)

print(f"Compilation complete in {compile_duration:.2f}s!")
print(f"Compilation Tokens: {compile_tokens['total_tokens']} | Throughput: {compile_tpm:,.1f} TPM ({compile_tps:.2f} TPS)\n")

# STEP C: Evaluate Compiled Model
compiled_score, compiled_stats = evaluate_pipeline(compiled_classifier, testset, name="Compiled (DSPy Optimized)")

# STEP D: Script Overall Performance Metrics
total_script_duration = time.perf_counter() - script_start_time
grand_total_tokens = get_token_stats(0)
overall_tps, overall_tpm = compute_throughput(grand_total_tokens["total_tokens"], total_script_duration)


# STEP E: Detailed Summary Report
print("=" * 65)
print("              EVALUATION, TOKENS & THROUGHPUT SUMMARY             ")
print("=" * 65)
print(f"Untrained Baseline Accuracy: {baseline_score:.1f}%")
print(f"DSPy Compiled Accuracy:     {compiled_score:.1f}%")
print(f"Net Accuracy Improvement:   {compiled_score - baseline_score:+.1f}%")
print("-" * 65)
print(f"Baseline Eval:   {baseline_stats['tokens']['total_tokens']:>6} tokens | {baseline_stats['duration']:>6.2f}s | {baseline_stats['tpm']:>9,.1f} TPM ({baseline_stats['tps']:>5.2f} TPS)")
print(f"Compilation:     {compile_tokens['total_tokens']:>6} tokens | {compile_duration:>6.2f}s | {compile_tpm:>9,.1f} TPM ({compile_tps:>5.2f} TPS)")
print(f"Compiled Eval:   {compiled_stats['tokens']['total_tokens']:>6} tokens | {compiled_stats['duration']:>6.2f}s | {compiled_stats['tpm']:>9,.1f} TPM ({compiled_stats['tps']:>5.2f} TPS)")
print("-" * 65)
print(f"SCRIPT TOTAL:    {grand_total_tokens['total_tokens']:>6} tokens | {total_script_duration:>6.2f}s | {overall_tpm:>9,.1f} TPM ({overall_tps:>5.2f} TPS)")
print("=" * 65)