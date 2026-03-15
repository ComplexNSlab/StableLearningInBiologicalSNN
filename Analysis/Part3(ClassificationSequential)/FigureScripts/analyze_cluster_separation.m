% analyze_cluster_separation.m  (FigureScripts/)
%
% Computes and visualizes a per-cluster separation score S_i for a single
% alpha value. S_i is defined as the ratio of the mean inter-cluster
% distance to the intra-cluster distance for each cluster. The script:
%   1. Loads precomputed cluster distance matrices from Step4.
%   2. Computes S_i for every cluster and splits results into Memory vs
%      Random groups.
%   3. Plots a bar chart of per-cluster S_i and a violin plot comparing
%      the Memory and Random distributions.
%   4. Optionally saves figures and a results struct to disk.
%
% Requires: clusterDistanceMatrices.mat (produced by Step4_plots.m)
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alpha (set below)

clear; clc;

visible = false;
doSave  = true;

% ---- Set parameters ----
N = 400;
nMems = 25;
alpha = 0.3;
alphaKey = round(100 * alpha);

% ---- Load saved cluster-level data ----
clusterMatPath = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems), "clusterDistanceMatrices.mat");
load(clusterMatPath, "clusterDictionary");

clusterData = clusterDictionary(alphaKey);
mean_cluster_mat = clusterData.mean_cluster_mat;
uniqueGroups = clusterData.uniqueGroups;
nSims = clusterData.nSims;

% Save results in Results folder
savePath = fullfile("..", "Results", "N"+num2str(N), ...
    "nMems"+num2str(nMems), ...
    "alpha"+num2str(round(100*alpha)));

if doSave && ~exist(savePath, 'dir')
    mkdir(savePath);
end

%% Compute cluster separation score S_i
nClusters = size(mean_cluster_mat, 1);
cluster_labels = string(uniqueGroups(:));

diag_i = diag(mean_cluster_mat);
mean_offdiag_i = nan(nClusters, 1);
S_i = nan(nClusters, 1);

for ii = 1:nClusters
    row_i = mean_cluster_mat(ii, :);
    offdiag_vals = row_i([1:ii-1, ii+1:end]);
    mean_offdiag_i(ii) = mean(offdiag_vals, 'omitnan');
    S_i(ii) = mean_offdiag_i(ii) / diag_i(ii);
end

is_memory = startsWith(cluster_labels, "m");
is_random = startsWith(cluster_labels, "rnd");

S_memory = S_i(is_memory);
S_random = S_i(is_random);

%% Plot per-cluster S_i
figure('Color', 'w', 'Position', [100, 100, 1100, 450], 'Visible', visible);

b = bar(S_i, 'FaceColor', 'flat'); hold on;
for k = 1:nClusters
    if is_memory(k)
        b.CData(k,:) = [0.2 0.45 0.85];
    else
        b.CData(k,:) = [0.9 0.55 0.2];
    end
end

yline(1, '--k', 'LineWidth', 1.2);

xticks(1:nClusters);
xticklabels(cluster_labels);
xtickangle(90);

xlabel('Cluster', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('$S_i = \frac{\mathrm{mean}_{j\neq i}(D_{ij})}{D_{ii}}$', ...
    'Interpreter', 'latex', 'FontSize', 13);

title(sprintf(['\\textbf{Cluster Separation Score}\n' ...
    'Across %d Simulations, $\\alpha = %.1f\\%%$'], ...
    nSims, 100*alpha), ...
    'Interpreter', 'latex', 'FontSize', 14);

set(gca, 'FontSize', 11, 'LineWidth', 1.2, 'TickLength', [0 0]);
box on;

if doSave
    print(gcf, fullfile(savePath, 'SeparationScore_perCluster'), '-dpng', '-r600');
end

%% Plot memory vs random distribution of S_i
sep_labels = [repmat("Memory", numel(S_memory), 1);
              repmat("Random", numel(S_random), 1)];
sep_values = [S_memory; S_random];
sep_cat = categorical(sep_labels, ["Memory", "Random"], 'Ordinal', true);

figure('Color', 'w', 'Position', [100, 100, 500, 450], 'Visible', visible);
violinplot(sep_cat, sep_values); hold on;
yline(1, '--k', 'LineWidth', 1.2);

ylabel('$S_i$', 'Interpreter', 'latex', 'FontSize', 13);
xlabel('Cluster Type', 'FontSize', 12, 'FontWeight', 'bold');

title(sprintf(['\\textbf{Distribution of Cluster Separation Scores}\n' ...
    'Across %d Simulations, $\\alpha = %.1f\\%%$'], ...
    nSims, 100*alpha), ...
    'Interpreter', 'latex', 'FontSize', 14);

set(gca, 'FontSize', 11, 'LineWidth', 1.2, 'TickLength', [0 0]);
box on;

if doSave
    print(gcf, fullfile(savePath, 'SeparationScore_MemoryVsRandom'), '-dpng', '-r600');
end

%% Save results
sepStruct = struct();
sepStruct.cluster_labels = cluster_labels;
sepStruct.mean_cluster_mat = mean_cluster_mat;
sepStruct.diag_i = diag_i;
sepStruct.mean_offdiag_i = mean_offdiag_i;
sepStruct.S_i = S_i;
sepStruct.S_memory = S_memory;
sepStruct.S_random = S_random;
sepStruct.alpha = alpha;
sepStruct.nSims = nSims;

if doSave
    save(fullfile(savePath, 'SeparationScoreData.mat'), 'sepStruct');
end