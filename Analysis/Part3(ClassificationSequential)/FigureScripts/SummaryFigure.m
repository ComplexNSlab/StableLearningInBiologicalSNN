% SummaryFigure.m  (FigureScripts/)
%
% Three-panel summary figure of cluster geometry across recall precisions.
%   Panel A -- Example inter-/intra-cluster Euclidean distance heatmap
%              at a chosen alpha.
%   Panel B -- Cluster separation score (S) vs alpha with shaded +/- std
%              bands for Memory and Random clusters.
%   Panel C -- Delta-S (Memory - Random separation advantage) vs alpha.
%
% Requires: clusterDistanceMatrices.mat (produced by Step4_plots.m)
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alphas, alphaExample (set below)

clear; clc;

visible = true;
doSave  = false;

% ---------------- Settings ----------------
N = 400;
nMems = 25;
alphas = [0.1 0.3 0.5 0.7 0.9];

% Choose which alpha to show for the heatmap panel
alphaExample = 0.7;
alphaExampleKey = round(100 * alphaExample);

clusterMatPath = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems), "clusterDistanceMatrices.mat");
load(clusterMatPath, "clusterDictionary");

% ---------------- Preallocate summary arrays ----------------
S_memory_mean = zeros(size(alphas));
S_random_mean = zeros(size(alphas));
S_memory_std  = zeros(size(alphas));
S_random_std  = zeros(size(alphas));
deltaS        = zeros(size(alphas));

% ---------------- Compute S summary across all alphas ----------------
for aIdx = 1:numel(alphas)
    alpha = alphas(aIdx);
    alphaKey = round(100 * alpha);

    clusterData = clusterDictionary(alphaKey);
    mean_cluster_mat = clusterData.mean_cluster_mat;
    labels = string(clusterData.uniqueGroups);

    nClusters = size(mean_cluster_mat, 1);

    diag_i = diag(mean_cluster_mat);
    mean_offdiag_i = nan(nClusters, 1);
    S_i = nan(nClusters, 1);

    for i = 1:nClusters
        row_i = mean_cluster_mat(i, :);
        offdiag_vals = row_i([1:i-1, i+1:end]);
        mean_offdiag_i(i) = mean(offdiag_vals, 'omitnan');
        S_i(i) = mean_offdiag_i(i) / diag_i(i);
    end

    is_memory = startsWith(labels, "m");
    is_random = startsWith(labels, "rnd");

    S_memory = S_i(is_memory);
    S_random = S_i(is_random);

    S_memory_mean(aIdx) = mean(S_memory, 'omitnan');
    S_random_mean(aIdx) = mean(S_random, 'omitnan');

    S_memory_std(aIdx) = std(S_memory, 'omitnan');
    S_random_std(aIdx) = std(S_random, 'omitnan');

    deltaS(aIdx) = S_memory_mean(aIdx) - S_random_mean(aIdx);
end

% ---------------- Load example heatmap data ----------------
clusterDataEx = clusterDictionary(alphaExampleKey);
mean_cluster_mat_ex = clusterDataEx.mean_cluster_mat;
labels_ex = string(clusterDataEx.uniqueGroups);

% Copy for plotting so diagonal can be hidden visually if desired
heatmap_plot = mean_cluster_mat_ex;
heatmap_plot(eye(size(heatmap_plot)) == 1) = NaN;

% ---------------- Figure ----------------
figure('Color', 'w', 'Position', [80 80 1500 450], 'Visible', visible);
t = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% ===== Panel A: heatmap =====
nexttile;
imagesc(heatmap_plot);
axis square;
colormap(parula);
set(gca, 'YDir', 'normal');

cb = colorbar;
cb.Label.String = 'Euclidean Distance';
cb.Label.FontSize = 11;
cb.Label.FontWeight = 'bold';

xticks(1:numel(labels_ex));
yticks(1:numel(labels_ex));
xticklabels(labels_ex);
yticklabels(labels_ex);
xtickangle(90);

xlabel('Cluster', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Cluster', 'FontSize', 11, 'FontWeight', 'bold');
title(sprintf('(A) Example distance matrix at $\\alpha = %.1f$', alphaExample), ...
    'Interpreter', 'latex', 'FontSize', 14);

set(gca, 'FontSize', 9, 'LineWidth', 1.1, 'TickLength', [0 0]);

% Optional dividing lines between memory and random blocks
hold on;
xline(nMems + 0.5, 'w-', 'LineWidth', 1.2);
yline(nMems + 0.5, 'w-', 'LineWidth', 1.2);

% ===== Panel B: S vs alpha with shaded std =====
nexttile; hold on;

plot_shaded(alphas, S_memory_mean, S_memory_std, [0.20 0.45 0.85]);
plot_shaded(alphas, S_random_mean, S_random_std, [0.90 0.45 0.10]);

plot(alphas, S_memory_mean, '-o', ...
    'Color', [0.20 0.45 0.85], ...
    'LineWidth', 2.3, ...
    'MarkerFaceColor', [0.20 0.45 0.85], ...
    'MarkerSize', 7);

plot(alphas, S_random_mean, '-o', ...
    'Color', [0.90 0.45 0.10], ...
    'LineWidth', 2.3, ...
    'MarkerFaceColor', [0.90 0.45 0.10], ...
    'MarkerSize', 7);

yline(1, '--k', 'LineWidth', 1.1);

xlabel('\alpha', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Cluster Separation Score', 'FontSize', 12, 'FontWeight', 'bold');
title('(B) Separation score vs recall precision', 'FontSize', 14);

legend({'Memory \pm std','','Random \pm std',''}, 'Location', 'northwest');
set(gca, 'FontSize', 11, 'LineWidth', 1.1);
box on;
xlim([min(alphas)-0.02, max(alphas)+0.02]);

% ===== Panel C: Delta S =====
nexttile; hold on;

plot(alphas, deltaS, '-o', ...
    'Color', [0.35 0.35 0.35], ...
    'LineWidth', 2.3, ...
    'MarkerFaceColor', [0.35 0.35 0.35], ...
    'MarkerSize', 7);

yline(0, '--k', 'LineWidth', 1.1);

xlabel('\alpha', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('\Delta S = S_{mem} - S_{rnd}', 'FontSize', 12, 'FontWeight', 'bold');
title('(C) Memory advantage over random', 'FontSize', 14);

set(gca, 'FontSize', 11, 'LineWidth', 1.1);
box on;
xlim([min(alphas)-0.02, max(alphas)+0.02]);

% Global title
title(t, '\textbf{Geometry of Recall Representations Across Recall Precision}', ...
    'Interpreter', 'latex', 'FontSize', 18);

% ---------------- Save ----------------
if doSave
    savePath = fullfile("..", "Results", "N"+num2str(N), "nMems"+num2str(nMems));
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    print(gcf, fullfile(savePath, 'SummaryFigure_ClusterGeometry'), '-dpng', '-r600');
    % print(gcf, fullfile(savePath, 'SummaryFigure_ClusterGeometry'), '-dpdf');
end

% ---------------- Local function ----------------
function plot_shaded(x, y, e, faceColor)
    xx = [x, fliplr(x)];
    yy = [y + e, fliplr(y - e)];
    p = patch(xx, yy, faceColor, ...
        'FaceAlpha', 0.18, ...
        'EdgeColor', 'none');
    uistack(p, 'bottom');
end