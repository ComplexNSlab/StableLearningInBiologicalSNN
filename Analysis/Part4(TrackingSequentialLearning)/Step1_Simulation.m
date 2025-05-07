%% Tracking 21 Memories Before and After Learning While Learning 100 Memories in Total
% clear; clc;
profile on; 

%%%%%%%%%% User-Defined Parameters %%%%%%%%%%
N = 100;                % Total number of neurons in the network
n_mems = 100;           % Number of memories to learn sequentially
n_trials = 1000;        % Number of learning trials per memory
scale50 = true;         % Whether to scale number of stimulated cells with N
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set number of cells and output folder based on scaling mode
if scale50
    scaleFolder = 'Scaled50';
    nCells = round(50 * N / 400);  % Scale 50 cells linearly with network size
else
    scaleFolder = 'constant50';
    nCells = 50;                   % Fixed 50 cells for stimulation
end

% Define the path to the data folder
baseFolder = fullfile("Data", scaleFolder, "N" + num2str(N));

% Initialize the Izhikevich neural network
net = IzhikevichNetwork(N, ...
    'heterogeneity', true, ...
    'g_ee', 0.5, ...
    'g_ei', 2, ...
    'g_ie', 2, ...
    'ExtoExDegree', 20, ...
    'InhtoExDegree', 5, ...
    'ExtoInhDegree', 5, ...
    'baseFolder', baseFolder);

% Set network simulation options
net.STDP = true;
net.stimulation = true;
net.sampling = false;
net.sampling_rate = 1000;
net.saveSimulation = false;

%% Generate Stimulation Protocols for All Memories
stims = [];
for m = 1:n_mems
    stims = [stims, Stimulation(net, 100, 2, 30, nCells, 5)];
end

% Save stimulation objects for future reference
save(net.RecordingDirectory + filesep + "Stims.mat", "stims", '-mat');

%% Simulation Loop: Learn One Memory at a Time and Probe 21 Memories
f = waitbar(0, "Please wait ...");
f.Position(1:2) = [100, 100];

for m = 1:n_mems
    ttfs = zeros(N, 21, n_trials);  % Time-to-first-spike storage

    for trial = 1:n_trials
        waitbar((m - 1) / n_mems, f, ...
            sprintf("Learning memory %d/%d Trial %d/%d", m, n_mems, trial, n_trials));

        % --- Learning Phase ---
        net.STDP = true;
        net.stims = stims(m);
        net.run(100);  % Run learning step

        % % --- Probing Phase (21 Memories: #40 to #60) ---
        % net.STDP = false;
        % for mem = 40:60
        %     net.stims = stims(mem);
        %     net.run(100);
        % 
        %     % Record time to first spike (TTFS) for each neuron
        %     for cell = unique(net.firings(:, 2))'
        %         index = find(net.firings(:, 2) == cell, 1);  % First spike index
        %         if ~isempty(index)
        %             ttfs(cell, mem - 39, trial) = net.firings(index, 1);
        %         end
        %     end
        % end
    end

    % Save TTFS results for this memory
    save(net.RecordingDirectory + filesep + sprintf("ttfs_mem%d.mat", m), '-mat', "net", "ttfs");
end

close(f);
