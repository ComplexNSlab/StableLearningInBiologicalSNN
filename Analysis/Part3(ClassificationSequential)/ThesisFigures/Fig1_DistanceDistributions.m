% % Fig1_DistanceDistributions.m  (ThesisFigures/)
% %
% % Thesis Figure 1 — Distribution of intra- and inter-cluster Euclidean
% % distances across recall precision values (alpha).
% %
% % Layout: 2 rows x 5 columns (one column per alpha).
% %   Row 1: Intra-cluster KDEs — Memory (solid blue) vs Random (dashed red)
% %   Row 2: Inter-cluster KDEs — m-vs-m (solid), m-vs-rnd (dashed),
% %          rnd-vs-rnd (dotted)
% %
% % Run from the ThesisFigures/ directory (cd into it first).
% %
% % On first run the aggregation is cached to Output/Fig1_cache.mat.
% % Subsequent runs load the cache and skip straight to plotting.
% %
% % Requires: ClusterDistances.mat per simulation (produced by Step3)
% % Parameters: N, nMems, alphas (set below)
% 
% clear; clc;
% 
% visible = true;
% doSave  = true;
% 
% N     = 400;
% nMems = 25;
% alphas = [0.1 0.3 0.5 0.7 0.9];
% 
% %% Load or compute aggregated distances
% cacheDir  = fullfile(pwd, 'Output');
% cacheFile = fullfile(cacheDir, 'Fig1_cache.mat');
% 
% if isfile(cacheFile)
%     fprintf('Loading cached data from %s\n', cacheFile);
%     load(cacheFile, 'intra_mem', 'intra_rnd', 'inter_mm', 'inter_mr', 'inter_rr', 'alphas');
% else
%     rootFolder = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems));
%     entries = dir(rootFolder);
%     entries = entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}));
% 
%     intra_mem = cell(size(alphas));
%     intra_rnd = cell(size(alphas));
%     inter_mm  = cell(size(alphas));
%     inter_mr  = cell(size(alphas));
%     inter_rr  = cell(size(alphas));
% 
%     m_idx   = 1:nMems;
%     rnd_idx = nMems+1 : 2*nMems;
%     mask_ut = triu(true(nMems), 1);
% 
%     totalSteps = numel(alphas) * numel(entries);
%     stepCount  = 0;
%     wb = waitbar(0, 'Aggregating distances...', 'Name', 'Fig1 — Loading Data');
% 
%     for aIdx = 1:numel(alphas)
%         alpha = alphas(aIdx);
%         alphaStr = sprintf("alpha%d", round(100*alpha));
% 
%         chunks_intra_m = {};  chunks_intra_r = {};
%         chunks_mm = {};  chunks_mr = {};  chunks_rr = {};
% 
%         for s = 1:numel(entries)
%             stepCount = stepCount + 1;
%             waitbar(stepCount / totalSteps, wb, ...
%                 sprintf('\\alpha=%.1f  sim %d/%d  (%d/%d)', ...
%                 alpha, s, numel(entries), stepCount, totalSteps));
% 
%             f = fullfile(entries(s).folder, entries(s).name, "Recalls", alphaStr, "ClusterDistances.mat");
%             if ~isfile(f), continue; end
%             load(f, "intra_dists_all", "inter_dists_all");
% 
%             v = cellfun(@(c) c(:), intra_dists_all(m_idx), 'UniformOutput', false);
%             chunks_intra_m{end+1} = vertcat(v{:}); %#ok<AGROW>
% 
%             v = cellfun(@(c) c(:), intra_dists_all(rnd_idx), 'UniformOutput', false);
%             chunks_intra_r{end+1} = vertcat(v{:}); %#ok<AGROW>
% 
%             block = inter_dists_all(m_idx, m_idx);
%             v = cellfun(@(c) c(:), block(mask_ut), 'UniformOutput', false);
%             chunks_mm{end+1} = vertcat(v{:}); %#ok<AGROW>
% 
%             block = inter_dists_all(m_idx, rnd_idx);
%             v = cellfun(@(c) c(:), block(:), 'UniformOutput', false);
%             chunks_mr{end+1} = vertcat(v{:}); %#ok<AGROW>
% 
%             block = inter_dists_all(rnd_idx, rnd_idx);
%             v = cellfun(@(c) c(:), block(mask_ut), 'UniformOutput', false);
%             chunks_rr{end+1} = vertcat(v{:}); %#ok<AGROW>
%         end
% 
%         intra_mem{aIdx} = vertcat(chunks_intra_m{:});
%         intra_rnd{aIdx} = vertcat(chunks_intra_r{:});
%         inter_mm{aIdx}  = vertcat(chunks_mm{:});
%         inter_mr{aIdx}  = vertcat(chunks_mr{:});
%         inter_rr{aIdx}  = vertcat(chunks_rr{:});
%     end
% 
%     if isvalid(wb), close(wb); end
% 
%     % Cache for next time
%     if ~exist(cacheDir, 'dir'), mkdir(cacheDir); end
%     save(cacheFile, 'intra_mem', 'intra_rnd', 'inter_mm', 'inter_mr', 'inter_rr', 'alphas', '-v7.3');
%     fprintf('Cached aggregated data to %s\n', cacheFile);
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FigHeatmap_ClusterGeometry.m
%
% Build a cluster-level mean-distance heatmap from ClusterDistances.mat
% using the already-available intra_dists_all and inter_dists_all.
%
% Clusters 1:nMems        -> learned memories
% Clusters nMems+1:2*nMems -> random controls

