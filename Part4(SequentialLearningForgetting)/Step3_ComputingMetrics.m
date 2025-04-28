%% Gathering quantities across all simulations of a type and saving them in a .mat file
clc; clear;

nTrials = 1000;
N = 1600; Ne = floor(0.8*N); Ni = floor(0.2*N);
nMems = 100;

parentFolder = fullfile(pwd, 'Data', "N" + num2str(N), "Trials" + num2str(nTrials));
items = dir(parentFolder);
folderNames = {items([items.isdir]).name};
subfolderNames = folderNames(~ismember(folderNames, {'.', '..'}));

% Computing response times and assembly participation rates
step = 1;

cos_ang = zeros(length(subfolderNames), 21, nMems*nTrials);
cos_ang_consec = zeros(length(subfolderNames), 21, floor( nMems*nTrials/step)-1);
norm_A = zeros(length(subfolderNames), 21,  nMems*nTrials);
participation_ex  = zeros(length(subfolderNames), 21,  nMems*nTrials);
participation_inh = zeros(length(subfolderNames), 21,  nMems*nTrials);

f = waitbar(0, "Calculating ...");
for iter = 1:length(subfolderNames)
    waitbar(iter/length(subfolderNames), f, sprintf("simulation %d/%d being calculated", iter, length(subfolderNames)));
    for memory = 40:60
        load(fullfile(parentFolder, subfolderNames(iter) ,"\Memory" + num2str(memory)  + "Recalls.mat"))
    
    
        sliced_TTFS = TTFS(:, 1: step:end);
        cos_ang_consec(iter, memory-39, :) = sum(sliced_TTFS(:, 1:end-1) .* sliced_TTFS(:, 2:end), 1)./(sqrt(sum(sliced_TTFS(:, 1:end-1).^2, 1)) .*sqrt(sum(sliced_TTFS(:, 2:end).^2)) );
    
        participation_ex(iter, memory-39, :) = sum(TTFS(1:Ne, :) ~= 0, 1);
        participation_inh(iter, memory-39, :) = sum(TTFS(Ne+1:end, :) ~= 0, 1);
    
        norm_A(iter, memory-39, :) = vecnorm(TTFS, 2, 1) ./ sqrt((N - sum(TTFS == 0, 1)));
        cos_ang(iter, memory-39, :) = sum(TTFS .* TTFS(:, memory*nTrials), 1)./(sqrt(sum(TTFS.^2, 1)) *sqrt(sum(TTFS(:, memory*nTrials).^2)) );
    end
end
close(f);

cos_ang(cos_ang > 1) = 1;
angles = 180*acos(cos_ang)/pi;

cos_ang_consec(cos_ang_consec > 1) = 1;
angles_consec = 180*acos(cos_ang_consec)/pi;

clearvars -except cos_ang cos_ang_consec norm_A participation_ex participation_inh angles angles_consec nTrials N Ne Ni nMems;
save(fullfile('Data', "N" + num2str(N), "Trials" + num2str(nTrials), "FinalRepresentations.mat"));