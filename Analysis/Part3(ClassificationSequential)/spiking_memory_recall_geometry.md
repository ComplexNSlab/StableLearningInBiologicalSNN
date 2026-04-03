
# Spiking Network Memory Recall Geometry

## Goal
Write a **thesis results section** and produce **compact figures** summarizing the geometry of memory recall representations.

---

# 1. Scientific Interpretation of the Analysis

The study investigates the **geometry of recall representations** in neural state space.

Each memory recall produces a neural activity vector

r_i ∈ R^400

Distance between recalls is defined as the Euclidean distance

D_ij = || r_i - r_j ||_2

Three quantities are analyzed:

- Intra-cluster distances
- Inter-cluster distances
- Separation score S

---

# 2. Intra-Cluster Distance

Distance between recalls of the **same memory**

D_intra = mean(D_ij),  i,j ∈ same memory

### Interpretation

Represents **recall stability**.

Small intra distances mean the network produces **consistent activity patterns when recalling the same memory**.

---

# 3. Inter-Cluster Distance

Distance between recalls of **different memories**

D_inter = mean(D_ij),  i,j ∈ different memories

### Interpretation

Represents **memory separability**.

Large inter distances mean **different memories occupy distinct regions of neural state space**.

---

# 4. Separation Score

A compact metric for memory separability:

S = (D_inter − D_intra) / D_inter

### Interpretation

| S value | Meaning |
|------|------|
| S ≈ 0 | clusters overlap |
| S ≈ 0.5 | moderate separation |
| S → 1 | strong separation |

---

# 5. Compact Figure Plan

Instead of producing dozens of plots, the results can be summarized with **3–4 strong figures**.

---

## Figure 1 — Distance Distributions

Purpose: show recall geometry.

Panels:

A: intra cluster distribution  
B: inter cluster distribution  

Overlay curves for **all α values**.

Conceptual sketch:

distance  
│  
│    inter  
│      /\  
│     /  \  
│    /    \  
│  
│  intra  
│   /\  
│  /  \  
└────────────────  

Caption idea:

> Distribution of intra-memory and inter-memory recall distances for different α values. Increasing α increases separation between recall clusters.

---

## Figure 2 — Mean Distances vs α

Plot two curves:

- mean intra distance
- mean inter distance

Conceptual sketch:

distance  
│  
│   inter  
│     *  
│    *  
│   *  
│  
│ intra  
│   *  
│  *  
│ *  
└────────────  
  α  

Interpretation:

Separation increases as **α increases**.

---

## Figure 3 — Separation Score vs α

Single curve:

S  
│  
│       *  
│     *  
│   *  
│ *  
└────────────  
  α  

Caption:

> Separation score increases with α, indicating improved cluster structure.

---

## Figure 4 — Geometry Visualization (optional but powerful)

Use:

- PCA
- or MDS

Example geometry:

PCA1  
│  o o o  
│  
│     x x x  
│  
│        + + +  
└──────────────  
       PCA2  

Each color represents a **memory cluster**.

This provides an intuitive visualization of recall structure.

---

# 6. Recommended Total Number of Figures

| Figure | Content |
|------|------|
| Figure 1 | intra vs inter distributions |
| Figure 2 | mean distances vs α |
| Figure 3 | separation score vs α |
| Figure 4 | PCA memory geometry |

Total: **3–4 figures**

This replaces **20+ redundant plots**.

---

# 7. Thesis Results Section Draft

## Geometry of Memory Recall Representations

To quantify how memories are represented in network activity, we analyzed the geometry of recall states in population space. Each recall event produces a neural activity vector r_i ∈ R^N, where N = 400 is the number of neurons. The similarity between recalls was quantified using the Euclidean distance

D_ij = ||r_i − r_j||_2

We computed pairwise distances between recalls belonging to the same memory (intra-cluster distances) and between recalls of different memories (inter-cluster distances).

### Intra- and Inter-Cluster Distances

Figure X compares the distributions of intra- and inter-cluster distances for different values of the learning parameter α. Intra-cluster distances remain relatively small, indicating that repeated recalls of the same memory produce similar neural representations.

In contrast, inter-cluster distances are substantially larger, reflecting separation between representations of different memories.

Increasing α enhances this separation: inter-cluster distances grow while intra-cluster distances remain relatively stable. This suggests that stronger plasticity leads to more distinct memory representations in the network.

### Separation Score

To quantify this effect we define a separation score

S = (D_inter − D_intra) / D_inter

This metric ranges from zero (no cluster separation) to one (perfect separation). As shown in Figure X, the separation score increases monotonically with α, indicating that higher learning rates improve the geometric separation of memory representations.

### Low-Dimensional Visualization

To visualize the geometry of recall states, we projected the activity vectors into a two-dimensional space using principal component analysis. The resulting embedding (Figure X) reveals clear clusters corresponding to individual memories.

These clusters remain distinguishable even when the network is driven by noise, demonstrating that the learned synaptic structure preserves memory-specific activity patterns.

---

# 8. Additional Metric (Recommended)

A useful complementary measure is the **signal-to-noise ratio of recall**:

SNR = D_inter / D_intra

Higher SNR means **stronger memory separation**.
