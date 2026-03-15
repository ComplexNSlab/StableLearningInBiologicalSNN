clc; clear;
% profile on 

for N = [500]
    for N_mems = 2.^(0:10)
        for repeatition = 1:1
                clc; clearvars -except N_mems repeatition N;
                Step1;
                Step2;
        end
    end
end
