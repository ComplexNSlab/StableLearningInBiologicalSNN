% Step2_Recalls_independent_of_Step1.m
%
% Standalone version of Step2_Recalls that does not require Step0/Step1 to
% be in the current workspace. It scans all simulation sub-folders under
% Data/N<N>/nMems<N_mems>/, loads the final network state (last patch
% file) and the saved stimuli, then runs partial-cue recalls for each
% alpha in alpha_array.  Already-computed alpha folders are skipped.
%
% Useful for running additional recall experiments on previously trained
% networks without re-training.
%
% Depends on: Step2_Recalls.m (called as a script)
% Parameters: N, N_mems, alpha_array (set below)

%% Parameters
clc; clear;

N = 400;             % network size
N_mems = 25;
alpha_array = [0.1];
nTrials  = 1000;     % training trials per memory (needed by Step2_Recalls)
stim_len = 100;      % stimulus length in ms      (needed by Step2_Recalls)

baseFolder = fullfile(pwd, 'Data', sprintf('N%d', N), sprintf('nMems%d', N_mems));

entries = dir(baseFolder);
entries = entries([entries.isdir]);
entries = entries(~ismember({entries.name}, {'.', '..'}));

for sim_id = 1:numel(entries)
    % remove variables from previous iteration, keep only important ones
    clearvars -except N N_mems baseFolder entries sim_id alpha_array nTrials stim_len
    
    simFolder = fullfile(baseFolder, entries(sim_id).name);
    recallsFolder = fullfile(simFolder, 'Recalls');

    fprintf('\nProcessing simulation folder %d/%d: %s\n', ...
        sim_id, numel(entries), entries(sim_id).name);

    % load only the last patch file
    patchFile = fullfile(simFolder, sprintf('Patch%d.mat', N_mems));
    stimsFile = fullfile(simFolder, sprintf('stimuli.mat'));

    if ~isfile(patchFile)
        fprintf('  Missing file: %s\n', patchFile);
        continue;
    end

    S = load(patchFile, 'obj');
    net = S.obj;
    stims = load(stimsFile, 'stims');
    stims = stims.stims;
    
    for alpha = alpha_array
        
        alphaFolderName = sprintf('alpha%d', round(alpha * 100));
        alphaFolder = fullfile(recallsFolder, alphaFolderName);

        % skip if this alpha folder already exists
        if isfolder(alphaFolder)
            fprintf('  Skipping alpha=%.1f because folder exists: %s\n', alpha, alphaFolderName);
            continue;
        end

        fprintf('  Running alpha=%.1f\n', alpha);

        % variables available for Step2_Recalls if it is a script:
        % net, alpha, simFolder, recallsFolder, sim_id, N, N_mems, ...
        Step2_Recalls;
    end
end
