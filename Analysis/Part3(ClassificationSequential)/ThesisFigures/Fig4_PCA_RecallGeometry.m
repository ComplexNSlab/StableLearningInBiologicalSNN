% Fig4_PCA_RecallGeometry.m  (ThesisFigures/)
%
% Thesis Figure 4 — Low-dimensional PCA projection of recall
% representations showing memory cluster geometry.
%
% For a chosen alpha, loads the time-delay recall vectors from one
% representative simulation, applies PCA, and plots a 2D scatter where
% each point is a single recall trial coloured by its memory identity.
% Random-pattern recalls are shown in grey.
%
% Run from the ThesisFigures/ directory (cd into it first).
%
% Produces a 1x2 figure:
%   Panel A: all memories + random (overview)
%   Panel B: zoomed into first few memories for clarity
%
% Requires: recalls25.mat (produced by Step2_Recalls)
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alpha, sim_id (set below)

clear; clc;

visible = true;
doSave  = true;

N     = 400;
nMems = 25;
alpha = 0.7;           % choose an alpha with good separation
sim_id = 1;            % which simulation folder to use (1-based index)
nMemsToHighlight = 5;  % number of memories to highlight in Panel B

%% Load recall data
rootFolder = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems));
entries = dir(rootFolder);
entries = entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}));

alphaStr = sprintf("alpha%d", round(100*alpha));
recallFile = fullfile(entries(sim_id).folder, entries(sim_id).name, ...
    "Recalls", alphaStr, sprintf("recalls%d.mat", nMems));

load(recallFile, 'delays', 'groups');

X = delays;           % [nTrials x N] time-delay features
labels = groups(:);   % string vector of group labels

%% PCA
X(isnan(X)) = 0;
[~, score, ~, ~, explained] = pca(X);

pc1 = score(:, 1);
pc2 = score(:, 2);

%% Assign colours
uniqueLabels = unique(labels, 'stable');
nGroups = numel(uniqueLabels);

% Memory labels get distinct colours, random gets grey
cmap_mem = lines(nMems);
colours  = zeros(numel(labels), 3);
markerSz = 15 * ones(numel(labels), 1);  % default size

for g = 1:nGroups
    idx = labels == uniqueLabels(g);
    if startsWith(uniqueLabels(g), "m")
        memNum = str2double(extractAfter(uniqueLabels(g), "m"));
        colours(idx, :) = repmat(cmap_mem(memNum, :), sum(idx), 1);
    else
        colours(idx, :) = repmat([0.7 0.7 0.7], sum(idx), 1);
        markerSz(idx) = 8;
    end
end

%% Plot
figure('Color', 'w', 'Position', [50 50 1400 550], 'Visible', visible);

% ---- Panel A: full overview ----
subplot(1, 2, 1); hold on;

% Plot random first (background)
is_rnd = startsWith(labels, "rnd");
scatter(pc1(is_rnd), pc2(is_rnd), markerSz(is_rnd), colours(is_rnd,:), ...
    'filled', 'MarkerFaceAlpha', 0.15);

% Plot memories on top
is_mem = startsWith(labels, "m");
scatter(pc1(is_mem), pc2(is_mem), markerSz(is_mem), colours(is_mem,:), ...
    'filled', 'MarkerFaceAlpha', 0.5);

xlabel(sprintf('PC1 (%.1f%%)', explained(1)), 'FontSize', 13, 'FontWeight', 'bold');
ylabel(sprintf('PC2 (%.1f%%)', explained(2)), 'FontSize', 13, 'FontWeight', 'bold');
title(sprintf('(A) All clusters, $\\alpha = %.1f$', alpha), ...
    'Interpreter', 'latex', 'FontSize', 14);
set(gca, 'FontSize', 11, 'LineWidth', 1.1); box on;

% ---- Panel B: highlighted subset ----
subplot(1, 2, 2); hold on;

% Background: random in light grey
scatter(pc1(is_rnd), pc2(is_rnd), 8, [0.85 0.85 0.85], ...
    'filled', 'MarkerFaceAlpha', 0.1);

% Foreground: first nMemsToHighlight memories with labels
highlighted = cell(nMemsToHighlight, 1);
for m = 1:nMemsToHighlight
    mLabel = sprintf("m%d", m);
    idx = labels == mLabel;
    scatter(pc1(idx), pc2(idx), 30, cmap_mem(m,:), 'filled', 'MarkerFaceAlpha', 0.7);
    % Add centroid label
    cx = mean(pc1(idx));
    cy = mean(pc2(idx));
    text(cx, cy, sprintf(' m%d', m), 'FontSize', 10, 'FontWeight', 'bold', ...
        'Color', cmap_mem(m,:) * 0.7);
    highlighted{m} = mLabel;
end

xlabel(sprintf('PC1 (%.1f%%)', explained(1)), 'FontSize', 13, 'FontWeight', 'bold');
ylabel(sprintf('PC2 (%.1f%%)', explained(2)), 'FontSize', 13, 'FontWeight', 'bold');
title(sprintf('(B) Highlighted memories 1–%d', nMemsToHighlight), 'FontSize', 14);
set(gca, 'FontSize', 11, 'LineWidth', 1.1); box on;

%% Save
if doSave
    savePath = fullfile(pwd, 'Output');
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    print(gcf, fullfile(savePath, 'Fig4_PCA_RecallGeometry'), '-dpng', '-r600');
    print(gcf, fullfile(savePath, 'Fig4_PCA_RecallGeometry'), '-dpdf');
end
