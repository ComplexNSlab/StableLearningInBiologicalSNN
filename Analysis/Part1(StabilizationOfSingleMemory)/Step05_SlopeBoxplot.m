% Step05_SlopeBoxplot.m  (SUPERSEDED by Step05_PlateauBoxplot.m)
% =========================================================================
% Grouped boxplot of slope-based stabilisation trials (latency vs firing
% rate) across network sizes, using the thresholds from Step04_SlopeThreshold.
%
% NOTE: newRepresentationStabilityTrialBoxPlot.m produces the same style
%       of plot but uses the improved plateau-based thresholds from
%       computeStabilizationTrialsForRepresentations.m.
%       This script is kept for reference / reproducibility of older results.
%
% INPUTS:
%   Data/Scaled50/Trials1500/DelaysThreshold.mat
%   Data/Scaled50/Trials1500/SpikeCountsThreshold.mat
%
% OUTPUTS:
%   Results/DelaysVsSpikeCounts_Boxplot.pdf / .png
% =========================================================================

clearvars('-except', 'show_figs', 'runAllPlots__*'); clc;
if ~exist('show_figs', 'var'), show_figs = 'on'; end

% Load delays
rep = "Delays";
file = fullfile("Data", "Scaled50", "Trials1500", rep + "Threshold.mat");
load(file, "thresholds");
thresholds_delays = thresholds;

% Load spike counts
rep = "SpikeCounts";
file = fullfile("Data", "Scaled50", "Trials1500", rep + "Threshold.mat");
load(file, "thresholds");
thresholds_spikecounts = thresholds;

% Settings
colors = {[0.6 0.7 1], [1 0.6 0.6]};  % Latency (blueish), SpikeCount (reddish)
labels = {'Latency', 'Spike Count'};

% Get all unique Ns
fields = fieldnames(thresholds_delays);
Ns = arrayfun(@(i) sscanf(fields{i}, 'N%d'), 1:numel(fields));
Ns = sort(Ns);
nGroups = numel(Ns);

% Initialize data
all_x = [];  % categorical x
all_y = [];
all_g = [];  % group indicator

for g = 1:2
    if g == 1
        data = thresholds_delays;
    else
        data = thresholds_spikecounts;
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
x_offset = x_double + (all_g - 1.5) * 0.25;  % shift left/right for grouping

% --- Plot ---
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
            data = thresholds_delays;
        else
            data = thresholds_spikecounts;
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
    n1 = sum(~isnan(thresholds_delays.(field)));
    n2 = sum(~isnan(thresholds_spikecounts.(field)));
    text(i, max(all_y)+150, sprintf('(%d|%d)', n1, n2), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'Interpreter', 'none');
end

% Labels and title
xlabel('Network Size $N$', 'Interpreter', 'latex');
ylabel({'Representational', 'Stabilization Time (Trials)'}, 'Interpreter', 'latex');
% t = title('Stabilization Thresholds: Delays vs Spike Counts', ...
%     'FontSize', 14, 'Interpreter', 'latex');
% t.Units = 'normalized';
% t.Position(2) = t.Position(2) + 0.05;

% Axis settings
ax = gca;
ax.XTick = 1:nGroups;
ax.XTickLabel = arrayfun(@num2str, Ns, 'UniformOutput', false);
ylim([min(all_y)-50, max(all_y)+100]);

% Legend
legend(labels, 'Location', 'southeast', 'Box', 'off');

% Export
slopeResultsDir = fullfile('Results', 'StabilizationResults', 'slope');
if ~isfolder(slopeResultsDir), mkdir(slopeResultsDir); end
exportgraphics(gcf, fullfile(slopeResultsDir, 'Step05_RepresentationalStabilization_Slope.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(slopeResultsDir, 'Step05_RepresentationalStabilization_Slope'), '-dpng', '-r300');
