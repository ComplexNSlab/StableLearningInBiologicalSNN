clear; clc;
% finding all subfolders in data_alternate 
parentFolder = fullfile(pwd, "Data", "N400");  % Replace with your path
subfolders = dir(parentFolder);
subfolders = subfolders([subfolders.isdir]);  % Keep only directories
subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'}));  % Remove . and ..
subfolderNames = {subfolders.name};

% for loop over all simulations to recall memories at the end and saving them
% fff = waitbar(0, "Please wait ...");
% parpool;

for iii = 7 % for on different number of memories folders
    clearvars -except iii subfolderNames parentFolder 
    N_mems = str2num(strrep(subfolderNames{iii}, "memories", ''));

    subfolders = dir(parentFolder + filesep + string(subfolderNames{iii}));
    subfolders = subfolders([subfolders.isdir]);
    subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'})); 

    for jjj = 3 % for on different simulations within a given n_mems 
        sprintf("Folder: %dmemories, %d out of %d sims \n Simulation: %s", N_mems, jjj, length(subfolders), strrep(string(subfolders(jjj).name), '_', '-'))

        clearvars -except iii jjj subfolderNames subfolders parentFolder N_mems
        N = 400;
        content = load(string(subfolders(jjj).folder) + filesep + string(subfolders(jjj).name) + filesep + "Patch" + num2str(N_mems) + ".mat", 'obj');
        net = content.obj;
        stims = net.stims;

        Step2;
    end
end
% close(fff)
% delete(gcp);