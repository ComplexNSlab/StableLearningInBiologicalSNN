%% Orginizing recalls of each memories in a separate file

clear; clc;
%%%%%%% parameters to be set %%%%%%%%%%%%
N = 100;
nMems = 100;
nTrials = 1000;
scale50 = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

folderPath = fullfile(pwd, 'Data', 'Scaled50', "N" + num2str(N));
items = dir(folderPath);
folderNames = {items([items.isdir]).name};
subfolderNames = folderNames(~ismember(folderNames, {'.', '..'}));

for iter = 1:length(subfolderNames)
    fprintf("Organizing Simluation : " + subfolderNames{iter} + "\n");
    


    f = waitbar(0, "Please wait");
    for selected_mem = 1:21
        if exist(fullfile(folderPath, subfolderNames{iter}, sprintf("Memory%dRecalls.mat", selected_mem+39)), "file")
            continue;
        end
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

