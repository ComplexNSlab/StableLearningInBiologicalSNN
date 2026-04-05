% Step02_ConvergenceOfSingleMemory.m
% =========================================================================
% Visualises convergence of a single simulation's memory representations.
%
% Loads the latest simulation for a given N and produces:
%   1. Spike order vs trial (excitatory/inhibitory ranked separately)
%      — each neuron is a colored line showing its rank drifting over trials.
%   2. Spike order vs trial (all neurons ranked together).
%   3. Trial-by-trial similarity (Pearson or Spearman) heatmap for a
%      chosen representation (spike counts, latency, or spike orders).
%   4. Mean correlation vs trial.
%   5. Consecutive-trial distance D(t, t+lag) converging to zero.
%
% PARAMETERS (set at top of script):
%   N           — network size to load
%   scaleFolder — 'Scaled50' or 'Constant50'
%
% INPUTS:
%   Data/{scaleFolder}/N{N}/{latestSim}/MemoryRepresentations.mat
%   Data/{scaleFolder}/N{N}/{latestSim}/Patch*.mat  (for net object)
%
% OUTPUTS:
%   Results/  — PDF and PNG of each figure (print calls currently commented out)
% =========================================================================

% This script should be run when you have a recording directory of a simulation
clc; clear;

cfg = jsondecode(fileread('config.json'));
N = cfg.N;
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

% default selection of latest simulation
folderPath = fullfile(pwd, "Data", scaleFolder, trialsSubfolder, "N" + num2str(N));
sim_folders = dir(folderPath);
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'})); 
[~, latestIdx] = max([sim_folders.datenum]);
latestSim = sim_folders(latestIdx).name;
filePath = fullfile(folderPath, latestSim);

% loading net object
data_files = dir(filePath);
data_files = data_files(~ismember({data_files.name}, {'.', '..'})); 
dataFiles = data_files(contains({data_files.name}, "Patch"));
[~, latestIdx] = max([dataFiles.datenum]);
latestData = dataFiles(latestIdx).name;
net = load(fullfile(filePath, latestData), 'obj'); net = net.obj;

clearvars -except net filePath cfg;
 
load(filePath + filesep + "MemoryRepresentations.mat");

clearvars filePath

%% Ensure output directory exists
if ~isfolder('Results'), mkdir('Results'); end

%% Spike Order Combined Figure (1x3: Separate | Together | Similarity Matrix)

N = net.N; Ne = net.Ne; Ni = net.Ni;
nTrials = size(orders_together, 1);

fig_order = figure('Units', 'inches', 'Position', [0.5 1 15 4.5], 'Visible', 'on');
tl = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Panel 1: E/I Separate ---
nexttile; hold on;
temp = orders_separate;
temp(temp == 0) = NaN;

stable_order_ex = orders_separate(end, 1:Ne);
stable_order_inh = orders_separate(end, Ne+1:end) - Ne;
stable_order_ex(stable_order_ex == 0) = Ne - sum(stable_order_ex == 0) + 1:Ne;
stable_order_inh(stable_order_inh == -Ne) = Ni - sum(stable_order_inh == -Ne) + 1:Ni;

cm_ex = jet(Ne);  cm_ex = cm_ex(stable_order_ex, :);
cm_inh = jet(Ni); cm_inh = cm_inh(stable_order_inh, :);

for c = 1:Ne
    plot(temp(:, c), 'Color', cm_ex(c, :), 'LineWidth', 0.8);
end
for c = Ne+1:N
    plot(temp(:, c), 'Color', cm_inh(c - Ne, :), 'LineWidth', 0.8);
end
xlabel('Trial'); ylabel('First-Spike Order Rank');
title('E/I Separate');
xlim([1 nTrials]);
% Colorbar: E and I indexed independently
colormap(gca, [jet(Ne); jet(Ni)]);
clim([1 N]);
cb_ei = colorbar;
cb_ei.Label.String = 'Neuron Index';
cb_ei.Ticks = [1 80 160 240 320 N];

% --- Panel 2: All Together ---
nexttile; hold on;
temp2 = orders_together;
temp2(temp2 == 0) = NaN;

