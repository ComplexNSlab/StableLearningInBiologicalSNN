% PlotSeparationVsAlpha_Shaded.m  (FigureScripts/)
%
% Enhanced version of PlotSeparationVsAlpha with shaded standard-error
% bands (SEM). Produces a two-panel figure:
%   Top panel  -- Mean cluster separation score (with shaded +/- SEM) for
%                 Memory (blue) and Random (orange) clusters vs alpha.
%   Bottom panel -- Delta-S (Memory mean - Random mean) vs alpha,
%                   quantifying the separation advantage of learned
%                   memories over random patterns (with propagated SEM).
%
% Requires: clusterDistanceMatrices.mat (produced by Step4_plots.m)
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alphas (set below)

clear; clc;

visible = true;
doSave = true;

N = 400;
nMems = 25;
alphas = [0.1 0.3 0.5 0.7 0.9];

clusterMatPath = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems), "clusterDistanceMatrices.mat");
load(clusterMatPath, "clusterDictionary");

S_memory_mean = zeros(size(alphas));
S_random_mean = zeros(size(alphas));
S_memory_sem  = zeros(size(alphas));
S_random_sem  = zeros(size(alphas));

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
        row_i = mean_cluster_mat(i,:);
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

    S_memory_sem(aIdx) = std(S_memory, 'omitnan') / sqrt(sum(is_memory));
    S_random_sem(aIdx) = std(S_random, 'omitnan') / sqrt(sum(is_random));
end

deltaS = S_memory_mean - S_random_mean;
deltaS_sem = sqrt(S_memory_sem.^2 + S_random_sem.^2);

%% Plot: top = shaded summary, bottom = gap
figure('Color','w','Position',[100 100 750 650],'Visible',visible);

% -------- Top panel --------
ax1 = subplot(2,1,1); hold on;

plot_shaded(alphas, S_memory_mean, S_memory_sem, [0.2 0.45 0.85]);
plot_shaded(alphas, S_random_mean, S_random_sem, [0.90 0.45 0.10]);

plot(alphas, S_memory_mean, '-o', 'LineWidth', 2.5, ...
    'Color', [0.2 0.45 0.85], 'MarkerFaceColor', [0.2 0.45 0.85], 'MarkerSize', 7);

plot(alphas, S_random_mean, '-o', 'LineWidth', 2.5, ...
    'Color', [0.90 0.45 0.10], 'MarkerFaceColor', [0.90 0.45 0.10], 'MarkerSize', 7);

yline(1, '--k', 'LineWidth', 1.2);

ylabel('Cluster Separation Score', 'FontSize', 13, 'FontWeight', 'bold');
title('\textbf{Cluster Separation vs Recall Precision}', ...
    'Interpreter', 'latex', 'FontSize', 18);

legend({'', '', 'Memory \pm SEM','Random \pm SEM'}, 'Location', 'northwest');
set(gca, 'FontSize', 12, 'LineWidth', 1.2);
box on;
xlim([min(alphas)-0.02, max(alphas)+0.02]);
yl = ylim; ylim([min(yl(1), 1 - 0.1*range(yl)), max(yl(2), 1 + 0.1*range(yl))]);

% -------- Bottom panel --------
ax2 = subplot(2,1,2); hold on;

plot_shaded(alphas, deltaS, deltaS_sem, [0.35 0.35 0.35]);

plot(alphas, deltaS, '-o', 'LineWidth', 2.5, ...
    'Color', [0.35 0.35 0.35], 'MarkerFaceColor', [0.35 0.35 0.35], 'MarkerSize', 7);

yline(0, '--k', 'LineWidth', 1.2);

xlabel('\alpha', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('\Delta S', 'FontSize', 13, 'FontWeight', 'bold');

title('\textbf{Separation Advantage of Memory over Random}', ...
    'Interpreter', 'latex', 'FontSize', 15);

set(gca, 'FontSize', 12, 'LineWidth', 1.2);
box on;
xlim([min(alphas)-0.02, max(alphas)+0.02]);
yl = ylim; ylim([min(yl(1), 0 - 0.1*range(yl)), max(yl(2), 0 + 0.1*range(yl))]);

linkaxes([ax1, ax2], 'x');

if doSave
    savePath = fullfile("..", "Results", "N"+num2str(N), "nMems"+num2str(nMems));
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    print(gcf, fullfile(savePath, 'SeparationVsAlpha_Shaded'), '-dpng', '-r600');
end

%% Local function
function plot_shaded(x, y, e, faceColor)
    xx = [x, fliplr(x)];
    yy = [y+e, fliplr(y-e)];
    p = patch(xx, yy, faceColor, ...
        'FaceAlpha', 0.18, 'EdgeColor', 'none');
    uistack(p, 'bottom');
end