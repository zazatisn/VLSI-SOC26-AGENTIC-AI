# AGENTS.md — start here

Rules and context for any AI agent (or person) working on this repository.
Read this file first, then the files in `docs/handoff/` that match your task.

| file | read it when you … |
|---|---|
| `docs/handoff/01_project.md` | need the big picture: what the repo is, where everything lives, current status |
| `docs/handoff/02_working_rules.md` | work with the owner: git, security, style, how to report |
| `docs/handoff/03_technical_lessons.md` | touch the flows, designs, testbenches, Docker, OpenROAD — the traps we already fell into |
| `docs/handoff/04_slides.md` | edit the tutorial deck |
| `docs/handoff/05_paper.md` | work on the research paper (experiments, profiling, related work) |

## The ten rules that matter most

1. **Never commit, print or copy API keys.** `scripts/api_keys.sh` holds the owner's real keys and is
   git-ignored. Configs only name the environment variable. `problem/` and `solution/` folders are given
   to tutorial attendees: nothing private goes there.
2. **The owner commits.** Make the changes in the working tree, then give the exact PowerShell commands
   (`git add <files>`, `git commit -m ...`, `git push`). Do not push yourself unless asked. Add only the
   files you changed — never `git add -A` (generated run outputs live in the tree).
3. **Verify claims against the code and by running things.** Several "facts" in slides and notes were
   wrong until someone ran the check (see `03_technical_lessons.md`). If a request or comment describes
   behaviour the code does not have, do it the way the code works and say so explicitly.
4. **A flow PASS is not proof.** The agent's RTL passing the agent's own testbench says nothing if the
   testbench is wrong. Sign off with `scripts/reference/check_designs.py` (our testbench, golden RTL, mutants).
5. **Scores are relative to our golden run** (`evaluation/visible/pN/pN.json`): golden = 80/100
   (75 for p9 and p13, whose golden run has negative slack). Do not regenerate references casually
   (`make_reference.py --force` changes every score).
6. **Run EDA work inside the Docker image** (`/home/scripts`, ORFS at `/home/OpenROAD-flow-scripts`) or the
   local install (`~/eda/vlsi_soc_env.sh`). Never run two flows of the *same design* in parallel.
7. **Keep the tutorial runnable for beginners.** Every change to the flows must keep `problem/` and
   `solution/` in sync, keep `regression.py` passing, and keep the rescue recordings meaningful.
8. **Use the owner's vocabulary:** "designs" (not problems), "single agent" (not single shot),
   "golden run", "run 2a/2b/2c/2d", "orchestrator", "workers", "rescue runs".
9. **Write for beginners, briefly.** Plain words, short sentences, concrete commands. Explain *why*, once.
10. **Clean up safely.** On the owner's machine files cannot be deleted by the agent: move them to
    `_to_delete/` (git-ignored) and tell the owner.
