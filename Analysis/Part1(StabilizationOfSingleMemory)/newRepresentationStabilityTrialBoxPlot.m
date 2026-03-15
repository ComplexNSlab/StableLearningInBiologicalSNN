clc; clear; close all;

%% Load plateau-based thresholds
S1 = load("Data\Scaled50\Trials1500\DelaysThreshold_plateau.mat");
delayThresholds = S1.delayThresholds;

S2 = load("Data\Scaled50\Trials1500\SpikeCountsThreshold_plateau.mat");
spikeThresholds = S2.spikeThresholds;

%% Network sizes to plot
N_list = 100:100:1000;

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