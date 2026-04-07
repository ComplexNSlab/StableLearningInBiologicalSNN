%% Step0_BatchRun.m — Part 8: Batch launcher
%
% Runs Step1_Simulation repeatedly to produce independent simulation
% instances. Each iteration creates a new random network, trains 100
% memories sequentially, and probes with all alphas + null patterns.
%
% Set n_iterations to the number of independent simulations you want.
% Safe to leave running overnight — each iteration prints progress.
%
% Depends on: Step1_Simulation.m (in same folder)

n_iterations = 10;

for simulation_iter = 1:n_iterations
    fprintf("\n========================================\n");
    fprintf("  BATCH RUN: Iteration %d / %d\n", simulation_iter, n_iterations);
    fprintf("========================================\n\n");

    clearvars -except simulation_iter n_iterations;

    Step1_Simulation;

    fprintf("\n  Iteration %d complete.\n", simulation_iter);
end

fprintf("\n========================================\n");
fprintf("  ALL %d ITERATIONS COMPLETE.\n", n_iterations);
fprintf("========================================\n");
