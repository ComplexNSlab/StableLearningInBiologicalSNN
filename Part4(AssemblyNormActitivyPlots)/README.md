# PartX: [Short Title of This Part]

## Description
Briefly describe what this part does in 2–3 sentences.

## Directory Structure
- **Data/**: [Time to first spike of neurons in ttfs array of size (nCells, nTrackingMemories, nTrials)]
- **Results/**: [Results saved in both PDF and PNG]
- **Step1_Simulation.m**: [Explain the purpose of the first step.]
- **Step2_Organizinge.m**: ...
- **...**

## Execution Order
1. `Step1_Simulation.m` – [Runs a network to learn 100 memories sequentially and in between track recalls of memories 40 to 60 during the whole process.]
2. `Step2_Organizing.m` – [Gathers and separate each memories recalls into a single "MemoryNRecalls.mat" file.]
3. `Step3_ComputingMetrics.m` – [Compute the assembly and normalized activity measures and save as "FinalRepresentaions.mat" within each simulation.]
4. `Step4_GeneratePlots.m` - [Loads the "FinalRepresentations.mat" and save the related plots in Results folder.]

## Main Results

![Normalized Response Size](Results/norm_A_N400trials1000.png)  
**Figure 1.** Normalized response size of firing cells during memory recall, before and after learning. Network size: 400 neurons.

![Assembly Size](Results/assembly_N400trials1000.png)  
**Figure 2.** Assembly size (participation rate) during memory recall in the sequential learning protocol. Shown before and after the learning window. Network size: 400 neurons.


## Notes
- Any specific settings, dependencies, or expected input formats.
- Any assumptions or critical points to check before running.

