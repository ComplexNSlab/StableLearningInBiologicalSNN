# Part 1: Stabilisation of a Single Memory

## Description

Trains a single memory on an Izhikevich spiking neural network and measures how the network's response (memory representation) converges over repeated training trials. Representations are measured in four forms: **first-spike latency**, **first-spike order**, **spike count**, and **filtered raster image**.

## Research Questions

- How many training trials does it take for a single memory to stabilise?
- Does the stabilisation time differ across representation types?
- How does it scale with network size N?
- Does structural (synaptic weight) stabilisation precede or follow functional (representation) stabilisation?

## Pipeline

| Script | Purpose | Thesis figure |
|--------|---------|---------------|
| `Step00.m` | Batch launcher — loops over network sizes and repetitions, calling Step01 each time. | — |
| `Step01_Simulation.m` | Core simulation — creates an Izhikevich network, trains it, computes 4 representations. | — |
| `Step02_ConvergenceOfSingleMemory.m` | Single-simulation visualisation — spike order vs trial, similarity heatmap, consecutive distance, and a 3-panel convergence comparison (latency / spike count / spike-order ρ). | Fig 4.1 (spike order), `ConvergenceCurves.pdf` |
| `Step03_StatisticsOfSimulations.m` | Multi-simulation diagnostic — sub-matrix max-distance curves across runs for all 4 representations. Not used in thesis; kept as a robustness check. | — |
| `Step04_PlateauThreshold.m` | **[Preferred]** Plateau-based stabilisation detection for latency, spike count, and spike order (all N). Saves per-run convergence curves for representative N. | — (data only) |
| `Step04b_ConvergencePlot.m` | Plots multi-simulation convergence trajectories (median + 80% CI, 3 panels). Loads curves saved by Step04. | Fig 4.2 (convergence trajectories) |
| `Step04_SlopeThreshold.m` | *(Superseded)* Slope-threshold method. Kept for reproducibility. | — |
| `Step05_PlateauBoxplot.m` | **[Preferred]** Grouped boxplot of plateau-based stabilisation times vs N (3 representations: latency, spike count, spike order). | Fig 4.3 (stabilisation boxplot) |
| `Step05_SlopeBoxplot.m` | *(Superseded)* Slope-based boxplot. Kept for reproducibility. | — |
| `Step06_WeightStabilization.m` | Structural (synaptic weight) stabilisation analysis — plateau criterion on L1 ΔW. | — (data only) |
| `Step07_WeightStabilizationPlots.m` | Visualisation of L1 weight stabilisation results (single-run trace, boxplots across N). | Fig 4.4 (ΔW trajectory), Fig 4.5 (structural boxplot) |
| `Step08_WeightVsRepresentationComparison.m` | Paired comparison: structural vs functional stabilisation times. | Fig 4.6 (paired difference) |
| `Step09_RadialStabilization.m` | Radial (polar-decomposition) stabilisation — threshold on ‖Δr‖→0. Also stores Δθ. | — (data only) |
| `Step10_RadialStabilizationPlots.m` | Visualisation of radial stabilisation results (Δr/Δθ traces, boxplots, trends). | — (exploratory) |
| `Step11_RadialVsRepresentationComparison.m` | Paired comparison of radial vs functional stabilisation times. | — (exploratory) |

### Non-spiking neuron conventions

| Representation | Non-spiking value | Rationale |
|---|---|---|
| First-spike latency | Excluded (`NaN`) | Mean latency reflects only active neurons |
| First-spike order | $N+1$ (tied for last) | Non-spiking neurons ranked below all spiking neurons |
| Spike count | 0 | Naturally correct |

## Configuration

Parameters are read from `config.json` (git-ignored). Copy `config.default.json` to `config.json` and edit:

| Key | Description |
|-----|-------------|
| `N` | Default network size for single-N scripts (Step02, Step03) |
| `networkSizes` | List of N values for batch runs (Step00, Step04, Step05) |
| `nTrials` | Number of training trials per simulation |
| `trialLen` | Duration of each trial (ms) |
| `scale50Flag` | Scale stimulus size with N (`true`) or keep fixed (`false`) |
| `scaleFolder` | Data subdirectory: `"Scaled50"` or `"Constant50"` |
| `trialsSubfolder` | Subfolder for trial-count variants, e.g. `"Trials1500"`, `"Trials1000"`, or `""` |
| `iterationsPerN` | Repeat simulations per N in Step00 |
| `lag` | Lag for diagonal distance signal in Step03 |
| `stabilityFrac` | Fractional threshold (α) for plateau-based stabilisation detection |
| `smoothTrials` | Smoothing window in actual trials for stabilisation detection |
| `holdTrials` | Consecutive-hold window in actual trials |

## Data Layout

```
Data/{scaleFolder}/{trialsSubfolder}/N{N}/{simID}/
    Patch1.mat                  — network object + weight snapshots
    MemoryRepresentations.mat   — orders_together, orders_separate, spike_counts, delays
```

## Results Layout

Analysis outputs are saved in a parameter-stamped subfolder so different configs don't overwrite each other:

```
Results/
    ConvergenceCurves.pdf/.png                          — from Step02 (single-sim 3-panel)
    SpikeOrderSeparate.pdf/.png                         — from Step02
    SpikeOrderTogether.pdf/.png                         — from Step02
    StabilizationResults/{paramTag}/
        DelaysThreshold_plateau.mat                     — from Step04
        SpikeCountsThreshold_plateau.mat                — from Step04
        SpikeOrderThreshold_plateau.mat                 — from Step04
        ConvergenceTrajectories.pdf/.png                — from Step04 (multi-sim median+CI)
        Step05_RepresentationalStabilization_Plateau.*  — from Step05
        Step07_DeltaW_SingleRun.pdf                     — from Step07
        Step07_StructuralStabilization.*                — from Step07
        Step08_StructuralVsRepresentational_Diff.*      — from Step08
        WeightStabilityResults.mat                      — from Step06
        RadialStabilityResults.mat                      — from Step09
```

where `{paramTag}` = `frac{NNN}_smooth{S}_hold{H}` (e.g. `frac010_smooth100_hold100`).

