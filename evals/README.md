# Activation evals

Eleven prompts that check when the skill activates: six that should use it and five that shouldn't. Each case passes a run when the `Skill` tool was (or wasn't) called with `liquid-glass`, so a case's score is its trigger rate.

```sh
claude plugin eval . --ablation none --model claude-sonnet-5-5 --threshold 0 --no-publish
```

`plugin eval` needs Claude Code 2.1.269 or later. `--ablation none` skips the no-plugin arm, which can't call the skill anyway. Runs stop after two turns to keep them cheap, so "Reached maximum number of turns" in the report is expected; the skill call happens in the first turn.

Results for the final 2.0.0 description, Sonnet 5.5, five runs per case (October 2026): all six positive prompts used the skill every time, and the five negative prompts, one of them about web glassmorphism, never did. An earlier description missed the design question in `t3-cards-glass-or-solid` (asked then without "iPhone"): 0 of 5.
