% Step07_WeightStabilizationPlots.m
% =========================================================================
% Visualisation of structural (synaptic) stabilisation results.
%
% Loads WeightStabilityResults.mat from Step06_WeightStabilization and
% produces four figures:
%   1. Single-run delta-W trace (raw + smoothed) with threshold, plateau,
%      peak, and stability landmarks.
%   2. Boxplot of structural stabilisation trial vs network size.
%   3. Median stabilisation trial vs N with IQR error bars.
%   4. Median peak-update trial vs N.
%
% INPUTS:
%   Results/WeightStabilityResults.mat
% =========================================================================

clc; clearvars('-except', 'show_figs', 'runAllPlots__*');
if ~exist('show_figs', 'var'), show_figs = 'on'; end

%% Load data
cfg = jsondecode(fileread('config.json'));
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(cfg.stabilityFrac*100), cfg.smoothTrials, cfg.holdTrials);
resultsDir = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);

S           = load(fullfile(resultsDir, 'WeightStabilityResults.mat'));
Results     = S.Results;
saveStride  = S.analysisParams.saveStride;

%% Single-run weight signal trace
% Pick a representative converged run for a given network size and plot
% the raw and smoothed delta-W signals with key landmarks.

targetN = 400;
idxN    = find([Results.N] == targetN, 1);

stabTrials = Results(idxN).stabTrial;
validIdx   = find(~isnan(stabTrials));
if isempty(validIdx)
    error('No converged run found for N=%d', targetN);
end

% Select the run closest to the median stabilization trial
medVal       = median(stabTrials(validIdx));
[~, loc]     = min(abs(stabTrials(validIdx) - medVal));
goodIdx      = validIdx(loc);

d  = Results(idxN).deltaRaw{goodIdx};
ds = Results(idxN).deltaSmooth{goodIdx};

xRaw = saveStride * (1:numel(d));
xSm  = saveStride * (1:numel(ds));

thr      = Results(idxN).threshold(goodIdx);
peakT    = Results(idxN).peakTrial(goodIdx);
plateauV = Results(idxN).plateauValue(goodIdx);
stabT    = Results(idxN).stabTrial(goodIdx);

figure('Visible', show_figs); hold on;
plot(xRaw, d,  'Color', [0.75 0.75 0.75], 'LineWidth', 1);
plot(xSm,  ds, 'b',                        'LineWidth', 2);
yline(thr,      '--r', 'Threshold');
yline(plateauV, ':k',  'Plateau');
xline(peakT,    '--m', 'Peak');
if ~isnan(stabT)
    xline(stabT, '--g', 'Stability');
end
xlabel('Trial');
ylabel('\Delta W(t)');
title(sprintf('Plateau-based structural stability', targetN, goodIdx));
legend('Raw', 'Smoothed', 'Location', 'northeast');
grid on;

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step07_DeltaW_SingleRun.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step07_DeltaW_SingleRun'), '-dpng', '-r300');

%% Boxplot — structural stabilization time vs network size
% Compare the distribution of stabilization trials across network sizes.

allTrials = [];
groupN    = [];
totalPerN = [];

for iN = 1:numel(Results)
    st = Results(iN).stabTrial;
    if isempty(st), continue; end

    nTotal = numel(st);
    st = st(~isnan(st));
    allTrials = [allTrials; st(:)];
    groupN    = [groupN;    Results(iN).N * ones(numel(st), 1)];
    totalPerN = [totalPerN; Results(iN).N, nTotal, numel(st)];
end

x_cat = categorical(groupN);
x_double = double(x_cat);
uniqueN = unique(groupN);
nGroups = numel(uniqueN);

figure('Units', 'inches', 'Position', [1, 1, 7, 4.5], 'Visible', show_figs); hold on;

boxchart(x_double, allTrials, ...
    'BoxFaceColor', [0.6 0.7 1], ...
    'MarkerStyle', 'none', ...
    'BoxEdgeColor', 'none', ...
    'WhiskerLineColor', [0.6 0.7 1], ...
    'BoxMedianLineColor', [0.6 0.7 1], ...
    'LineWidth', 1.2, ...
    'WhiskerLineStyle', '-', ...
    'BoxWidth', 0.4);

% Plot individual data points (with jitter)
for k = 1:nGroups
    mask = groupN == uniqueN(k);
    jitter = (rand(sum(mask), 1) - 0.5) * 0.20;
    scatter(k + jitter, allTrials(mask), ...
        4, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
end

% Annotate converged sample sizes above
for k = 1:nGroups
    row = totalPerN(totalPerN(:,1) == uniqueN(k), :);
    text(k, max(allTrials)+50, sprintf('%d', row(3)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontName', 'Times New Roman', ...
        'Interpreter', 'none');
end

xlabel('Network Size $N$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel({'Structural', 'Stabilization Time (Trials)'}, 'Interpreter', 'latex', 'FontSize', 14);

ax = gca;
ax.XTick = 1:nGroups;
ax.XTickLabel = arrayfun(@num2str, uniqueN(:)', 'UniformOutput', false);
ax.FontSize = 12;
ax.FontName = 'Times New Roman';
ax.Box = 'off';
ax.TickDir = 'out';
ylim([min(allTrials)-50, max(allTrials)+100]);

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step07_StructuralStabilization.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step07_StructuralStabilization'), '-dpng', '-r300');

%% Median stabilization trial vs network size (error bars = IQR)

Ns      = [];
meds    = [];
iqrVals = [];

for iN = 1:numel(Results)
    st = Results(iN).stabTrial;
    st = st(~isnan(st));
    if isempty(st), continue; end

    Ns(end+1)      = Results(iN).N;
    meds(end+1)    = median(st);
    iqrVals(end+1) = iqr(st);
end

figure('Visible', show_figs);
errorbar(Ns, meds, iqrVals/2, 'o-', 'LineWidth', 2);
xlabel('Network Size N');
ylabel('Median structural stabilization trial');
title('Structural stabilization trend with network size');
grid on;

%% Median peak-update trial vs network size

Ns       = [];
peakMeds = [];

for iN = 1:numel(Results)
    pt = Results(iN).peakTrial;
    pt = pt(~isnan(pt));
    if isempty(pt), continue; end

    Ns(end+1)       = Results(iN).N;
    peakMeds(end+1) = median(pt);
end

figure('Visible', show_figs);
plot(Ns, peakMeds, 's-', 'LineWidth', 2);
xlabel('Network Size N');
ylabel('Median peak trial');
title('Peak synaptic update time vs network size');
grid on;