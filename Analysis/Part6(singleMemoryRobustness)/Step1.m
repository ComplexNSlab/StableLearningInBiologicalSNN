% This script runs and simulate a network given your customize condition 

clear; clc;
for iter = 1:10
    trialLen = 100;
    nTrials = 1500;
    
    content = load("Data\Scaled50\N400\May_13_2025_15_56_59\config.mat");
    
    net = content.net;
    stim = content.stim;
    net.PatchNumber = iter+1;
    

    subw = net.w(1:net.Ne, 1:net.Ne);
    [rows, cols] = find(subw);
    randId = randperm(length(rows));
    for i = 1:length(rows)
        net.w(rows(i), cols(i)) = subw(rows(randId(i)), cols(randId(i)));
    end

    net.STDP = true;
    net.noise = false;
    
    net.sampling_rate = 5000;
    net.stimulation = true;
    
    net.run(trialLen * nTrials);
end
