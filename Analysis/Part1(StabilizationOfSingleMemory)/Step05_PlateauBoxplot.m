% Step05_PlateauBoxplot.m
% =========================================================================
% Grouped boxplot of plateau-based stabilisation times (latency vs firing
% rate) across network sizes.
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

clc; clearvars('-except', 'show_figs', 'runAllPlots__*'); close all;
if ~exist('show_figs', 'var'), show_figs = 'on'; end

%% Load config and build paramTag
cfg = jsondecode(fileread('config.json'));
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(cfg.stabilityFrac*100), cfg.smoothTrials, cfg.holdTrials);
resultsDir = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);

S1 = load(fullfile(resultsDir, 'DelaysThreshold_plateau.mat'));
delayThresholds = S1.delayThresholds;

S2 = load(fullfile(resultsDir, 'SpikeCountsThreshold_plateau.mat'));
spikeThresholds = S2.spikeThresholds;

%% Settings
colors = {[0.6 0.7 1], [1 0.6 0.6]};  % Latency (blueish), SpikeCount (reddish)
labels = {'Latency', 'Spike Count'};
Ns = sort(cfg.networkSizes(:)');
nGroups = numel(Ns);

%% Gather data
all_x = [];
all_y = [];
all_g = [];

for g = 1:2
    if g == 1
        data = delayThresholds;
    else
        data = spikeThresholds;
    end

    for i = 1:nGroups
        field = sprintf('N%d', Ns(i));
        if ~isfield(data, field), continue; end
        vals = data.(field);
        vals = vals(~isnan(vals));
        if isempty(vals), continue; end

        all_x = [all_x; repmat(Ns(i), numel(vals), 1)];
        all_y = [all_y; vals(:)];
        all_g = [all_g; repmat(g, numel(vals), 1)];
    end
end

% Convert to categorical x with group offsets
x_cat = categorical(all_x);
x_double = double(x_cat);
x_offset = x_double + (all_g - 1.5) * 0.25;

%% Plot
figure('Units', 'inches', 'Position', [1, 1, 7, 4.5], 'Visible', show_figs); hold on;

% Plot each group boxchart
for g = 1:2
    idx = (all_g == g);
    boxchart(x_offset(idx), all_y(idx), ...
        'BoxFaceColor', colors{g}, ...
        'MarkerStyle', 'none', ...
        'BoxEdgeColor', 'none', ...
        'WhiskerLineColor', colors{g}, ...
        'BoxMedianLineColor', colors{g}, ...
        'LineWidth', 1.2, ...
        'WhiskerLineStyle', '-', ...
        'BoxWidth', 0.2);
end

% Plot individual data points (with jitter)
for g = 1:2
    for i = 1:nGroups
        x_val = i + (g - 1.5) * 0.25;
        if g == 1
            data = delayThresholds;
        else
            data = spikeThresholds;
        end
        field = sprintf('N%d', Ns(i));
        if ~isfield(data, field), continue; end
        vals = data.(field);
        vals = vals(~isnan(vals));
        jitter = (rand(size(vals)) - 0.5) * 0.10;
        scatter(x_val + jitter, vals, ...
            4, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
    end
end

% Annotate sample sizes above (converged delays | converged spikes)
for i = 1:nGroups
    field = sprintf('N%d', Ns(i));
    n1 = sum(~isnan(delayThresholds.(field)));
    n2 = sum(~isnan(spikeThresholds.(field)));
    text(i, max(all_y)+150, sprintf('(%d|%d)', n1, n2), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontName', 'Times New Roman', ...
        'Interpreter', 'none');
end

% Labels
xlabel('Network Size $N$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel({'Representational', 'Stabilization Time (Trials)'}, 'Interpreter', 'latex', 'FontSize', 14);

% Axis settings
ax = gca;
ax.XTick = 1:nGroups;
ax.XTickLabel = arrayfun(@num2str, Ns, 'UniformOutput', false);
ax.FontSize = 12;
ax.FontName = 'Times New Roman';
ax.Box = 'off';
ax.TickDir = 'out';
ylim([min(all_y)-50, max(all_y)+100]);

% Legend
legend(labels, 'Location', 'southeast', 'FontSize', 10, 'Box', 'off');

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step05_RepresentationalStabilization_Plateau.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step05_RepresentationalStabilization_Plateau'), '-dpng', '-r300');