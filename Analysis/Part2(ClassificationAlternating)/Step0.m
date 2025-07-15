clc; clear;
% profile on 

for N = [100]
    for N_mems = [3]
        for repeatition = 1:1
                clc; clearvars -except N_mems repeatition N;
                Step1;
                Step2;
        end
    end
end
