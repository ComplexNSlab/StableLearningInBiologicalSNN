% Step10_RadialStabilizationPlots.m
% =========================================================================
% Visualisation of radial (polar-decomposition) stabilisation results.
%
% Loads RadialStabilityResults.mat from Step09_RadialStabilization and
% produces five figures:
%   1. Single-run Delta_r trace (raw + smoothed) with threshold & landmarks.
%   2. Single-run Delta_theta trace for the same run.
%   3. Boxplot of radial stabilisation trial vs network size.
%   4. Median radial stabilisation trial vs N with IQR error bars.
%   5. Median peak |Delta_r| trial vs N.
%
% INPUTS:
%   Results/RadialStabilityResults.mat
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

S           = load(fullfile(resultsDir, 'RadialStabilityResults.mat'));
Results     = S.Results;
saveStride  = S.analysisParams.saveStride;

%% 1. Single-run Delta_r trace
% Pick a representative converged run for a given network size.

targetN = 400;
idxN    = find([Results.N] == targetN, 1);

if isempty(idxN)
    error('No results found for N=%d', targetN);
end

stabTrials = Results(idxN).stabTrial;
validIdx   = find(~isnan(stabTrials));
if isempty(validIdx)
    error('No converged run found for N=%d', targetN);
end

% Select the run closest to the median stabilization trial
medVal       = median(stabTrials(validIdx));
[~, loc]     = min(abs(stabTrials(validIdx) - medVal));
goodIdx      = validIdx(loc);

dr   = Results(idxN).drRaw{goodIdx};
dr_s = Results(idxN).drSmooth{goodIdx};
trials = saveStride * (1:numel(dr));

thr   = Results(idxN).threshold(goodIdx);
peakT = Results(idxN).peakTrial(goodIdx);
stabT = Results(idxN).stabTrial(goodIdx);

figure('Color', 'w', 'Visible', show_figs); hold on;
plot(trials, dr,   'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
plot(trials, dr_s, 'r', 'LineWidth', 2);
yline(thr,  '--b', 'Threshold');
yline(-thr, '--b', 'HandleVisibility', 'off');
yline(0,    ':k',  'HandleVisibility', 'off');
xline(peakT, '--m', 'Peak');
if ~isnan(stabT)
    xline(stabT, '--g', 'Stability');
end
xlabel('Trial');
ylabel('$\Delta r(t)$', 'Interpreter', 'latex');
title(sprintf('Radial stabilisation — N=%d, sim=%s', targetN, ...
    Results(idxN).folderNames(goodIdx)), 'Interpreter', 'none');
legend('Raw', 'Smoothed', 'Location', 'northeast', 'Box', 'off');

% Export, 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step10_DeltaR_SingleRun'), '-dpng', '-r300');

%% 2. Matching Delta_theta trace

dtheta   = Results(idxN).dthetaRaw{goodIdx};
dtheta_s = Results(idxN).dthetaSmooth{goodIdx};

figure('Color', 'w', 'Visible', show_figs); hold on;
plot(trials, rad2deg(dtheta),   'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
plot(trials, rad2deg(dtheta_s), 'Color', [0.1 0.6 0.1],    'LineWidth', 2);
if ~isnan(stabT)
    xline(stabT, '--g', 'Radial stability');
end
xlabel('Trial');
ylabel('$\Delta\theta(t)$ [deg]', 'Interpreter', 'latex');
title(sprintf('Angular change — N=%d, sim=%s', targetN, ...
    Results(idxN).folderNames(goodIdx)), 'Interpreter', 'none');
legend('Raw', 'Smoothed', 'Location', 'northeast', 'Box', 'off');

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step10_DeltaTheta_SingleRun.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step10_DeltaTheta_SingleRun'), '-dpng', '-r300');

%% 3. Boxplot — radial stabilisation trial vs network size

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
        'Interpreter', 'none');
end

xlabel('Network Size $N$', 'Interpreter', 'latex');
ylabel({'Radial', 'Stabilization Time (Trials)'}, 'Interpreter', 'latex');

ax = gca;
ax.XTick = 1:nGroups;
ax.XTickLabel = arrayfun(@num2str, uniqueN(:)', 'UniformOutput', false);
ylim([min(allTrials)-50, max(allTrials)+100]);

% Export
exportgraphics(gcf, fullfile(resultsDir, 'Step10_RadialStabilization.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step10_RadialStabilization'), '-dpng', '-r300');

%% 4. Median radial stabilisation trial vs N (error bars = IQR)

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

figure('Color', 'w', 'Visible', show_figs);
errorbar(Ns, meds, iqrVals/2, 'o-', 'LineWidth', 2, 'Color', 'r');
xlabel('Network Size N');
ylabel('Median radial stabilization trial');
title('Radial stabilization trend with network size');
grid on;

%% 5. Median peak |Delta_r| trial vs N

Ns       = [];
peakMeds = [];

for iN = 1:numel(Results)
    pt = Results(iN).peakTrial;
    pt = pt(~isnan(pt));
    if isempty(pt), continue; end

    Ns(end+1)       = Results(iN).N;
    peakMeds(end+1) = median(pt);
end

figure('Color', 'w', 'Visible', show_figs);
plot(Ns, peakMeds, 's-', 'LineWidth', 2, 'Color', 'r');
xlabel('Network Size N');
ylabel('Median peak trial');
title('Peak radial change trial vs network size');
grid on;
