# Design profile (2026-10-10 19:34)

## EDA only (golden design, no LLM)

| design | cells | n | sim | OpenROAD flow (wall) | OpenROAD steps (sum) | metrics | total |
|---|---|---|---|---|---|---|---|
| p11 | 72 | 1 | - | - | 19s ± 0s | - | - |
| p12 | 121 | 1 | - | - | 39s ± 0s | - | - |
| p15 | 156 | 1 | - | - | 23s ± 0s | - | - |
| p13 | 206 | 1 | - | - | 41s ± 0s | - | - |
| p14 | 356 | 1 | - | - | 41s ± 0s | - | - |
| p16 | 319 | 1 | - | - | 38s ± 0s | - | - |

## Agent runs

| run | design | n | success | wall mean ± sd | median | LLM | EDA | OpenROAD runs | tokens mean | score |
|---|---|---|---|---|---|---|---|---|---|---|
| 2a_single_agent | p1 | 1 | 1/1 | 2.1m ± 0s | 2.1m | 64s | 63s | 3.0 | 27k | 91.3 |
| 2b_multi_agent | p1 | 1 | 1/1 | 81s ± 0s | 81s | 37s | 44s | 2.0 | 16k | 90.2 |
| 2b_multi_agent | p8 | 3 | 0/3 | 64s ± 8s | 62s | 56s | 8s | 0.0 | 52k | - |
| 2c_multi_agent_mixed_models | p1 | 3 | 0/3 | 2.1m ± 29s | 115s | 91s | 36s | 0.0 | 15k | - |
| 2d_multi_agent_mixed_models_validators | p1 | 3 | 0/3 | 114s ± 42s | 118s | 108s | 6s | 0.0 | 61k | - |
| 3_multi_agent_collaboration | p5 | 3 | 0/3 | 2.4m ± 42s | 2.7m | 100s | 44s | 0.0 | 57k | - |
| 4a_orchestrator_claude | p1 | 1 | 1/1 | 3.2m ± 0s | 3.2m | 2.3m | 58s | 3.0 | 41k | 91.3 |
| 4a_orchestrator_claude | p14 | 1 | 1/1 | 3.1m ± 0s | 3.1m | 115s | 69s | 1.0 | 48k | 80.7 |

## Average per run config

| run | runs | mean | median | max |
|---|---|---|---|---|
| 2a_single_agent | 1 | 2.1m | 2.1m | 2.1m |
| 2b_multi_agent | 4 | 68s | 67s | 81s |
| 2c_multi_agent_mixed_models | 3 | 2.1m | 115s | 2.7m |
| 2d_multi_agent_mixed_models_validators | 3 | 114s | 118s | 2.6m |
| 3_multi_agent_collaboration | 3 | 2.4m | 2.7m | 2.9m |
| 4a_orchestrator_claude | 2 | 3.2m | 3.2m | 3.2m |

