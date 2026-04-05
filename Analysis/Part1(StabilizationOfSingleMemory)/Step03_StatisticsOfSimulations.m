% Step03_StatisticsOfSimulations.m
% =========================================================================
% Aggregates distance/similarity matrices across multiple simulations for
% a given network size N and computes convergence statistics.
%
% For each of 4 representation types (spike counts, latency, spike orders
% together, spike orders separate), the script:
%   1. Computes the full trial-by-trial distance matrix D = 1 - corr.
%   2. For every starting trial t0, finds the maximum distance in the
%      bottom-right sub-matrix D(t0:end, t0:end) — a measure of worst-case
%      residual variability after trial t0.
%   3. Overlays these curves for all simulations.
%
% PARAMETERS (set at top of script):
%   N           — network size  
%   lag         — lag for diagonal distance signal
%   scaleFolder — 'Scaled50' or 'Constant50'
%
% INPUTS:
%   Data/{scaleFolder}/N{N}/{simID}/MemoryRepresentations.mat
%
% OUTPUTS:
%   One figure per representation showing max-distance-in-submatrix curves.
% =========================================================================

%% Reading Responses and computing distance matrices

cfg = jsondecode(fileread('config.json'));
lag = cfg.lag;
N = cfg.N;
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

folderPath = fullfile(pwd, "Data", scaleFolder, trialsSubfolder, "N" + num2str(N));
sim_folders = dir(folderPath);
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'}));

nTrials = cfg.nTrials;
signals = zeros(4, length(sim_folders), nTrials-lag);
mats = zeros(4, length(sim_folders), nTrials, nTrials);

for i = 1:length(sim_folders)
    load(fullfile(folderPath, sim_folders(i).name, "MemoryRepresentations.mat"));

    counter = 1;
    for representation = ["spike counts", "latency", "spike orders together", "spike orders separate"]
        if representation.lower == "spike counts"
            data = spike_counts;
            dist_measure = 'correlation';
        elseif representation.lower == "latency"
            data = delays;
            dist_measure = 'correlation';
        elseif representation.lower == "spike orders together"
            data = orders_together;
            data(data == 0) = N + 1;  % non-spiking → tied for last
            dist_measure = 'spearman';
        elseif representation.lower == "spike orders separate"
            data = orders_separate;
            data(data == 0) = N + 1;  % non-spiking → tied for last
            dist_measure = 'spearman';
        end
        corrmat = 1 - squareform(pdist(data, dist_measure));
        mats(counter, i, :, :) = corrmat;
        signals(counter, i, :) = diag(corrmat, lag);
        counter = counter + 1;
    end
end

%% Max distance in bottom-right sub-matrix vs starting trial
% For each simulation and representation, compute how the worst-case
% distance shrinks as we exclude early (pre-convergence) trials.

counter = 1;
for representation = ["spike counts", "latency", "spike orders together", "spike orders separate"]

    D = 1 - mats;      % D(representation, sim, trial_i, trial_j)
    [~, nIter, nTrials, ~] = size(D);

    figure; hold on;
    title(representation + " — max distance in sub-matrix");
    xlabel('Starting trial $t_0$', 'Interpreter', 'latex');
    ylabel('$\max D(t_0{:}end,\, t_0{:}end)$', 'Interpreter', 'latex');

    for iter = 1:min(nIter, 40)
        mat = squeeze(D(counter, iter, :, :));
        y = zeros(1, nTrials);
        for t0 = 1:nTrials
            submat = mat(t0:end, t0:end);
            y(t0) = max(submat, [], 'all');
        end
        plot(y, 'k');
    end

    counter = counter + 1;
end