stable_order = orders_together(end, :);
stable_order(stable_order == 0) = N - sum(stable_order == 0) + 1:N;
cm_all = jet(N); cm_all = cm_all(stable_order, :);

for c = 1:N
    plot(temp2(:, c), 'Color', cm_all(c, :), 'LineWidth', 0.6);
end
xlabel('Trial'); ylabel('First-Spike Order Rank');
title('All Neurons');
xlim([1 nTrials]);
% Colorbar showing original neuron index
colormap(gca, jet(N));
clim([1 N]);
cb_idx = colorbar;
cb_idx.Label.String = 'Neuron Index';
cb_idx.Ticks = [1 80 160 240 320 N];

% --- Panel 3: Spearman Similarity Matrix ---
nexttile;
data_ord = orders_together;
data_ord(data_ord == 0) = N + 1;  % non-spiking -> tied for last
corrmat = 1 - squareform(pdist(data_ord, 'spearman'));
imagesc(corrmat); axis square;
colormap(gca, parula); cb = colorbar;
cb.Label.String = 'Spearman Correlation';
set(gca, 'YDir', 'normal');
xlabel('Trial'); ylabel('Trial');
title('First Spike Order Similarity');
xlim([0.5 nTrials+0.5]); ylim([0.5 nTrials+0.5]);

% Save
exportgraphics(fig_order, 'Results/SpikeOrderPanel.pdf', 'ContentType', 'vector', 'BackgroundColor', 'none');
print(fig_order, 'Results/SpikeOrderPanel', '-dpng', '-r300');

%% Convergence curves for all three representations
% Shows how the three scalar convergence signals used by Step04 evolve
% over trials for this single simulation: raw (light) + smoothed (dark).

smoothWin = cfg.smoothTrials;
nTrials = size(delays, 1);

% 1. Mean first-spike latency per trial
d = delays;
d(d == 0) = NaN;
conv_delay = nanmean(d, 2);         % [nTrials x 1]

% 2. Mean spike count per trial
conv_spike = mean(spike_counts, 2);  % [nTrials x 1]

% 3. Spearman correlation with final-trial spike order
%    Non-spiking neurons (order == 0) are assigned rank N+1 so they are
%    treated as "tied for last" — slower than every neuron that fired.
final_order = orders_together(end, :);
final_order(final_order == 0) = N + 1;
conv_order = nan(nTrials, 1);
for t = 1:nTrials
    a = orders_together(t, :);
    a(a == 0) = N + 1;
    conv_order(t) = corr(a', final_order', 'Type', 'Spearman');
end

% Smoothed versions
conv_delay_s  = movmean(conv_delay,  smoothWin, 'omitnan');
conv_spike_s  = movmean(conv_spike,  smoothWin);
conv_order_s  = movmean(conv_order,  smoothWin, 'omitnan');

figure('Units', 'inches', 'Position', [1 1 8 7], 'Visible', 'on');
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% -- Latency
nexttile; hold on;
plot(1:nTrials, conv_delay, 'Color', [0.6 0.7 1 0.4]);
plot(1:nTrials, conv_delay_s, 'Color', [0.2 0.3 0.8], 'LineWidth', 1.5);
ylabel('Mean Latency (ms)');
title('First-Spike Latency');
xlim([1 nTrials]);

% -- Spike Count
nexttile; hold on;
plot(1:nTrials, conv_spike, 'Color', [1 0.6 0.6 0.4]);
plot(1:nTrials, conv_spike_s, 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
ylabel('Mean Spike Count');
title('Spike Count');
xlim([1 nTrials]);

% -- Spike Order
nexttile; hold on;
plot(1:nTrials, conv_order, 'Color', [0.6 0.9 0.6 0.4]);
plot(1:nTrials, conv_order_s, 'Color', [0.1 0.6 0.1], 'LineWidth', 1.5);
ylabel('Spearman $\rho$');
xlabel('Trial Number');
title('First-Spike Order Correlation with Final Trial');
xlim([1 nTrials]); ylim([0 1]);

print(gcf, 'Results/ConvergenceCurves', '-dpdf', '-vector', '-r300');
print(gcf, 'Results/ConvergenceCurves', '-dpng', '-r300');
