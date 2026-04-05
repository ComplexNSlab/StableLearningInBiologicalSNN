% Fig2_MeanDistancesVsAlpha.m  (ThesisFigures/)
%
% Thesis Figure 2 — Mean intra- and inter-cluster Euclidean distances as
% a function of recall precision (alpha).
%
% Two curves on one panel:
%   - Mean intra-cluster distance (recall stability)
%   - Mean inter-cluster distance (memory separability)
% Error bands show +/- SEM across clusters.
%
% Run from the ThesisFigures/ directory (cd into it first).
%
% Requires: ClusterDistances.mat per simulation (produced by Step3)
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alphas (set below)

clear; clc;

visible = true;
doSave  = true;

N     = 400;
nMems = 25;
alphas = [0.1 0.3 0.5 0.7 0.9];

rootFolder = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems));
entries = dir(rootFolder);
entries = entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}));

m_idx   = 1:nMems;
rnd_idx = nMems+1 : 2*nMems;

%% Compute per-cluster means at each alpha, then average across simulations
% For each alpha we collect per-simulation summary vectors, then report
% mean +/- SEM across simulations.

intra_mem_sim = zeros(numel(entries), numel(alphas));
intra_rnd_sim = zeros(numel(entries), numel(alphas));
inter_mm_sim  = zeros(numel(entries), numel(alphas));
inter_mr_sim  = zeros(numel(entries), numel(alphas));
inter_rr_sim  = zeros(numel(entries), numel(alphas));

totalSteps = numel(alphas) * numel(entries);
stepCount  = 0;
wb = waitbar(0, 'Computing mean distances...', 'Name', 'Fig2 — Loading Data');

for aIdx = 1:numel(alphas)
    alpha = alphas(aIdx);
    alphaStr = sprintf("alpha%d", round(100*alpha));

    for s = 1:numel(entries)
        stepCount = stepCount + 1;
        waitbar(stepCount / totalSteps, wb, ...
            sprintf('\\alpha=%.1f  sim %d/%d  (%d/%d)', ...
            alpha, s, numel(entries), stepCount, totalSteps));

        f = fullfile(entries(s).folder, entries(s).name, "Recalls", alphaStr, "ClusterDistances.mat");
        if ~isfile(f), continue; end
        load(f, "intra_dists_all", "inter_dists_all");

        % Mean intra — memory clusters
        vals = cellfun(@(c) mean(c(:), 'omitnan'), intra_dists_all(m_idx));
        intra_mem_sim(s, aIdx) = mean(vals, 'omitnan');

        % Mean intra — random clusters
        vals = cellfun(@(c) mean(c(:), 'omitnan'), intra_dists_all(rnd_idx));
        intra_rnd_sim(s, aIdx) = mean(vals, 'omitnan');

        % Mean inter m-vs-m
        mask = triu(true(nMems), 1);
        block = cellfun(@(c) mean(c(:), 'omitnan'), inter_dists_all(m_idx, m_idx));
        inter_mm_sim(s, aIdx) = mean(block(mask), 'omitnan');

        % Mean inter m-vs-rnd
        block = cellfun(@(c) mean(c(:), 'omitnan'), inter_dists_all(m_idx, rnd_idx));
        inter_mr_sim(s, aIdx) = mean(block(:), 'omitnan');

        % Mean inter rnd-vs-rnd
        block = cellfun(@(c) mean(c(:), 'omitnan'), inter_dists_all(rnd_idx, rnd_idx));
        inter_rr_sim(s, aIdx) = mean(block(mask), 'omitnan');
    end
end

if isvalid(wb), close(wb); end

nSims = numel(entries);

% Summary statistics across simulations
intra_mem_mean = mean(intra_mem_sim, 1);  intra_mem_se = std(intra_mem_sim, 0, 1) / sqrt(nSims);
intra_rnd_mean = mean(intra_rnd_sim, 1);  intra_rnd_se = std(intra_rnd_sim, 0, 1) / sqrt(nSims);
inter_mm_mean  = mean(inter_mm_sim, 1);   inter_mm_se  = std(inter_mm_sim, 0, 1) / sqrt(nSims);
inter_mr_mean  = mean(inter_mr_sim, 1);   inter_mr_se  = std(inter_mr_sim, 0, 1) / sqrt(nSims);
inter_rr_mean  = mean(inter_rr_sim, 1);   inter_rr_se  = std(inter_rr_sim, 0, 1) / sqrt(nSims);

%% Plot
figure('Color', 'w', 'Position', [100 100 700 500], 'Visible', visible);
hold on;

% Intra
plot_shaded(alphas, intra_mem_mean, intra_mem_se, [0.20 0.45 0.85]);
h1 = plot(alphas, intra_mem_mean, '-o', 'LineWidth', 2.5, ...
    'Color', [0.20 0.45 0.85], 'MarkerFaceColor', [0.20 0.45 0.85], 'MarkerSize', 7);

plot_shaded(alphas, intra_rnd_mean, intra_rnd_se, [0.90 0.45 0.10]);
h2 = plot(alphas, intra_rnd_mean, '-o', 'LineWidth', 2.5, ...
    'Color', [0.90 0.45 0.10], 'MarkerFaceColor', [0.90 0.45 0.10], 'MarkerSize', 7);

% Inter
plot_shaded(alphas, inter_mm_mean, inter_mm_se, [0.30 0.70 0.30]);
h3 = plot(alphas, inter_mm_mean, '-s', 'LineWidth', 2.5, ...
    'Color', [0.30 0.70 0.30], 'MarkerFaceColor', [0.30 0.70 0.30], 'MarkerSize', 7);

plot_shaded(alphas, inter_mr_mean, inter_mr_se, [0.60 0.30 0.60]);
h4 = plot(alphas, inter_mr_mean, '-s', 'LineWidth', 2.5, ...
    'Color', [0.60 0.30 0.60], 'MarkerFaceColor', [0.60 0.30 0.60], 'MarkerSize', 7);

plot_shaded(alphas, inter_rr_mean, inter_rr_se, [0.50 0.50 0.50]);
h5 = plot(alphas, inter_rr_mean, '-s', 'LineWidth', 2.5, ...
    'Color', [0.50 0.50 0.50], 'MarkerFaceColor', [0.50 0.50 0.50], 'MarkerSize', 7);

legend([h1 h2 h3 h4 h5], ...
    {'Intra: memory', 'Intra: random', ...
     'Inter: m vs m', 'Inter: m vs rnd', 'Inter: rnd vs rnd'}, ...
    'Location', 'best');

xlabel('\alpha (Recall Precision)', 'FontWeight', 'bold');
ylabel('Mean Euclidean Distance', 'FontWeight', 'bold');
title('\textbf{Cluster Distances vs Recall Precision}', ...
    'Interpreter', 'latex');

set(gca, 'LineWidth', 1.2);
box on;
xlim([min(alphas)-0.02, max(alphas)+0.02]);

%% Save
if doSave
    savePath = fullfile(pwd, 'Output');
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    print(gcf, fullfile(savePath, 'Fig2_MeanDistancesVsAlpha'), '-dpng', '-r600');
    print(gcf, fullfile(savePath, 'Fig2_MeanDistancesVsAlpha'), '-dpdf');
end

%% Local function
function plot_shaded(x, y, e, faceColor)
    xx = [x, fliplr(x)];
    yy = [y+e, fliplr(y-e)];
    p = patch(xx, yy, faceColor, 'FaceAlpha', 0.18, 'EdgeColor', 'none');
    uistack(p, 'bottom');
end
