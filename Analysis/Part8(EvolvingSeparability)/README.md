# Part 8 — Evolving Separability with Partial Cues

Tracks the 21×21 separability matrix of memories 40–60 across sequential
learning of 100 memories, using **partial-cue probing** (α < 1).

## Pipeline

| Step | Script | Description |
|------|--------|-------------|
| 1 | `Step1_Simulation.m` | Learn 100 memories sequentially (STDP on). After each episode, probe memories 40–60 with partial cues (STDP off). Save TTFS per episode. |
| 2 | `Step2_AnalyzeEvolvingSeparability.m` | Load TTFS, compute centroids, intra-cluster spread, and pairwise distance matrices. Separate S into learned-vs-learned and learned-vs-unlearned components. Plot aligned curves and heatmap snapshots. |

## Key Parameters
- `alpha` — cue fraction (default 0.5). Learning always uses α=1.
- `n_trials_probe` — probe trials per memory per episode (default 100).
- Tracked memories: 40–60 (21 total), learned at episodes 40–60.

## Expected Results
- **Pre-learning:** Partial cue → noisy response → low S (≈ 1, overlap).
- **At onset:** STDP-encoded pattern → structured completion → S jumps.
- **Post-learning:** S vs unlearned stays high (easy to distinguish from noise); S vs learned may decay if representations interfere.