clear; clc;

visible = true;
doSave  = true;

N      = 400;
nMems  = 25;
alphas = [0.1 0.3 0.5 0.7 0.9];
nClust = 2 * nMems;

cacheDir  = fullfile(pwd, 'Output');
cacheFile = fullfile(cacheDir, 'FigHeatmap_cache.mat');

if isfile(cacheFile)
    fprintf('Loading cached heatmap data from %s\n', cacheFile);
    load(cacheFile, 'meanDistMat', 'alphas');
else
    rootFolder = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems));
    entries = dir(rootFolder);
    entries = entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}));

    meanDistMat = cell(size(alphas));   % one 50x50 matrix per alpha

    totalSteps = numel(alphas) * numel(entries);
    stepCount  = 0;
    wb = waitbar(0, 'Building mean distance matrices...', ...
        'Name', 'Heatmap — Loading Data');

    for aIdx = 1:numel(alphas)
        alpha = alphas(aIdx);
        alphaStr = sprintf("alpha%d", round(100*alpha));

        simMatrices = nan(nClust, nClust, numel(entries));

        for s = 1:numel(entries)
            stepCount = stepCount + 1;
            waitbar(stepCount / totalSteps, wb, ...
                sprintf('\\alpha = %.1f   sim %d/%d   (%d/%d)', ...
                alpha, s, numel(entries), stepCount, totalSteps));

            f = fullfile(entries(s).folder, entries(s).name, ...
                "Recalls", alphaStr, "ClusterDistances.mat");
            if ~isfile(f)
                continue;
            end

            S = load(f, "intra_dists_all", "inter_dists_all");
            intra_dists_all = S.intra_dists_all;
            inter_dists_all = S.inter_dists_all;

            M = nan(nClust, nClust);

            % diagonal = mean intra-cluster distance
            for i = 1:nClust
                v = intra_dists_all{i};
                if ~isempty(v)
                    M(i,i) = mean(v(:), 'omitnan');
                end
            end

            % off-diagonal = mean inter-cluster distance
            for i = 1:nClust
                for j = 1:nClust
                    if i == j
                        continue;
                    end
                    v = inter_dists_all{i,j};
                    if ~isempty(v)
                        M(i,j) = mean(v(:), 'omitnan');
                    end
                end
            end

            simMatrices(:,:,s) = M;
        end

        meanDistMat{aIdx} = mean(simMatrices, 3, 'omitnan');
    end

    if isvalid(wb), close(wb); end

    if ~exist(cacheDir, 'dir')
        mkdir(cacheDir);
    end
    save(cacheFile, 'meanDistMat', 'alphas', '-v7.3');
    fprintf('Cached heatmap data to %s\n', cacheFile);
