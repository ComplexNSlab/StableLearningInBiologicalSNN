clc;clear;
nRepeats = 30;
for i = 1:nRepeats
    clearvars -except nRepeats i
    N = 400; T_noise = 500; T_learning = 100; noise_strength = 1;
    Step1_simulation(N, T_noise, T_learning, noise_strength);
end