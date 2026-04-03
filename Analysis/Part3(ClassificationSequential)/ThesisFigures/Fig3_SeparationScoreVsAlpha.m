% Fig3_SeparationScoreVsAlpha.m  (ThesisFigures/)
%
% Thesis Figure 3 — Cluster separation score (S) vs recall precision
% (alpha) with SEM bands and significance annotations.
%
% S_i = mean_offdiag(D_i) / D_ii  for each cluster i.
% Memory and Random groups are compared at each alpha using a one-sided
% Wilcoxon rank-sum test (*** p<0.001, ** p<0.01, * p<0.05, n.s.).
%
% Requires: clusterDistanceMatrices.mat (produced by Step4_plots.m)
%
% Run from the ThesisFigures/ directory (cd into it first).
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alphas (set below)

clear; clc;

visible = true;
doSave  = true;

N     = 400;
nMems = 25;
alphas = [0.1 0.3 0.5 0.7 0.9];

clusterMatPath = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems), "clusterDistanceMatrices.mat");
load(clusterMatPath, "clusterDictionary");

S_memory_mean = zeros(size(alphas));
S_random_mean = zeros(size(alphas));
S_memory_sem  = zeros(size(alphas));
S_random_sem  = zeros(size(alphas));
pvals         = zeros(size(alphas));

for aIdx = 1:numel(alphas)
    alphaKey = round(100 * alphas(aIdx));

    clusterData = clusterDictionary(alphaKey);
    mat = clusterData.mean_cluster_mat;
    labels = string(clusterData.uniqueGroups);

    nClusters = size(mat, 1);
    S_i = nan(nClusters, 1);
    for i = 1:nClusters
        row = mat(i,:);
        offdiag = row([1:i-1, i+1:end]);
        S_i(i) = mean(offdiag, 'omitnan') / mat(i,i);
    end

    is_mem = startsWith(labels, "m");
    is_rnd = startsWith(labels, "rnd");

    S_mem = S_i(is_mem);
    S_rnd = S_i(is_rnd);

    S_memory_mean(aIdx) = mean(S_mem, 'omitnan');
    S_random_mean(aIdx) = mean(S_rnd, 'omitnan');
    S_memory_sem(aIdx)  = std(S_mem, 'omitnan') / sqrt(sum(is_mem));
    S_random_sem(aIdx)  = std(S_rnd, 'omitnan') / sqrt(sum(is_rnd));
    pvals(aIdx) = ranksum(S_mem, S_rnd, 'tail', 'right');
end

%% Plot
figure('Color', 'w', 'Position', [100 100 700 450], 'Visible', visible);
hold on;

plot_shaded(alphas, S_memory_mean, S_memory_sem, [0.20 0.45 0.85]);
plot_shaded(alphas, S_random_mean, S_random_sem, [0.90 0.45 0.10]);

plot(alphas, S_memory_mean, '-o', 'LineWidth', 2.5, ...
    'Color', [0.20 0.45 0.85], 'MarkerFaceColor', [0.20 0.45 0.85], 'MarkerSize', 7);
plot(alphas, S_random_mean, '-o', 'LineWidth', 2.5, ...
    'Color', [0.90 0.45 0.10], 'MarkerFaceColor', [0.90 0.45 0.10], 'MarkerSize', 7);

yline(1, '--k', 'Overlap Threshold', 'LineWidth', 1.2);

xlabel('\alpha (Recall Precision)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Cluster Separation Score  $S$', 'Interpreter', 'latex', 'FontSize', 13);
title('\textbf{Separation Score vs Recall Precision}', ...
    'Interpreter', 'latex', 'FontSize', 16);

legend({'', '', 'Memory \pm SEM', 'Random \pm SEM', 'Overlap threshold'}, ...
    'Location', 'west');
set(gca, 'FontSize', 12, 'LineWidth', 1.2);
box on;
xlim([min(alphas)-0.02, max(alphas)+0.02]);
yl = ylim; ylim([min(yl(1), 1 - 0.1*range(yl)), max(yl(2), 1 + 0.1*range(yl))]);

% ---- Significance asterisks (Wilcoxon rank-sum, one-sided) ----
yl_top = ylim;
for aIdx = 1:numel(alphas)
    if pvals(aIdx) < 0.001,      stars = '***';
    elseif pvals(aIdx) < 0.01,   stars = '**';
    elseif pvals(aIdx) < 0.05,   stars = '*';
    else,                         stars = 'n.s.';
    end
    text(alphas(aIdx), yl_top(2) - 0.03*range(yl_top), stars, ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end

%% Save
if doSave
    savePath = fullfile(pwd, 'Output');
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    print(gcf, fullfile(savePath, 'Fig3_SeparationScoreVsAlpha'), '-dpng', '-r600');
    print(gcf, fullfile(savePath, 'Fig3_SeparationScoreVsAlpha'), '-dpdf');
end

%% Local function
function plot_shaded(x, y, e, faceColor)
    xx = [x, fliplr(x)];
    yy = [y+e, fliplr(y-e)];
    p = patch(xx, yy, faceColor, 'FaceAlpha', 0.18, 'EdgeColor', 'none');
    uistack(p, 'bottom');
end
