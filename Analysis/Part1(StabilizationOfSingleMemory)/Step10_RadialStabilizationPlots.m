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

clc; clear;

%% Load data
cfg = jsondecode(fileread('config.json'));
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(cfg.stabilityFrac*100), cfg.smoothTrials, cfg.holdTrials);

S           = load(fullfile(pwd, 'Results', 'StabilizationResults', sprintf('RadialStabilityResults_%s.mat', paramTag)));
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

figure('Color', 'w'); hold on;
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
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');

%% 2. Matching Delta_theta trace

dtheta   = Results(idxN).dthetaRaw{goodIdx};
dtheta_s = Results(idxN).dthetaSmooth{goodIdx};

figure('Color', 'w'); hold on;
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
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');

%% 3. Boxplot — radial stabilisation trial vs network size

allTrials = [];
groupN    = [];

for iN = 1:numel(Results)
    st = Results(iN).stabTrial;
    if isempty(st), continue; end

    st = st(~isnan(st));
    allTrials = [allTrials; st(:)];
    groupN    = [groupN;    Results(iN).N * ones(numel(st), 1)];
end

figure('Color', 'w'); hold on;
boxplot(allTrials, groupN);

uniqueN = unique(groupN);
for k = 1:numel(uniqueN)
    mask = groupN == uniqueN(k);
    jitter = 0.2 * (rand(sum(mask), 1) - 0.5);
    scatter(k + jitter, allTrials(mask), 15, [0.3 0.3 0.3], 'filled', ...
        'MarkerFaceAlpha', 0.35);
end

xlabel('Network Size N');
ylabel('Trial to radial stabilization');
title('Radial stabilization time (|\Deltar| \rightarrow 0)');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');

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

figure('Color', 'w');
errorbar(Ns, meds, iqrVals/2, 'o-', 'LineWidth', 2, 'Color', 'r');
xlabel('Network Size N');
ylabel('Median radial stabilization trial');
title('Radial stabilization trend with network size');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
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

figure('Color', 'w');
plot(Ns, peakMeds, 's-', 'LineWidth', 2, 'Color', 'r');
xlabel('Network Size N');
ylabel('Median peak trial');
title('Peak radial change trial vs network size');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
grid on;
