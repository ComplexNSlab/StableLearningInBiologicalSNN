%% Orginizing recalls of each memories in a separate file

clear; clc;
nTrials = 1000;
N = 100;
nMems = 100;

folderPath = fullfile(pwd, 'Data', 'Scaled50', "N" + num2str(N));
items = dir(folderPath);
folderNames = {items([items.isdir]).name};
subfolderNames = folderNames(~ismember(folderNames, {'.', '..'}));

for iter = 1:length(subfolderNames)
    fprintf("Organizing Simluation : " + subfolderNames{iter} + "\n");

    f = waitbar(0, "Please wait");
    for selected_mem = 1:21
        TTFS = zeros(N, nTrials*100);
        for i = 1:nMems
            waitbar(((selected_mem-1)*nMems + i)/2100, f, sprintf("retreiving memory %d/21, while learning memory %d/100", selected_mem, i));
            load(fullfile(folderPath, subfolderNames{iter}, "ttfs_mem" + num2str(i) + ".mat"), "ttfs");
            TTFS(:, (i-1)*nTrials+1:i*nTrials) = mod(squeeze(ttfs(:, selected_mem, :)), 100);
        end
        save(fullfile(folderPath, subfolderNames{iter}, "Memory" + num2str(39+selected_mem) + "Recalls.mat"), "TTFS", '-mat');
    end
    close(f)
end

