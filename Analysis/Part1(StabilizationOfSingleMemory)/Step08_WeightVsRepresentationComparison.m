% Step08_WeightVsRepresentationComparison.m
% =========================================================================
% Compares structural (weight) vs functional (representation) stabilisation
% on a per-run paired basis.
%
% For each network size, pairs up simulation runs and computes the
% difference (structural − representation stabilisation trial). Produces:
%   1. Paired scatter plot (delay vs structural stabilisation).
%   2. Violin plot of paired differences per N.
%   3. Fraction of runs where structural stabilisation is later.
%   4. Median paired difference vs N.
%   5. Ratio of structural / representation stabilisation vs N.
%
% INPUTS:
%   Results/WeightStabilityResults.mat           (from Step06)
%   Data/.../SpikeCountsThreshold_plateau.mat    (from Step04_PlateauThreshold)
%
% OUTPUTS:
%   Figures displayed on screen; summary table printed to console.
% =========================================================================

clc; clearvars('-except', 'show_figs', 'runAllPlots__*'); close all;
if ~exist('show_figs', 'var'), show_figs = 'on'; end

%% Load data
cfg = jsondecode(fileread('config.json'));
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(cfg.stabilityFrac*100), cfg.smoothTrials, cfg.holdTrials);
resultsDir = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);

S1 = load(fullfile(resultsDir, 'WeightStabilityResults.mat'));
Results = S1.Results;

S2 = load(fullfile(resultsDir, 'SpikeCountsThreshold_plateau.mat'));
thresholds = S2.spikeThresholds;

%% Compare structural vs latency-based stabilization
Ns = [Results.N];

allDelay = [];
allStruct = [];
allDiff = [];
groupN = [];

fracStructLater = nan(size(Ns));
medianDiff = nan(size(Ns));
nMatched = zeros(size(Ns));
nTotal_runs = zeros(size(Ns));

for iN = 1:numel(Ns)
    N = Ns(iN);

    % structural stabilization trials
    structVals = Results(iN).stabTrial(:);

    % latency-based stabilization trials
    fieldName = sprintf('N%d', N);
    if ~isfield(thresholds, fieldName)
        warning('Field %s not found in thresholds.', fieldName);
        continue;
    end
    delayVals = thresholds.(fieldName)(:);

    % Match lengths conservatively
    L = min(numel(structVals), numel(delayVals));
    nTotal_runs(iN) = L;
    structVals = structVals(1:L);
    delayVals  = delayVals(1:L);

    % Keep only paired valid runs
    valid = ~isnan(structVals) & ~isnan(delayVals);

    structVals = structVals(valid);
    delayVals  = delayVals(valid);

    if isempty(structVals)
        warning('No matched valid runs for N=%d', N);
        continue;
    end

    diffVals = structVals - delayVals;

    allStruct = [allStruct; structVals];
    allDelay  = [allDelay; delayVals];
    allDiff   = [allDiff; diffVals];
    groupN    = [groupN; N * ones(numel(diffVals),1)];

    fracStructLater(iN) = mean(diffVals > 0);
    medianDiff(iN) = median(diffVals);
    nMatched(iN) = numel(diffVals);

    fprintf('N=%d: matched=%d, frac(struct>delay)=%.3f, median diff=%.1f\n', ...
        N, numel(diffVals), fracStructLater(iN), medianDiff(iN));
end

%% 1) Scatter plot: delay vs structural
figure('Visible', show_figs); hold on;
scatter(allDelay, allStruct, 30, groupN, 'filled');
mx = max([allDelay; allStruct]);
plot([0 mx], [0 mx], '--k', 'LineWidth', 1.5);

xlabel('Latency-based stabilization trial');
ylabel('Structural stabilization trial');
title('Paired comparison: latency-based vs structural stabilization');
cb = colorbar;
cb.Label.String = 'Network Size N';
xlim([0 1400]);
ylim([0 1400]);
grid on;
axis square;

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step08_StructuralVsRepresentational_Scatter.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step08_StructuralVsRepresentational_Scatter'), '-dpng', '-r300');

%% 2) Boxplot of paired differences: structural - delay
uniqueN = unique(groupN);
nGroups_diff = numel(uniqueN);
x_cat_diff = categorical(groupN);
x_double_diff = double(x_cat_diff);

figure('Units', 'inches', 'Position', [1, 1, 7, 4.5], 'Visible', show_figs); hold on;

