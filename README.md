# Izhikevich Neural Network Memory Retrieval Project

This repository contains a modular MATLAB-based project that simulates and analyzes memory retrieval in spiking neural networks using the Izhikevich neuron model. The project is organized into four main parts, each representing a stage in the analysis pipeline, from stability testing to activity normalization.

---

## 📁 Project Structure

```text
Part1(StabilizationOfSingleMemory)
│   └── Simulates the stabilization of individual memories in the network.
│
Part2(RetrievalsAccuracyAlternate)
│   └── Measures retrieval accuracy for alternative memory cues.
│
Part3(RetrievalsAccuracySequential)
│   └── Simulates sequential memory recall and analyzes retrieval order.
│
Part4(AssemblyNormActivityPlotting)
│   └── Normalized activity plots and metrics across memory assemblies.
│
Src/
│   └── Core implementation files: Izhikevich model, stimulation setup, etc.
