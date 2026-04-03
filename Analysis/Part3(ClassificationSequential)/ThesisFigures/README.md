# ThesisFigures/

Compact, publication-ready figures summarizing the geometry of memory recall
representations. These replace the 20+ exploratory plots from `FigureScripts/`
with 4 focused figures suitable for a thesis results section.

## Figures

| Script | Figure | What it shows |
|--------|--------|---------------|
| `Fig1_DistanceDistributions.m` | Intra & inter distance distributions | KDE curves for all alpha values, separated by group type |
| `Fig2_MeanDistancesVsAlpha.m` | Mean distances vs alpha | 5 distance curves (intra-mem, intra-rnd, inter m-m, m-rnd, rnd-rnd) with SEM bands |
| `Fig3_SeparationScoreVsAlpha.m` | Separation score vs alpha | S_memory vs S_random with SEM bands and Wilcoxon significance stars |
| `Fig4_PCA_RecallGeometry.m` | PCA projection of recalls | 2D scatter showing memory clusters in PC space |

## How to run

1. Set MATLAB's current directory to `Part3(ClassificationSequential)/`
2. Run any `Fig*.m` script — each is self-contained
3. Output saved to `ThesisFigures/Output/` as both PNG (600 DPI) and PDF

## Data dependencies

All scripts load from `Data/N400/nMems25/`:
- **Fig1, Fig2**: `ClusterDistances.mat` per simulation per alpha (from Step3)
- **Fig3**: `clusterDistanceMatrices.mat` aggregated dictionary (from Step4)
- **Fig4**: `recalls25.mat` raw trial data (from Step2)
