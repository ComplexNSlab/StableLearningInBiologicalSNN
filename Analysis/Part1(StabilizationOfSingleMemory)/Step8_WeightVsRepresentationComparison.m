% Step8_WeightVsRepresentationComparison.m
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
%   Results/WeightStabilityResults.mat           (from Step6)
%   Data/.../SpikeCountsThreshold_plateau.mat    (from Step4_PlateauThreshold)
%
% OUTPUTS:
%   Figures displayed on screen; summary table printed to console.
% =========================================================================

clc; clear; close all;

%% Load data
projectRoot = fileparts(fileparts(which('IzhikevichNetwork')));
scriptDir   = fullfile(projectRoot, 'Analysis', 'Part1(StabilizationOfSingleMemory)');

S1 = load(fullfile(scriptDir, "Results", "WeightStabilityResults.mat"));
Results = S1.Results;

S2 = load(fullfile(scriptDir, "Data", "Scaled50", "Trials1500", "SpikeCountsThreshold_plateau.mat"));
thresholds = S2.spikeThresholds;

%% Compare structural vs delay-based stabilization
Ns = [Results.N];

allDelay = [];
allStruct = [];
allDiff = [];
groupN = [];

fracStructLater = nan(size(Ns));
medianDiff = nan(size(Ns));
nMatched = zeros(size(Ns));

for iN = 1:numel(Ns)
    N = Ns(iN);

    % structural stabilization trials
    structVals = Results(iN).stabTrial(:);

    % delay-based stabilization trials
    fieldName = sprintf('N%d', N);
    if ~isfield(thresholds, fieldName)
        warning('Field %s not found in thresholds.', fieldName);
        continue;
    end
    delayVals = thresholds.(fieldName)(:);

    % Match lengths conservatively
    L = min(numel(structVals), numel(delayVals));
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
figure; hold on;
scatter(allDelay, allStruct, 30, groupN, 'filled');
mx = max([allDelay; allStruct]);
plot([0 mx], [0 mx], '--k', 'LineWidth', 1.5);

xlabel('Delay-based stabilization trial');
ylabel('Structural stabilization trial');
title('Paired comparison: delay-based vs structural stabilization');
cb = colorbar;
cb.Label.String = 'Network Size N';
xlim([0 1400]);
ylim([0 1400]);
grid on;
axis square;

%% 2) Violin plot of paired differences: structural - delay
uniqueN = unique(groupN);
figure; hold on;

for k = 1:numel(uniqueN)
    vals = allDiff(groupN == uniqueN(k));
    [f, xi] = ksdensity(vals, 'NumPoints', 200);
    f = f / max(f) * 0.35;  % normalize width
    fill([k+f fliplr(k-f)], [xi fliplr(xi)], [0.5 0.7 1], ...
        'FaceAlpha', 0.4, 'EdgeColor', [0.2 0.4 0.8], 'LineWidth', 1);
    jitter = 0.15 * (rand(numel(vals),1) - 0.5);
    scatter(k + jitter, vals, 15, [0.3 0.3 0.3], 'filled', ...
        'MarkerFaceAlpha', 0.4);
    plot(k, median(vals), 'w_', 'MarkerSize', 12, 'LineWidth', 2);
end

yline(0, '--k', 'LineWidth', 1.5);
set(gca, 'XTick', 1:numel(uniqueN), 'XTickLabel', string(uniqueN));
xlabel('Network Size N');
ylabel('Structural - delay stabilization time (trials)');
title('Paired difference between structural and delay-based stabilization times');
grid on;

%% 3) Fraction of runs where structural is later
validN = nMatched > 0;

figure; hold on;
plot(Ns(validN), fracStructLater(validN), 'o-', 'LineWidth', 2);
yline(0.5, '--k', 'LineWidth', 1.5);

xlabel('Network Size N');
ylabel('Fraction with structural > delay');
title('How often structural stabilization is later than delay stabilization');
ylim([0 1]);
grid on;

%% 4) Median paired difference vs N
figure; hold on;
plot(Ns(validN), medianDiff(validN), 's-', 'LineWidth', 2);
yline(0, '--k', 'LineWidth', 1.5);

xlabel('Network Size N');
ylabel('Median(structural - delay)');
title('Median paired difference vs network size');
grid on;

%% Optional summary table in command window
T = table(Ns(:), nMatched(:), fracStructLater(:), medianDiff(:), ...
    'VariableNames', {'N','MatchedRuns','FracStructLater','MedianDiff'});
disp(T);

%% 5) Ratio of structural to representation stabilization vs N
allRatio = allStruct ./ allDelay;
uniqueN = unique(groupN);

figure; hold on;

for k = 1:numel(uniqueN)
    vals = allRatio(groupN == uniqueN(k));
    [f, xi] = ksdensity(vals, 'NumPoints', 200);
    f = f / max(f) * 0.35;
    fill([k+f fliplr(k-f)], [xi fliplr(xi)], [1 0.7 0.5], ...
        'FaceAlpha', 0.4, 'EdgeColor', [0.8 0.4 0.2], 'LineWidth', 1);
    jitter = 0.15 * (rand(numel(vals),1) - 0.5);
    scatter(k + jitter, vals, 15, [0.3 0.3 0.3], 'filled', ...
        'MarkerFaceAlpha', 0.4);
    plot(k, median(vals), 'w_', 'MarkerSize', 12, 'LineWidth', 2);
end

yline(1, '--k', 'LineWidth', 1.5);
set(gca, 'XTick', 1:numel(uniqueN), 'XTickLabel', string(uniqueN));
xlabel('Network Size N');
ylabel('Structural / Representation stabilization trial');
title('Ratio of structural to representation stabilization vs network size');
grid on;
%% 