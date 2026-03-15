clear; clc;

% Configuration
n_mems = 20; noise_strength = 1.0;


for repeat = 1:5
    for N = [1600]
        clearvars -except n_mems noise_strength repeat N 
        Step1_simulation;
    end    
end