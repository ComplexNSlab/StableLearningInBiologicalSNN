# Part 1: Stabilisation of a Single Memory

## Description

Trains a single memory on an Izhikevich spiking neural network and measures how the network's response (memory representation) converges over repeated training trials. Representations are measured in four forms: **time delay** (first spike timing), **spike count**, **assembly participation**, and **spike order**.

## Research Questions

- How many training trials does it take for a single memory to stabilise?
- Does the stabilisation time differ across representation types?
- How does it scale with network size N?
- Does structural (synaptic weight) stabilisation precede or follow functional (representation) stabilisation?

## Pipeline

| Script | Purpose |
|--------|---------|
| `Step00.m` | Batch launcher — loops over network sizes and repetitions, calling Step01 each time. |
| `Step01_Simulation.m` | Core simulation — creates an Izhikevich network, trains it, computes 4 representations. |
| `Step02_ConvergenceOfSingleMemory.m` | Single-simulation visualisation — spike order vs trial, similarity heatmap, consecutive distance. |
| `Step03_StatisticsOfSimulations.m` | Multi-simulation aggregate — max-distance-in-submatrix curves across runs. |
| `Step04_PlateauThreshold.m` | **[Preferred]** Plateau-based stabilisation detection for delays and spike counts (all N). |
| `Step04_SlopeThreshold.m` | *(Superseded)* Slope-threshold method for a single N. Kept for reproducibility. |
| `Step05_PlateauBoxplot.m` | **[Preferred]** Grouped boxplot of plateau-based stabilisation times vs N. |
| `Step05_SlopeBoxplot.m` | *(Superseded)* Slope-based boxplot. Kept for reproducibility. |
| `Step06_WeightStabilization.m` | Structural (synaptic weight) stabilisation analysis — plateau criterion on L1 delta-W. |
| `Step07_WeightStabilizationPlots.m` | Visualisation of L1 weight stabilisation results (traces, boxplots, trends). |
| `Step08_WeightVsRepresentationComparison.m` | Paired comparison of structural vs functional stabilisation times. |
| `Step09_RadialStabilization.m` | Radial (polar-decomposition) stabilisation — threshold on \|Δr\| → 0. Also stores Δθ. |
| `Step10_RadialStabilizationPlots.m` | Visualisation of radial stabilisation results (Δr/Δθ traces, boxplots, trends). |
| `Step11_RadialVsRepresentationComparison.m` | Paired comparison of radial vs functional stabilisation times. |

## Configuration

Parameters are read from `config.json` (git-ignored). Copy `config.default.json` to `config.json` and edit:

| Key | Description |
|-----|-------------|
| `N` | Default network size for single-N scripts (Step02, Step03, Step04) |
| `networkSizes` | List of N values for batch runs (Step00) |
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
Results/StabilizationResults/
    DelaysThreshold_plateau_{paramTag}.mat         — from Step04
    SpikeCountsThreshold_plateau_{paramTag}.mat    — from Step04
    WeightStabilityResults_{paramTag}.mat           — from Step06
    RadialStabilityResults_{paramTag}.mat           — from Step09
```

where `{paramTag}` = `frac{NNN}_smooth{S}_hold{H}` (e.g. `frac010_smooth100_hold100`).

