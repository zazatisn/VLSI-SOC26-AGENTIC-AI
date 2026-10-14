---
name: MIPROv2Teacher
version: 1.0.0
---

<!--
The MIPROv2 teacher (prompt model) has no prompt of its own: DSPy MIPROv2 writes the
instructions it sends to the teacher. Only configs/mipro_teacher/config.yaml is used,
and only when "mipro_teacher" is enabled in AGENT_CONFIGS of main.py and
RTL_GEN_DSPY_MODE = "Optimize". This file is kept so every agent folder has the same layout.
-->

# Role and Objective
Teacher model for the MIPROv2 optimization of the RTL Generator. It proposes new
instructions and few-shot demos; the student is the RTL Generator (configs/rtl_generator).
