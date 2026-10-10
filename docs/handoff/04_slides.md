# 04 — The tutorial deck

## Versions

- Latest: `VLSI-SoC_Agentic_AI_Tutorial3_3.pptx` (81 slides). The owner reviews with PowerPoint comments;
  every comment must be addressed, then the comments are removed from the file.
- History: 3_1 (owner) → 3_2 (program, ICLAD slide, single/multi-agent titles, check_designs slide) →
  3_3 (owner's comments: scoring slide, knobs slide, loops-in-scripts slide, lessons slide, open challenges).
- Hidden slides (kept for reference, not shown): 12 Terminal survival kit, 13 What runs where, 16 Switching models.

## Structure (v3_3)

1 title · 2 program · 3–36 Part 1 (setup 9–22, sentiment 23–28, ICLAD testbench 29–35, quick fixes 36) ·
37–55 Part 2 (decomposition, LLM vs SLM, four runs, Spec2Tapeout, **47 scoring vs golden run**, 48 designs,
49 run 2a, **51 the knobs**, 52 runs 2b/2c, log reading, follow-along 2.2, 55 check_designs) ·
56–68 Part 3 (FPU loop, custom EDA tools, two loops, **65 loops in the scripts**, hands-on) ·
69–78 Part 4 (planner, orchestrator, hands-on, guarantees, what went wrong, **78 what we learned**) ·
79–80 Part 5 (open challenges with one-line explanations) · 81 thank you.

## Look and conventions

- 4:3, 10 × 7.5 in. Top navy bar, bottom red bar, title top-left (navy `17365D`), `PART n` tag top-right in red,
  slide number bottom-right. Font Calibri.
- Palette: navy `0E2745`, red `B91F2D`, light box `F3F6FA`, light blue `E6EEF7`, border `4F81BD`, grey `5D6C7B`,
  pink `FBE9EB`, green `2E7D4F`, amber `C27C0E`, terminal `1E1E1E` with green comments `7EC699`.
- Patterns: dark terminal boxes for commands (exact, runnable paths under `/home/scripts/...`); "Follow along"
  slides = numbered step rows + command + green CHECKPOINT bar; pink box = warning/"why"; navy bar = hands-on.
- Speaker notes on every slide: plain explanation, `SAY:` / `DO:` cues where useful, and a last line
  `TIME: n minutes`. Notes must match the slide (they drifted once — re-map after inserting slides).

## Content rules from the owner

- Follow-along style "for dummies": every step concrete, every term explained once.
- "Single agent" (run 2a), "multi-agent" (2b), "hybrid" (2c), validators (2d). Never "single shot".
- No ICLAD history/statistics; keep only what the audience needs to run and understand the flows.
- Scores are always "vs our golden run". The orchestrator must be a strong reasoning, big-context model.
- Lessons to keep: prompt refinement beats raw reasoning for small tasks; decompose big tasks; an expert
  writes the Agent.md; "if you can understand it in the log by hand, write it in the Agent.md".

## How we edit the deck (reproducible)

1. Unzip the .pptx; edit slide XML directly (helpers: `box`, `P`, `terminal`, `arrow`, `circle_num`, `card`,
   `new_slide`/`blank_from` keep bars, title, PART tag and number).
2. New slides: pptx skill `add_slide.py <dir> slideN.xml --after slideN.xml`, then create a notesSlide for it.
3. Remove comments when done: `ppt/comments/`, comment relationships, `p188:commentRel` ext entries,
   content-type overrides and `ppt/authors.xml`.
4. `clean.py`, zip, `validate.py` must pass.
5. Render to check: un-hide slides in a copy (`show="0"`), `soffice --convert-to pdf`, `pdftoppm`, look at
   every changed slide (hidden slides otherwise shift the PDF page numbers).
