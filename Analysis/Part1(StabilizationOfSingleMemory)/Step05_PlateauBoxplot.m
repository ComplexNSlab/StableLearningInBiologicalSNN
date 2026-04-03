% Step05_PlateauBoxplot.m
% =========================================================================
% Grouped boxplot of plateau-based stabilisation times (delays vs spike
% counts) across network sizes.
%
% Loads the thresholds produced by Step04_PlateauThreshold and displays
% side-by-side boxplots for each N, annotated with sample counts.
%
% INPUTS:
%   Data/{scaleFolder}/Trials{X}/DelaysThreshold_plateau.mat
%   Data/{scaleFolder}/Trials{X}/SpikeCountsThreshold_plateau.mat
%
% OUTPUTS:
%   Figure displayed on screen.
% =========================================================================

clc; clear; close all;

%% Load config and build paramTag
cfg = jsondecode(fileread('config.json'));
if isfield(cfg, 'stabilityFrac'), frac = cfg.stabilityFrac; else, frac = 0.10; end
if isfield(cfg, 'smoothTrials'),  smoo = cfg.smoothTrials;  else, smoo = 100;  end
if isfield(cfg, 'holdTrials'),    hold_ = cfg.holdTrials;   else, hold_ = 100;  end
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(frac*100), smoo, hold_);

S1 = load(fullfile(pwd, 'Results', 'StabilizationResults', sprintf('DelaysThreshold_plateau_%s.mat', paramTag)));
delayThresholds = S1.delayThresholds;

S2 = load(fullfile(pwd, 'Results', 'StabilizationResults', sprintf('SpikeCountsThreshold_plateau_%s.mat', paramTag)));
spikeThresholds = S2.spikeThresholds;

%% Network sizes to plot
N_list = cfg.networkSizes(:)';

%% Gather data
allVals = [];
groupPos = [];
groupColor = [];
topLabels = strings(numel(N_list), 1);

% positions for side-by-side boxplots
xBase = 1:numel(N_list);
offset = 0.18;

for iN = 1:numel(N_list)
    N = N_list(iN);
    fieldName = sprintf('N%d', N);

    if ~isfield(delayThresholds, fieldName) || ~isfield(spikeThresholds, fieldName)
        warning('Missing thresholds for N=%d', N);
        continue;
    end

    delayVals = delayThresholds.(fieldName)(:);
    spikeVals = spikeThresholds.(fieldName)(:);

    delayVals = delayVals(~isnan(delayVals));
    spikeVals = spikeVals(~isnan(spikeVals));

    % store top annotation like (49|33)
    topLabels(iN) = sprintf('(%d|%d)', numel(delayVals), numel(spikeVals));

    % delays
    allVals   = [allVals; delayVals];
    groupPos  = [groupPos; (xBase(iN)-offset) * ones(numel(delayVals),1)];
    groupColor = [groupColor; ones(numel(delayVals),1)];   % 1 = delay

    % spike counts
    allVals   = [allVals; spikeVals];
    groupPos  = [groupPos; (xBase(iN)+offset) * ones(numel(spikeVals),1)];
    groupColor = [groupColor; 2 * ones(numel(spikeVals),1)]; % 2 = spike
end

%% Plot
figure('Color','w'); hold on;

% Delay boxplots
idxD = groupColor == 1;
boxplot(allVals(idxD), groupPos(idxD), ...
    'Positions', unique(groupPos(idxD)), ...
    'Widths', 0.28, ...
    'Colors', [0.3 0.5 0.9], ...
    'Symbol', '.');

% Spike-count boxplots
idxS = groupColor == 2;
boxplot(allVals(idxS), groupPos(idxS), ...
    'Positions', unique(groupPos(idxS)), ...
    'Widths', 0.28, ...
    'Colors', [0.9 0.4 0.4], ...
    'Symbol', '.');

% Re-label x-axis
set(gca, 'XTick', xBase, 'XTickLabel', string(N_list));

xlabel('Network Size $N$');
ylabel('Trial to stabilization');
title('Plateau-based stabilization times for delay and spike-count representations');

% Add top labels
yl = ylim;
yTop = yl(2) - 0.03*(yl(2)-yl(1));
for iN = 1:numel(N_list)
    text(xBase(iN), yTop, topLabels(iN), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 10);
end

% Dummy legend
h1 = plot(nan, nan, '-', 'Color', [0.3 0.5 0.9], 'LineWidth', 8);
h2 = plot(nan, nan, '-', 'Color', [0.9 0.4 0.4], 'LineWidth', 8);
legend([h1 h2], {'Delays', 'Spike Counts'}, 'Location', 'best');

grid on;
box on;