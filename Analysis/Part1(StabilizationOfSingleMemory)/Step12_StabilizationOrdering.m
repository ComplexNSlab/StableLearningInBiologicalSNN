% Step12_StabilizationOrdering.m
% =========================================================================
% Statistical analysis of the ordering among all four stabilization times:
%   1. First-spike order (representational)
%   2. Spike count (representational)
%   3. Latency (representational)
%   4. Radial (structural)
%
% For each network size and each simulation run that has all four valid
% stabilization times, the script:
%   - Ranks the four measures from earliest to latest
%   - Counts how often each pairwise ordering holds
%   - Reports the most common full ordering
%   - Runs paired sign tests on each of the 6 pairwise comparisons
%   - Produces a summary figure
%
% INPUTS:
%   Results/StabilizationResults/{paramTag}/DelaysThreshold_plateau.mat
%   Results/StabilizationResults/{paramTag}/SpikeCountsThreshold_plateau.mat
%   Results/StabilizationResults/{paramTag}/SpikeOrderThreshold_plateau.mat
%   Results/StabilizationResults/{paramTag}/RadialStabilityResults.mat
%
% OUTPUTS:
%   Console summary + figures
% =========================================================================

clc; clearvars('-except', 'show_figs'); close all;
if ~exist('show_figs', 'var'), show_figs = 'on'; end

%% Load config
cfg = jsondecode(fileread('config.json'));
paramTag = sprintf('frac%03d_smooth%d_hold%d', ...
    round(cfg.stabilityFrac * 100), cfg.smoothTrials, cfg.holdTrials);
resultsDir = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);

%% Load all four stabilization results
S1 = load(fullfile(resultsDir, 'DelaysThreshold_plateau.mat'));
S2 = load(fullfile(resultsDir, 'SpikeCountsThreshold_plateau.mat'));
S3 = load(fullfile(resultsDir, 'SpikeOrderThreshold_plateau.mat'));
S4 = load(fullfile(resultsDir, 'RadialStabilityResults.mat'));

delayThr = S1.delayThresholds;
spikeThr = S2.spikeThresholds;
orderThr = S3.orderThresholds;
Results  = S4.Results;

Ns = [Results.N];
measureNames = {'Spike Order', 'Spike Count', 'Latency', 'Structural'};
nMeasures = 4;

%% Collect all four stabilization times per run
% Columns: [order, spikeCount, latency, radial]
allData  = [];
allGroup = [];

for iN = 1:numel(Ns)
    N = Ns(iN);
    fieldN = sprintf('N%d', N);

    if ~isfield(delayThr, fieldN) || ~isfield(spikeThr, fieldN) || ~isfield(orderThr, fieldN)
        warning('Missing thresholds for N=%d, skipping.', N);
        continue;
    end

    tDelay = delayThr.(fieldN)(:);
    tSpike = spikeThr.(fieldN)(:);
    tOrder = orderThr.(fieldN)(:);
    tRadial = Results(iN).stabTrial(:);

    % Match lengths
    L = min([numel(tDelay), numel(tSpike), numel(tOrder), numel(tRadial)]);
    tDelay  = tDelay(1:L);
    tSpike  = tSpike(1:L);
    tOrder  = tOrder(1:L);
    tRadial = tRadial(1:L);

    % Keep only runs where all four are valid
    valid = ~isnan(tDelay) & ~isnan(tSpike) & ~isnan(tOrder) & ~isnan(tRadial);

    mat = [tOrder(valid), tSpike(valid), tDelay(valid), tRadial(valid)];

    allData  = [allData; mat];
    allGroup = [allGroup; N * ones(sum(valid), 1)];

    fprintf('N=%d: %d/%d runs with all four valid\n', N, sum(valid), L);
end

nTotal = size(allData, 1);
fprintf('\nTotal runs with all four stabilization times: %d\n\n', nTotal);

%% Per-run ranking
ranks = nan(nTotal, nMeasures);
for i = 1:nTotal
    [~, sortIdx] = sort(allData(i, :));
    r = nan(1, nMeasures);
    r(sortIdx) = 1:nMeasures;
    ranks(i, :) = r;
end

fprintf('=== Mean rank per measure (1 = earliest) ===\n');
for m = 1:nMeasures
    fprintf('  %12s: mean rank = %.2f ± %.2f\n', ...
        measureNames{m}, mean(ranks(:, m)), std(ranks(:, m)));
end

