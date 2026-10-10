# 02 — Working with the owner

## Git

- The owner commits and pushes from **Windows PowerShell**. Give ready-to-paste commands:
  ```powershell
  git add <only the files you changed>
  git commit -m "<what changed>" -m "<optional co-author / session lines if the owner uses them>"
  git push
  ```
- Never `git add -A` / `git add .`: run outputs (Part 1 `tb.v`, `golden.tb`, `runs/`, `results/`) live in the tree.
- Mention untracked files you did NOT include and why.
- `.gitignore` rules worth knowing: `*.log` is ignored but `!scripts/rescue/runs/**/*.log` keeps the rescue
  console logs; `scripts/reference/p*/build/`, `scripts/regression/logs/`, `scripts/profile/results/runs/`,
  `_to_delete/` are ignored.
- `.gitattributes` forces LF on `Dockerfile.arm64` (and shell scripts must stay LF — CRLF breaks bash in Docker).
- The paper work happens in a **private mirror** (`git clone --bare` + `git push --mirror`), with the public
  repo as `upstream` (push disabled). Tutorial fixes go to the public repo; paper code goes to the private one.

## Security

- `scripts/api_keys.sh` = the owner's real keys. Never read it into output, never commit it, never copy it
  into another file. The template is `api_keys.example.sh`. Configs reference env var names only.
- `problem/` and `solution/` folders are handed to attendees: no keys, no private notes, no paper material.

## How to work

- **Check before you claim.** Run the tool, read the code, compute the number. If the owner's comment
  describes behaviour the code does not have (it happened: loop order in Part 3, `.yaml` vs `plan.json`,
  "negative slack prints a warning"), implement/describe what the code does and flag the mismatch clearly.
- **Small, verifiable steps.** After changing a flow: `python3 scripts/regression/regression.py --quick`
  (or the full one), and `check_designs.py` for anything touching designs or testbenches.
- **Keep problem/ and solution/ in sync** for every flow change (the six flow copies: Part 2 and 3 have
  `asic_autonomous_flow.py` in problem + solution, Part 4 `asic_orchestrated_flow.py` in problem + solution).
- **Long runs**: tell the owner how long, and prefer scripts they can resume (`--skip-existing`, CSV resume).
- **Owner's machine**: an agent connected to the owner's folder cannot delete files there; move them to
  `_to_delete/` and say so. Writing a file over an existing one through the bridge may silently keep the old
  content — verify with `md5sum` after writing.

## Style the owner likes

- Concise answers: what changed, the file, the command. No long recaps.
- Beginner-friendly wording in anything attendees see (README, slides, notes, script help).
- Tables for comparisons, numbered steps for procedures, real commands in code blocks.
- Vocabulary: designs, golden run, single agent, multi-agent, hybrid (LLM + SLM), orchestrator, workers,
  rescue runs, run 2a/2b/2c/2d.
- Things the owner explicitly did NOT want: ICLAD history/statistics in the slides, slides the audience does
  not need (e.g. old design lists), "single shot" for run 2a.

## Models

Profiles (in each `configs/<agent>/config.yaml`): `ollama-llama3.1` (local), `gemini_lite`, `gemini_preview`,
`claude-haiku-4-5` (temp 0.0), `claude-sonnet-5-5` (temp 1), `claude-opus-5-5` (temp 1).
Gemini preview often returns 503 / high demand: rerun, or switch to `gemini_lite`.
Keys: `GEMINI_API_KEY` / `ANTHROPIC_API_KEY` from `api_keys.sh` (sourced by the env / container).