boxchart(x_double_diff, allDiff, ...
    'BoxFaceColor', [0.5 0.7 1], ...
    'MarkerStyle', 'none', ...
    'BoxEdgeColor', 'none', ...
    'WhiskerLineColor', [0.5 0.7 1], ...
    'BoxMedianLineColor', [0.5 0.7 1], ...
    'LineWidth', 1.2, ...
    'WhiskerLineStyle', '-', ...
    'BoxWidth', 0.4);

% Plot individual data points (with jitter)
for k = 1:nGroups_diff
    mask = groupN == uniqueN(k);
    vals = allDiff(mask);
    jitter = (rand(numel(vals), 1) - 0.5) * 0.20;
    scatter(k + jitter, vals, ...
        4, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
end

yline(0, '--k', 'LineWidth', 1.5);

% Annotate converged sample sizes above
for k = 1:nGroups_diff
    iN = find(Ns == uniqueN(k), 1);
    text(k, max(allDiff)+50, sprintf('%d', nMatched(iN)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'Interpreter', 'none');
end

xlabel('Network Size $N$', 'Interpreter', 'latex');
ylabel({'Structural $-$ Representational', 'Stabilization Time (Trials)'}, 'Interpreter', 'latex');

ax = gca;
ax.XTick = 1:nGroups_diff;
ax.XTickLabel = arrayfun(@num2str, uniqueN(:)', 'UniformOutput', false);

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step08_StructuralVsRepresentational_Diff.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step08_StructuralVsRepresentational_Diff'), '-dpng', '-r300');

%% 3) Fraction of runs where structural is later
validN = nMatched > 0;

figure('Visible', show_figs); hold on;
plot(Ns(validN), fracStructLater(validN), 'o-', 'LineWidth', 2);
yline(0.5, '--k', 'LineWidth', 1.5);

xlabel('Network Size N');
ylabel('Fraction with structural > latency');
title('How often structural stabilization is later than latency stabilization');
ylim([0 1]);
grid on;

%% 4) Median paired difference vs N
figure('Visible', show_figs); hold on;
plot(Ns(validN), medianDiff(validN), 's-', 'LineWidth', 2);
yline(0, '--k', 'LineWidth', 1.5);

xlabel('Network Size N');
ylabel('Median(structural - latency)');
title('Median paired difference vs network size');
grid on;

%% Optional summary table in command window
T = table(Ns(:), nMatched(:), fracStructLater(:), medianDiff(:), ...
    'VariableNames', {'N','MatchedRuns','FracStructLater','MedianDiff'});
disp(T);

%% 5) Ratio of structural to representation stabilization vs N
allRatio = allStruct ./ allDelay;
uniqueN = unique(groupN);
nGroups_ratio = numel(uniqueN);
x_cat_ratio = categorical(groupN);
x_double_ratio = double(x_cat_ratio);

figure('Units', 'inches', 'Position', [1, 1, 7, 4.5], 'Visible', show_figs); hold on;

boxchart(x_double_ratio, allRatio, ...
    'BoxFaceColor', [1 0.7 0.5], ...
    'MarkerStyle', 'none', ...
    'BoxEdgeColor', 'none', ...
    'WhiskerLineColor', [1 0.7 0.5], ...
    'BoxMedianLineColor', [1 0.7 0.5], ...
    'LineWidth', 1.2, ...
    'WhiskerLineStyle', '-', ...
    'BoxWidth', 0.4);

% Plot individual data points (with jitter)
for k = 1:nGroups_ratio
    mask = groupN == uniqueN(k);
    vals = allRatio(mask);
    jitter = (rand(numel(vals), 1) - 0.5) * 0.20;
    scatter(k + jitter, vals, ...
        4, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
end

yline(1, '--k', 'LineWidth', 1.5);

% Annotate converged sample sizes above
for k = 1:nGroups_ratio
    iN = find(Ns == uniqueN(k), 1);
    text(k, max(allRatio)+0.1, sprintf('%d', nMatched(iN)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'Interpreter', 'none');
end

xlabel('Network Size $N$', 'Interpreter', 'latex');
ylabel({'Structural / Representational', 'Stabilization Time'}, 'Interpreter', 'latex');

ax = gca;
ax.XTick = 1:nGroups_ratio;
ax.XTickLabel = arrayfun(@num2str, uniqueN(:)', 'UniformOutput', false);

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step08_StructuralVsRepresentational_Ratio.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step08_StructuralVsRepresentational_Ratio'), '-dpng', '-r300');
%% 