%% Friedman test (non-parametric repeated-measures ANOVA)
fprintf('\n=== Friedman test ===\n');
[pFriedman, tblFriedman, statsFriedman] = friedman(allData, 1, 'off');
fprintf('  Chi-sq = %.2f, df = %d, p = %.2e\n', ...
    tblFriedman{2,5}, tblFriedman{2,3}, pFriedman);

%% Post-hoc pairwise Wilcoxon signed-rank tests (Bonferroni-corrected)
fprintf('\n=== Pairwise post-hoc (Wilcoxon signed-rank, Bonferroni-corrected) ===\n');
nPairs = nchoosek(nMeasures, 2);
bonferroni = nPairs;  % 6 comparisons
fprintf('%-25s  %%A<B   %%A>B   p-raw        p-corrected  sig\n', 'Comparison');
fprintf('%s\n', repmat('-', 1, 85));

pairs = nchoosek(1:nMeasures, 2);
pValsRaw  = nan(size(pairs, 1), 1);
pValsBonf = nan(size(pairs, 1), 1);
winFracPairs = nan(size(pairs, 1), 1);

for p = 1:size(pairs, 1)
    a = pairs(p, 1);
    b = pairs(p, 2);

    diffs = allData(:, a) - allData(:, b);
    fracAearlier = mean(diffs < 0);
    fracAlater   = mean(diffs > 0);
    winFracPairs(p) = fracAearlier;

    % Two-sided Wilcoxon signed-rank test
    [pRaw, ~] = signrank(allData(:, a), allData(:, b));
    pCorrected = min(pRaw * bonferroni, 1);

    pValsRaw(p)  = pRaw;
    pValsBonf(p) = pCorrected;

    if pCorrected < 0.001, sigStr = '***';
    elseif pCorrected < 0.01, sigStr = '**';
    elseif pCorrected < 0.05, sigStr = '*';
    else, sigStr = 'n.s.';
    end

    label = sprintf('%s vs %s', measureNames{a}, measureNames{b});
    fprintf('%-25s  %5.1f  %5.1f   %.2e   %.2e   %s\n', ...
        label, 100*fracAearlier, 100*fracAlater, pRaw, pCorrected, sigStr);
end

% Store pairwise p-values in matrix form for the heatmap
pMatBonf = nan(nMeasures);
winFracMat = nan(nMeasures);
for p = 1:size(pairs, 1)
    a = pairs(p, 1);
    b = pairs(p, 2);
    pMatBonf(a, b) = pValsBonf(p);
    pMatBonf(b, a) = pValsBonf(p);
    winFracMat(a, b) = winFracPairs(p);
    winFracMat(b, a) = 1 - winFracPairs(p);
end

%% Most common full orderings
fprintf('\n=== Most common full orderings ===\n');
[~, orderIdx] = sort(allData, 2);
orderStrings = cell(nTotal, 1);
for i = 1:nTotal
    orderStrings{i} = strjoin(measureNames(orderIdx(i, :)), ' → ');
end

[uniqueOrders, ~, ic] = unique(orderStrings);
counts = accumarray(ic, 1);
[counts, sortI] = sort(counts, 'descend');
uniqueOrders = uniqueOrders(sortI);

nShow = min(10, numel(uniqueOrders));
for i = 1:nShow
    fprintf('  %3d/%d (%.1f%%)  %s\n', counts(i), nTotal, ...
        100*counts(i)/nTotal, uniqueOrders{i});
end

%% Per network size: fraction with canonical ordering
canonicalOrder = [1 2 3 4];  % order < spike < latency < radial
fprintf('\n=== Fraction with canonical ordering (Order < Spike < Latency < Radial) per N ===\n');
uniqueN = unique(allGroup);
for k = 1:numel(uniqueN)
    mask = allGroup == uniqueN(k);
    subData = allData(mask, :);
    nCanon = 0;
    for i = 1:size(subData, 1)
        [~, si] = sort(subData(i, :));
        if isequal(si, canonicalOrder)
            nCanon = nCanon + 1;
        end
    end
    fprintf('  N=%4d: %d/%d (%.1f%%)\n', uniqueN(k), nCanon, sum(mask), ...
        100*nCanon/sum(mask));
end

%% Shared settings
colors = [0.2 0.7 0.2;   % green — order
          0.9 0.3 0.3;   % red — spike count
          0.3 0.5 0.9;   % blue — latency
          0.6 0.4 0.8];  % purple — radial

uniqueN = unique(allGroup);
nN = numel(uniqueN);
meanRankByN = nan(nN, nMeasures);
for k = 1:nN
    mask = allGroup == uniqueN(k);
    meanRankByN(k, :) = mean(ranks(mask, :), 1);
