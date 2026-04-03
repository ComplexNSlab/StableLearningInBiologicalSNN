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

clc; clear;

%% Load data
cfg = jsondecode(fileread('config.json'));
if isfield(cfg, 'stabilityFrac'), frac = cfg.stabilityFrac; else, frac = 0.10; end
if isfield(cfg, 'smoothTrials'),  smoo = cfg.smoothTrials;  else, smoo = 100;  end
if isfield(cfg, 'holdTrials'),    hold_ = cfg.holdTrials;   else, hold_ = 100;  end
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(frac*100), smoo, hold_);

S           = load(fullfile(pwd, 'Results', 'StabilizationResults', sprintf('WeightStabilityResults_%s.mat', paramTag)));
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

figure; hold on;
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

%% Boxplot — structural stabilization time vs network size
% Compare the distribution of stabilization trials across network sizes.

allTrials = [];
groupN    = [];

for iN = 1:numel(Results)
    st = Results(iN).stabTrial;
    if isempty(st), continue; end

    st = st(~isnan(st));
    allTrials = [allTrials; st(:)];
    groupN    = [groupN;    Results(iN).N * ones(numel(st), 1)];
end

figure; hold on;
boxplot(allTrials, groupN);

uniqueN = unique(groupN);
for k = 1:numel(uniqueN)
    mask = groupN == uniqueN(k);
    jitter = 0.2 * (rand(sum(mask),1) - 0.5);
    scatter(k + jitter, allTrials(mask), 15, [0.3 0.3 0.3], 'filled', ...
        'MarkerFaceAlpha', 0.35);
end

xlabel('Network Size N');
ylabel('Trial to structural stabilization');
title('Structural stabilization time (synaptic update plateau)');
% grid on;

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

figure;
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

figure;
plot(Ns, peakMeds, 's-', 'LineWidth', 2);
xlabel('Network Size N');
ylabel('Median peak trial');
title('Peak synaptic update time vs network size');
grid on;