end

%% Plot one representative alpha heatmap
alphaTarget = 0.7;
aIdx = find(abs(alphas - alphaTarget) < 1e-12, 1);

if isempty(aIdx)
    error('Requested alpha not found.');
end

M = meanDistMat{aIdx};

figure('Color', 'w', 'Position', [100 100 700 620], 'Visible', visible);
imagesc(M);
axis square;
set(gca, 'YDir', 'normal');

colormap(parula);
cb = colorbar;
cb.Label.String = 'Mean Euclidean Distance';
cb.Label.FontSize = 12;

hold on;
xline(nMems + 0.5, 'w--', 'LineWidth', 2);
yline(nMems + 0.5, 'w--', 'LineWidth', 2);

title(sprintf('Cluster-level Recall Geometry, \\alpha = %.1f', alphaTarget), ...
    'FontSize', 15, 'FontWeight', 'bold');
xlabel('Cluster index', 'FontSize', 12);
ylabel('Cluster index', 'FontSize', 12);

set(gca, 'FontSize', 11, 'LineWidth', 1.2);

% optional text labels for blocks
text(6, 3, 'Memory vs Memory', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
text(31, 3, 'Memory vs Random', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
text(4, 31, 'Random vs Memory', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
text(31, 31, 'Random vs Random', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

if doSave
    outDir = fullfile(pwd, 'Output');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    exportgraphics(gcf, fullfile(outDir, 'FigHeatmap_ClusterGeometry_alpha07.png'), ...
        'Resolution', 300);
end

%% Plot 3 representative alphas
alphaShow = [0.3 0.5 0.9];
idxShow = arrayfun(@(a) find(abs(alphas-a) < 1e-12, 1), alphaShow);

% common color limits across panels
allVals = [];
for k = 1:numel(idxShow)
    allVals = [allVals; meanDistMat{idxShow(k)}(:)];
end
cLims = [min(allVals, [], 'omitnan'), max(allVals, [], 'omitnan')];

figure('Color', 'w', 'Position', [100 100 1500 450], 'Visible', visible);

for k = 1:numel(idxShow)
    subplot(1,3,k);
    M = meanDistMat{idxShow(k)};

    imagesc(M);
    axis square;
    set(gca, 'YDir', 'normal');
    colormap(parula);
    caxis(cLims);

    hold on;
    xline(nMems + 0.5, 'w--', 'LineWidth', 2);
    yline(nMems + 0.5, 'w--', 'LineWidth', 2);

    title(sprintf('\\alpha = %.1f', alphaShow(k)), ...
        'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Cluster index', 'FontSize', 11);
    ylabel('Cluster index', 'FontSize', 11);
    set(gca, 'FontSize', 10, 'LineWidth', 1.2);
end

cb = colorbar('Position', [0.92 0.15 0.015 0.7]);
cb.Label.String = 'Mean Euclidean Distance';
cb.Label.FontSize = 12;

sgtitle('Cluster-level Recall Geometry Across Recall Precision', ...
    'FontSize', 16, 'FontWeight', 'bold');

if doSave
    outDir = fullfile(pwd, 'Output');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    exportgraphics(gcf, fullfile(outDir, 'FigHeatmap_ClusterGeometry_3alphas.png'), ...
        'Resolution', 300);
end
%% Save
if doSave
    savePath = fullfile(pwd, 'Output');
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    print(gcf, fullfile(savePath, 'Fig1_DistanceDistributions'), '-dpng', '-r600');
    print(gcf, fullfile(savePath, 'Fig1_DistanceDistributions'), '-dpdf');
end