end

% Compute median and IQR pairwise difference matrices (A − B)
medDiffMat = nan(nMeasures);
iqrDiffMat = nan(nMeasures);
for a = 1:nMeasures
    for b = 1:nMeasures
        if a ~= b
            d = allData(:, a) - allData(:, b);
            medDiffMat(a, b) = median(d);
            iqrDiffMat(a, b) = iqr(d);
        end
    end
end

%% Figure 1 (standalone): Mean rank per network size
figure('Units', 'inches', 'Position', [1, 1, 7, 4], 'Color', 'w', 'Visible', show_figs);
hold on;
for m = 1:nMeasures
    plot(uniqueN, meanRankByN(:, m), 'o-', ...
        'LineWidth', 2, 'Color', colors(m, :), ...
        'MarkerFaceColor', colors(m, :), 'MarkerSize', 6);
end
yline(2.5, '--k', 'LineWidth', 0.5);
xlabel('Network Size $N$', 'Interpreter', 'latex');
ylabel('Mean Rank (1 = earliest)', 'Interpreter', 'latex');
legend(measureNames, 'Location', 'best');
ylim([0.5 4.5]);
set(gca, 'YTick', 1:4);
grid on;

exportgraphics(gcf, fullfile(resultsDir, 'Step12_MeanRankByN.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');

%% Figure 2 (standalone): Boxplot of all four stabilization times
figure('Units', 'inches', 'Position', [1, 1, 6, 4.5], 'Color', 'w', 'Visible', show_figs);
hold on;
for m = 1:nMeasures
    boxchart(m * ones(nTotal, 1), allData(:, m), ...
        'BoxFaceColor', colors(m, :), ...
        'MarkerStyle', 'none', ...
        'BoxEdgeColor', 'none', ...
        'WhiskerLineColor', colors(m, :), ...
        'BoxMedianLineColor', colors(m, :), ...
        'LineWidth', 1.2, ...
        'BoxWidth', 0.5);
    jitter = (rand(nTotal, 1) - 0.5) * 0.25;
    scatter(m + jitter, allData(:, m), 3, 'k', 'filled', 'MarkerFaceAlpha', 0.15);
end
set(gca, 'XTick', 1:nMeasures, 'XTickLabel', measureNames);
ylabel('Stabilization Trial', 'Interpreter', 'latex');
grid on;

exportgraphics(gcf, fullfile(resultsDir, 'Step12_FourStabilizationTimes.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');

%% Figure 3 (standalone): Two-panel heatmap — win fraction + median [IQR]
figure('Units', 'inches', 'Position', [1, 1, 11, 4.5], 'Color', 'w', 'Visible', show_figs);

% --- Panel A: Win fraction ---
ax1 = subplot(1, 2, 1);
winFracPlot = winFracMat;
winFracPlot(eye(nMeasures)==1) = NaN;

imagesc(winFracPlot, [0 1]);
colormap(ax1, parula);
cb1 = colorbar;
cb1.Label.String = 'Fraction of runs';
cb1.Label.FontSize = 10;

hold on;
for i = 1:nMeasures
    patch([i-0.5 i+0.5 i+0.5 i-0.5], [i-0.5 i-0.5 i+0.5 i+0.5], ...
        [0.85 0.85 0.85], 'EdgeColor', 'none');
end

for a = 1:nMeasures
    for b = 1:nMeasures
        if a == b, continue; end
        wf = winFracMat(a, b);
        pc = pMatBonf(a, b);
        if pc < 0.001, sigStr = '***';
        elseif pc < 0.01, sigStr = '**';
        elseif pc < 0.05, sigStr = '*';
        else, sigStr = '';
        end
        txt = sprintf('%.2f%s', wf, sigStr);
        if wf > 0.6, clr = 'k'; else, clr = 'w'; end
        text(b, a, txt, 'HorizontalAlignment', 'center', ...
            'FontSize', 11, 'FontWeight', 'bold', 'Color', clr);
    end
end

set(ax1, 'XTick', 1:nMeasures, 'XTickLabel', measureNames, ...
    'YTick', 1:nMeasures, 'YTickLabel', measureNames, ...
    'TickLabelInterpreter', 'none', 'FontSize', 9);
xlabel('Measure B');
ylabel('Measure A');
title('(a)  P(A stabilizes before B)', 'FontWeight', 'bold');
axis square;

% --- Panel B: Median [IQR] difference ---
ax2 = subplot(1, 2, 2);
medDiffPlot = medDiffMat;
medDiffPlot(eye(nMeasures)==1) = NaN;
maxAbs = max(abs(medDiffMat(:)));

imagesc(medDiffPlot, [-maxAbs maxAbs]);

nCmap = 256;
blueToWhite = [linspace(0.2, 1, nCmap/2)', linspace(0.4, 1, nCmap/2)', linspace(0.8, 1, nCmap/2)'];
whiteToRed  = [linspace(1, 0.8, nCmap/2)', linspace(1, 0.2, nCmap/2)', linspace(1, 0.2, nCmap/2)'];
divCmap = [blueToWhite; whiteToRed];
colormap(ax2, divCmap);
cb2 = colorbar;
cb2.Label.String = 'Median difference (trials)';
cb2.Label.FontSize = 10;

hold on;
for i = 1:nMeasures
    patch([i-0.5 i+0.5 i+0.5 i-0.5], [i-0.5 i-0.5 i+0.5 i+0.5], ...
        [0.85 0.85 0.85], 'EdgeColor', 'none');
end

for a = 1:nMeasures
    for b = 1:nMeasures
        if a == b, continue; end
        md = medDiffMat(a, b);
        iq = iqrDiffMat(a, b);
        txt = sprintf('%.0f [%.0f]', md, iq);
        text(b, a, txt, 'HorizontalAlignment', 'center', ...
            'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k');
    end
end

set(ax2, 'XTick', 1:nMeasures, 'XTickLabel', measureNames, ...
    'YTick', 1:nMeasures, 'YTickLabel', measureNames, ...
    'TickLabelInterpreter', 'none', 'FontSize', 9);
xlabel('Measure B');
ylabel('Measure A');
title('(b)  Median [IQR] of A $-$ B (trials)', 'FontWeight', 'bold', 'Interpreter', 'latex');
axis square;

exportgraphics(gcf, fullfile(resultsDir, 'Step12_PairwiseOrdering.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step12_PairwiseOrdering'), '-dpng', '-r300');

%% Figure 4 (appendix): Two-panel — boxplot + mean rank by N
%  (a) Boxplot — absolute timescales
%  (b) Mean rank by N — within-run ordering

figure('Units', 'inches', 'Position', [1, 1, 12, 4.5], 'Color', 'w', 'Visible', show_figs);

% --- Panel (a): Boxplot ---
axA = subplot(1, 2, 1);
hold on;
for m = 1:nMeasures
    boxchart(m * ones(nTotal, 1), allData(:, m), ...
        'BoxFaceColor', colors(m, :), ...
        'MarkerStyle', 'none', ...
        'BoxEdgeColor', 'none', ...
        'WhiskerLineColor', colors(m, :), ...
        'BoxMedianLineColor', colors(m, :), ...
        'LineWidth', 1.2, ...
        'BoxWidth', 0.5);
    jitter = (rand(nTotal, 1) - 0.5) * 0.25;
    scatter(m + jitter, allData(:, m), 3, 'k', 'filled', 'MarkerFaceAlpha', 0.15);
end
set(axA, 'XTick', 1:nMeasures, 'XTickLabel', measureNames);
ylabel('Stabilization Trial', 'Interpreter', 'latex');
title('(a)  Stabilization times', 'FontWeight', 'bold');
grid on;

% --- Panel (b): Mean rank by N ---
axB = subplot(1, 2, 2);
hold on;
for m = 1:nMeasures
    plot(uniqueN, meanRankByN(:, m), 'o-', ...
        'LineWidth', 2, 'Color', colors(m, :), ...
        'MarkerFaceColor', colors(m, :), 'MarkerSize', 6);
end
yline(2.5, '--k', 'LineWidth', 0.5);
xlabel('Network Size $N$', 'Interpreter', 'latex');
ylabel('Mean Rank (1 = earliest)', 'Interpreter', 'latex');
legend(measureNames, 'Location', 'best');
ylim([0.5 4.5]);
set(axB, 'YTick', 1:4);
title('(b)  Within-run rank by network size', 'FontWeight', 'bold');
grid on;

exportgraphics(gcf, fullfile(resultsDir, 'Step12_AppendixOrdering.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');
print(gcf, fullfile(resultsDir, 'Step12_AppendixOrdering'), '-dpng', '-r300');

fprintf('\nFriedman test: chi-sq = %.2f, p = %.2e\n', tblFriedman{2,5}, pFriedman);
fprintf('Done.\n');
