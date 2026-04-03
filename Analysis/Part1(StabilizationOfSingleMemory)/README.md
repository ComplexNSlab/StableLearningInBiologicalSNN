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
| `Step0.m` | Batch launcher — loops over network sizes and repetitions, calling Step1 each time. |
| `Step1_Simulation.m` | Core simulation — creates an Izhikevich network, trains it, computes 4 representations. |
| `Step2_ConvergenceOfSingleMemory.m` | Single-simulation visualisation — spike order vs trial, similarity heatmap, consecutive distance. |
| `Step3_StatisticsOfSimulations.m` | Multi-simulation aggregate — max-distance-in-submatrix curves across runs. |
| `Step4_PlateauThreshold.m` | **[Preferred]** Plateau-based stabilisation detection for delays and spike counts (all N). |
| `Step4_SlopeThreshold.m` | *(Superseded)* Slope-threshold method for a single N. Kept for reproducibility. |
| `Step5_PlateauBoxplot.m` | **[Preferred]** Grouped boxplot of plateau-based stabilisation times vs N. |
| `Step5_SlopeBoxplot.m` | *(Superseded)* Slope-based boxplot. Kept for reproducibility. |
| `Step6_WeightStabilization.m` | Structural (synaptic weight) stabilisation analysis — plateau criterion on delta-W. |
| `Step7_WeightStabilizationPlots.m` | Visualisation of weight stabilisation results (traces, boxplots, trends). |
| `Step8_WeightVsRepresentationComparison.m` | Paired comparison of structural vs functional stabilisation times. |

## Configuration

Parameters are read from `config.json` (git-ignored). Copy `config.default.json` to `config.json` and edit:

| Key | Description |
|-----|-------------|
| `N` | Default network size for single-N scripts (Step2, Step3, Step4) |
| `networkSizes` | List of N values for batch runs (Step0) |
| `nTrials` | Number of training trials per simulation |
| `trialLen` | Duration of each trial (ms) |
| `scale50Flag` | Scale stimulus size with N (`true`) or keep fixed (`false`) |
| `scaleFolder` | Data subdirectory: `"Scaled50"` or `"Constant50"` |
| `trialsSubfolder` | Subfolder for trial-count variants, e.g. `"Trials1500"`, `"Trials1000"`, or `""` |
| `iterationsPerN` | Repeat simulations per N in Step0 |
| `lag` | Lag for diagonal distance signal in Step3 |

## Data Layout

```
Data/{scaleFolder}/{trialsSubfolder}/N{N}/{simID}/
    Patch1.mat                  — network object + weight snapshots
    MemoryRepresentations.mat   — orders_together, orders_separate, spike_counts, delays
```

