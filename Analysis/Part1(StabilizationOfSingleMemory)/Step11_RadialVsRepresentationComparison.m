% Step11_RadialVsRepresentationComparison.m
% =========================================================================
% Compares radial (polar-decomposition) vs functional (representation)
% stabilisation on a per-run paired basis.
%
% Mirrors Step08 but uses the radial stabilisation times from Step09
% instead of the L1-based weight stabilisation from Step06.
%
% For each network size, pairs up simulation runs and computes the
% difference (radial − representation stabilisation trial). Produces:
%   1. Paired scatter plot (delay vs radial stabilisation).
%   2. Violin plot of paired differences per N.
%   3. Fraction of runs where radial stabilisation is later.
%   4. Median paired difference vs N.
%   5. Ratio of radial / representation stabilisation vs N.
%
% INPUTS:
%   Results/RadialStabilityResults.mat           (from Step09)
%   Data/.../SpikeCountsThreshold_plateau.mat    (from Step04_PlateauThreshold)
%
% OUTPUTS:
%   Figures displayed on screen; summary table printed to console.
% =========================================================================

clc; clear; close all;

%% Load config & data
cfg = jsondecode(fileread('config.json'));
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
paramTag = sprintf('frac%03d_smooth%d_hold%d', round(cfg.stabilityFrac*100), cfg.smoothTrials, cfg.holdTrials);

S1 = load(fullfile(pwd, 'Results', 'StabilizationResults', sprintf('RadialStabilityResults_%s.mat', paramTag)));
Results = S1.Results;

S2 = load(fullfile(pwd, 'Results', 'StabilizationResults', sprintf('SpikeCountsThreshold_plateau_%s.mat', paramTag)));
thresholds = S2.spikeThresholds;

%% Compare radial vs delay-based stabilization
Ns = [Results.N];

allDelay  = [];
allRadial = [];
allDiff   = [];
groupN    = [];

fracRadialLater = nan(size(Ns));
medianDiff      = nan(size(Ns));
nMatched        = zeros(size(Ns));

for iN = 1:numel(Ns)
    N = Ns(iN);

    % radial stabilization trials
    radialVals = Results(iN).stabTrial(:);

    % delay-based stabilization trials
    fieldName = sprintf('N%d', N);
    if ~isfield(thresholds, fieldName)
        warning('Field %s not found in thresholds.', fieldName);
        continue;
    end
    delayVals = thresholds.(fieldName)(:);

    % Match lengths conservatively
    L = min(numel(radialVals), numel(delayVals));
    radialVals = radialVals(1:L);
    delayVals  = delayVals(1:L);

    % Keep only paired valid runs
    valid = ~isnan(radialVals) & ~isnan(delayVals);
    radialVals = radialVals(valid);
    delayVals  = delayVals(valid);

    if isempty(radialVals)
        warning('No matched valid runs for N=%d', N);
        continue;
    end

    diffVals = radialVals - delayVals;

    allRadial = [allRadial; radialVals];
    allDelay  = [allDelay;  delayVals];
    allDiff   = [allDiff;   diffVals];
    groupN    = [groupN;    N * ones(numel(diffVals), 1)];

    fracRadialLater(iN) = mean(diffVals > 0);
    medianDiff(iN)      = median(diffVals);
    nMatched(iN)        = numel(diffVals);

    fprintf('N=%d: matched=%d, frac(radial>delay)=%.3f, median diff=%.1f\n', ...
        N, numel(diffVals), fracRadialLater(iN), medianDiff(iN));
end

%% 1) Scatter plot: delay vs radial
figure('Color', 'w'); hold on;
scatter(allDelay, allRadial, 30, groupN, 'filled');
mx = max([allDelay; allRadial]);
plot([0 mx], [0 mx], '--k', 'LineWidth', 1.5);

xlabel('Delay-based stabilization trial');
ylabel('Radial stabilization trial');
title('Paired comparison: delay-based vs radial stabilization');
cb = colorbar;
cb.Label.String = 'Network Size N';
xlim([0 1500]);
ylim([0 1500]);
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
grid on;
axis square;

%% 2) Violin plot of paired differences: radial - delay
uniqueN = unique(groupN);
figure('Color', 'w'); hold on;

for k = 1:numel(uniqueN)
    vals = allDiff(groupN == uniqueN(k));
    [f, xi] = ksdensity(vals, 'NumPoints', 200);
    f = f / max(f) * 0.35;
    fill([k+f fliplr(k-f)], [xi fliplr(xi)], [0.5 0.7 1], ...
        'FaceAlpha', 0.4, 'EdgeColor', [0.2 0.4 0.8], 'LineWidth', 1);
    jitter = 0.15 * (rand(numel(vals), 1) - 0.5);
    scatter(k + jitter, vals, 15, [0.3 0.3 0.3], 'filled', ...
        'MarkerFaceAlpha', 0.4);
    plot(k, median(vals), 'w_', 'MarkerSize', 12, 'LineWidth', 2);
end

yline(0, '--k', 'LineWidth', 1.5);
set(gca, 'XTick', 1:numel(uniqueN), 'XTickLabel', string(uniqueN));
xlabel('Network Size N');
ylabel('Radial - delay stabilization time (trials)');
title('Paired difference: radial vs delay-based stabilization');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
grid on;

%% 3) Fraction of runs where radial is later
validN = nMatched > 0;

figure('Color', 'w'); hold on;
plot(Ns(validN), fracRadialLater(validN), 'o-', 'LineWidth', 2, 'Color', 'r');
yline(0.5, '--k', 'LineWidth', 1.5);

xlabel('Network Size N');
ylabel('Fraction with radial > delay');
title('How often radial stabilization is later than delay stabilization');
ylim([0 1]);
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
grid on;

%% 4) Median paired difference vs N
figure('Color', 'w'); hold on;
plot(Ns(validN), medianDiff(validN), 's-', 'LineWidth', 2, 'Color', 'r');
yline(0, '--k', 'LineWidth', 1.5);

xlabel('Network Size N');
ylabel('Median(radial - delay)');
title('Median paired difference vs network size');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
grid on;

%% Summary table
T = table(Ns(:), nMatched(:), fracRadialLater(:), medianDiff(:), ...
    'VariableNames', {'N', 'MatchedRuns', 'FracRadialLater', 'MedianDiff'});
disp(T);

%% 5) Ratio of radial / representation stabilization vs N
allRatio = allRadial ./ allDelay;
uniqueN = unique(groupN);

figure('Color', 'w'); hold on;

for k = 1:numel(uniqueN)
    vals = allRatio(groupN == uniqueN(k));
    [f, xi] = ksdensity(vals, 'NumPoints', 200);
    f = f / max(f) * 0.35;
    fill([k+f fliplr(k-f)], [xi fliplr(xi)], [1 0.7 0.5], ...
        'FaceAlpha', 0.4, 'EdgeColor', [0.8 0.4 0.2], 'LineWidth', 1);
    jitter = 0.15 * (rand(numel(vals), 1) - 0.5);
    scatter(k + jitter, vals, 15, [0.3 0.3 0.3], 'filled', ...
        'MarkerFaceAlpha', 0.4);
    plot(k, median(vals), 'w_', 'MarkerSize', 12, 'LineWidth', 2);
end

yline(1, '--k', 'LineWidth', 1.5);
set(gca, 'XTick', 1:numel(uniqueN), 'XTickLabel', string(uniqueN));
xlabel('Network Size N');
ylabel('Radial / Representation stabilization trial');
title('Ratio of radial to representation stabilization vs network size');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');
grid on;
