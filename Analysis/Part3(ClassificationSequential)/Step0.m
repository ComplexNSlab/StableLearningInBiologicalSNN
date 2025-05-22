for simulation_iter = 1:5    
    clc; clearvars -except simulation_iter;

    N = 400; %networkSize
    nTrials = 1000;
    stim_len = 100;
    N_mems = 25;
    Step1_Simulation;
    for alpha = [30, 50, 70, 90]
        Step2_Recalls;
    end
end
