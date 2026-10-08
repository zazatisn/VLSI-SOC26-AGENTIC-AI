# Rescue runs

Live demos fail: Wi-Fi, API quotas ("model overloaded"), a laptop that takes 20 minutes for
OpenROAD. Record every run you plan to show **before** the tutorial, then show or replay it.

```bash
cd /home/scripts/rescue            # in the container, API keys loaded, ollama running
python3 make_rescue.py --list                    # presets and what is recorded
python3 make_rescue.py --preset tutorial         # every run shown in the tutorial (1-2 hours)
python3 make_rescue.py --preset quick            # one run per part
python3 make_rescue.py --part 2 --run 2b_multi_agent --design p8.yaml      # a single run
python3 make_rescue.py --part 1 --task google_iterative --design enc_bin2gray
```

The presets are in `presets.yaml`: edit them to match what you will show. Every run uses the
part's `solution/` folder (the golden prompts). Add `variant: problem` to record a baseline run with
the minimal prompts.

Each recorded run goes to `runs/<id>/`:

| File | Content |
|---|---|
| `console.log` | The console output, with colours |
| `console.timing` | When each line appeared (for the replay) |
| `meta.json` | Command, date, git commit, duration, exit code, status, score, tokens |
| `files/` | The run's outputs: log, `token_usage.json`, every iteration, final RTL/TB/SDC/config.mk, layout |

## On the day

```bash
python3 show_rescue.py list                       # what you have: status, score, tokens, time
python3 show_rescue.py show 2b-p8                 # summary, end of the console, final files
python3 show_rescue.py replay 2b-p8               # replays the console with its real timing, 10x faster
python3 show_rescue.py replay 2b-p8 --speed 30 --max-pause 1 --quiet   # looks like a live run
python3 show_rescue.py files 4a-p1                # where the generated Agent.md files and the layout are
```

`<id>` can be any unique part of the name, e.g. `2b-p8` or `part4`.

Good practice:
- Record a few days before, with the final version of the repository. `meta.json` keeps the git
  commit, so you can see when a recording is stale.
- Copy `runs/` to a USB stick as well. Recorded runs are not git-ignored: commit them only if you
  want attendees to have them (the `.odb` layouts make the repository larger).
- The golden layouts from `reference/make_reference.py --keep-layout` are a second safety net:
  known-good results without any LLM.
