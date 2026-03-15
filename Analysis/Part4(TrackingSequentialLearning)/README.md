# Part4: Stability of Memories in Sequential Learning

## Description
This part investigates the stability of memories in a sequential learning scheme. We measure how assembly participation rates and normalized neuronal response sizes change before and after memory-specific learning windows.

## Directory Structure
- **Data/**: Contains time-to-first-spike (TTFS) arrays of size (nCells, nTrackingMemories, nTrials).
- **Results/**: Contains generated plots saved as PDF and PNG.
- **Step1_Simulation.m**: Simulates sequential learning of 100 memories and tracks memory recalls.
- **Step2_Organizing.m**: Organizes recall events by memory and saves them into individual `.mat` files.
- **Step3_ComputingMetrics.m**: Computes normalized activity and assembly participation metrics.
- **Step4_GeneratePlots.m**: Loads computed metrics and generates visual plots into the Results folder.

## Execution Order
1. `Step1_Simulation.m` – Simulates sequential learning of 100 memories, periodically tracking recall performance for memories 40 to 60.
2. `Step2_Organizing.m` – Organizes recall events, saving each memory’s recall events into individual `.mat` files.
3. `Step3_ComputingMetrics.m` – Computes assembly participation and normalized activity metrics for each memory recall.
4. `Step4_GeneratePlots.m` – Loads computed metrics and saves corresponding plots into the Results directory.

## Main Results

![Normalized Response Size](Results/norm_A_N400trials1000.png)  
**Figure 1.** Normalized response size of firing cells during memory recall, before and after learning. Network size: 400 neurons.

![Assembly Size](Results/assembly_N400trials1000.png)  
**Figure 2.** Assembly size (participation rate) during memory recall in the sequential learning protocol. Shown before and after the learning window. Network size: 400 neurons.


