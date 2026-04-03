# Part 3: Sequential Classification of Memory Representations

## Description

Trains a heterogeneous Izhikevich spiking network on multiple memories
presented **sequentially**, then tests whether the resulting neural
representations can be distinguished from random activity via partial-cue
recall experiments. Cluster distances (Euclidean, on time-delay features)
and separation scores are computed to quantify how well memories form
distinct representational clusters.

## Directory Structure

```
Part3(ClassificationSequential)/
│
├── Step0.m                              # Batch launcher (loops Step1 + Step2)
├── Step1_Simulation.m                   # Train the network sequentially
├── Step2_Recalls.m                      # Partial-cue recall trials
├── Step2_Recalls_independent_of_Step1.m # Standalone recall runner
├── Step3_ComputeClusterDistances.m      # Pairwise cluster distances
├── Step4_plots.m                        # Aggregate stats + save dictionary
│
├── FigureScripts/                       # Stand-alone plotting scripts
│   ├── analyze_cluster_separation.m     # Per-cluster S_i bar & violin
│   ├── PlotDistancesVsAlpha.m           # Distance curves vs cue strength
│   ├── PlotSeparationVsAlpha.m          # S vs alpha with error bars
│   ├── PlotSeparationVsAlpha_Shaded.m   # Shaded-band version + significance
│   └── SummaryFigure.m                  # Three-panel summary figure
│
├── ThesisFigures/                       # 4 compact thesis-ready figures
│   ├── Fig1_DistanceDistributions.m     # Intra/inter distance KDE curves
│   ├── Fig2_MeanDistancesVsAlpha.m      # Mean distance trends vs alpha
│   ├── Fig3_SeparationScoreVsAlpha.m    # S score + significance stars
│   ├── Fig4_PCA_RecallGeometry.m        # PCA scatter of recall clusters
│   └── Output/                          # Saved PNG + PDF figures
│
├── Simulation_Alternating.m             # Self-contained exploratory pipeline
├── PCAClusters.mlx                      # PCA live-script exploration
├── Test.mlx                             # Misc testing live script
│
├── Data/                                # Simulation output & precomputed data
└── Results/                             # Saved figures & result structs
```

## Simulation Pipeline (execution order)

1. **`Step0.m`** — Outer loop: repeats the full pipeline across multiple
   independent simulations and alpha values.
2. **`Step1_Simulation.m`** — Creates an Izhikevich network (N neurons,
   STDP on, heterogeneity on) and trains it on `N_mems` memories
   presented sequentially. Saves `Patch*.mat` and `stimuli.mat`.
3. **`Step2_Recalls.m`** — Loads the trained network, performs partial-cue
   recall (alpha = fraction of cue presented) for each memory and for
   random control stimuli. Extracts spike-order, spike-count, time-delay,
   and assembly representations. Saves to `Recalls/alpha<X>/`.
   - *`Step2_Recalls_independent_of_Step1.m`* is an alternative entry
     point that scans existing simulation folders so you can add new
     alpha values without re-training.
4. **`Step3_ComputeClusterDistances.m`** — Computes full pairwise
   Euclidean distance matrices on the time-delay representation and
   splits them into intra-/inter-cluster distributions.
   Saves `ClusterDistances.mat`.
5. **`Step4_plots.m`** — Aggregates `ClusterDistances.mat` across
   simulations, produces violin plots and heatmaps, and persists a
   `clusterDictionary` to `clusterDistanceMatrices.mat` (keyed by
   alpha × 100) for downstream figure scripts.

## Figure Scripts (`FigureScripts/`)

All scripts in this folder consume the data produced by the pipeline
above (mainly `clusterDistanceMatrices.mat`). They can be run
independently **after** the pipeline has completed.

| Script | What it plots |
|--------|---------------|
| `analyze_cluster_separation.m` | Bar chart + violin of per-cluster separation score S_i for one alpha |
| `PlotDistancesVsAlpha.m` | Raw & normalized cluster distances vs cue strength |
| `PlotSeparationVsAlpha.m` | Mean S for Memory vs Random clusters vs alpha (error bars) |
| `PlotSeparationVsAlpha_Shaded.m` | Same as above with shaded std bands + Delta-S gap panel |
| `SummaryFigure.m` | Publication-ready 1×3 tiled figure (heatmap, S vs α, ΔS vs α) |

## Key Parameters

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `N` | 400 | Total number of neurons |
| `N_mems` / `nMems` | 25 | Number of sequential memories |
| `nTrials` | 1000 | Training trials per memory |
| `stim_len` | 100 ms | Stimulus duration per trial |
| `alpha` | 0.1–0.9 | Fraction of the cue pattern presented during recall |

## Notes

- The pipeline assumes MATLAB's current directory is this folder
  (`Part3(ClassificationSequential)/`).
- Figure scripts under `FigureScripts/` reference data via `../Data/`
  and save to `../Results/`, so MATLAB's `cd` should point to that
  subfolder when running them.
- `.asv` files are MATLAB auto-save backups and can be safely deleted.

