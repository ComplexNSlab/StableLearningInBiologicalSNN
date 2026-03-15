% Step0.m  --  Batch launcher for the sequential-learning pipeline.
%
% Runs Step1_Simulation followed by Step2_Recalls for a grid of alpha
% values, repeating the entire procedure over multiple independent
% simulation iterations (default: 10). Each iteration:
%   1. Sets network size (N), number of memories (N_mems), trial count,
%      and stimulus length.
%   2. Calls Step1_Simulation to train the network sequentially.
%   3. Loops over the specified alpha values and calls Step2_Recalls to
%      perform partial-cue recall tests.
%
% Depends on: Step1_Simulation.m, Step2_Recalls.m
% Parameters: N, nTrials, stim_len, N_mems, alpha values (set below)

for simulation_iter = 1:10   
    clc; clearvars -except simulation_iter;

    N = 400; %networkSize
    nTrials = 1000;
    stim_len = 100;
    N_mems = 50;
    Step1_Simulation;
    for alpha = [0.1, 0.3, 0.5, 0.7, 0.9]
        Step2_Recalls;
    end
end
