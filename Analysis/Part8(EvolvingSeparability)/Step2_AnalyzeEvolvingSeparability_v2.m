%% Step2_AnalyzeEvolvingSeparability_v2.m — Part 8
%
% Computes evolving cluster separation scores during sequential learning,
% matching Part 3's trial-level distance methodology exactly.
%
% Method (same as Part 3 Step3_ComputeClusterDistances):
%   At each episode m, for a given alpha:
%   1. Stack all probe trials: X = (nClusters*nTrials, N)
%   2. Compute full pairwise Euclidean distance matrix: pdist(X)
%   3. Extract intra-cluster distances (upper triangle of within-group block)
%   4. Extract inter-cluster distances (all cross-group pairs)
%   5. S_i = mean(inter_i) / mean(intra_i)
%
% Non-firing neurons use 0 (matching Part 3's convention).
%
% If null-pattern probes exist (columns 22+ in TTFS), included as
% additional clusters for concurrent baseline.
%
% Produces:
%   1. Separation score S(t) aligned to learning onset
%   2. Intra-cluster distance over time
%   3. Heatmap snapshots of inter-cluster distance matrix
%   4. Multi-alpha comparison on one figure
%   5. (If nulls) Learned vs Null comparison
%
% Requires: ttfs_alpha{XX}_mem{1..100}.mat (from Step1_Simulation)
%           Run fix_absolute_timestamps.m first if data has absolute times.

clc; clear;

%% -------- Parameters --------
N              = 400;
nMems          = 100;
nTracked       = 21;       % memories 40-60
trackedOffset  = 39;       % memory 40 = tracked index 1
alphas_all     = [0.1, 0.3, 0.5, 0.7, 0.9];
scale50Flag    = true;
showFig        = 'on';
saveFig        = false;

if scale50Flag
    scaleFolder = 'Scaled50';
else
    scaleFolder = 'Constant50';
end

data_folder = fullfile(pwd, 'Data', scaleFolder, "N" + num2str(N));
items = dir(data_folder);
folderNames = {items([items.isdir]).name};
subfolderNames = folderNames(~ismember(folderNames, {'.', '..'}));
nSims = length(subfolderNames);

%% -------- Detect data format --------
has_null      = false;
n_null        = 0;
nTrialsProbe  = 20;  % default

for iter = 1:nSims
    simDir_check = fullfile(data_folder, subfolderNames{iter});
    alphaTag_check = sprintf("alpha%d", round(100 * alphas_all(1)));
    fname_check = fullfile(simDir_check, sprintf("ttfs_%s_mem%d.mat", alphaTag_check, 1));
    if isfile(fname_check)
        info = whos('-file', fname_check, 'ttfs');
        nTrialsProbe = info.size(3);
        if info.size(2) > nTracked
            has_null = true;
            n_null = info.size(2) - nTracked;
            fprintf("Detected %d null patterns.\n", n_null);
        end
        fprintf("nTrialsProbe = %d\n", nTrialsProbe);
        break;
    end
end

nClusters = nTracked + n_null;

%% -------- Compute separation scores for all alphas --------
results = struct();

for alpha_idx = 1:numel(alphas_all)
    alpha = alphas_all(alpha_idx);
    alphaTag = sprintf("alpha%d", round(100 * alpha));
    fprintf("\n===== alpha = %.1f =====\n", alpha);

    S_tracked  = nan(nSims, nTracked, nMems);
    intra_tracked = nan(nSims, nTracked, nMems);
    if has_null
        S_null     = nan(nSims, n_null, nMems);
        intra_null = nan(nSims, n_null, nMems);
    end
    % Mean distance matrix (nClusters x nClusters x nMems) across sims
    D_mean = zeros(nClusters, nClusters, nMems);
    D_count = zeros(1, nMems);

    for iter = 1:nSims
        fprintf("  Sim %d/%d: %s\n", iter, nSims, subfolderNames{iter});
        simDir = fullfile(data_folder, subfolderNames{iter});

        for m = 1:nMems
            fname = fullfile(simDir, sprintf("ttfs_%s_mem%d.mat", alphaTag, m));
            if ~isfile(fname), continue; end
            loaded = load(fname, 'ttfs');
            ttfs = loaded.ttfs;  % (N, nClusters, nTrialsProbe)

            % NaN → 0 (Part 3 convention: 0 = non-firing neuron)
            ttfs(isnan(ttfs)) = 0;

            % Stack into feature matrix: (nClusters*nTrials, N)
            nT = size(ttfs, 3);
            X = zeros(nClusters * nT, N);
            for c = 1:nClusters
                rows = (c-1)*nT + 1 : c*nT;
                X(rows, :) = squeeze(ttfs(:, c, :))';
            end

            % Full pairwise Euclidean distance matrix
            dMat = squareform(pdist(X, 'euclidean'));

            % Per-cluster intra and inter distances (Part 3 style)
            mean_cluster_mat = nan(nClusters, nClusters);
            for ci = 1:nClusters
                idx_i = (ci-1)*nT + 1 : ci*nT;

                % Intra-cluster: upper triangle
                D_ii = dMat(idx_i, idx_i);
                intra_vals = D_ii(triu(true(nT), 1));
                mean_cluster_mat(ci, ci) = mean(intra_vals);

                % Inter-cluster
                for cj = ci+1:nClusters
                    idx_j = (cj-1)*nT + 1 : cj*nT;
                    D_ij = dMat(idx_i, idx_j);
                    mean_cluster_mat(ci, cj) = mean(D_ij(:));
                    mean_cluster_mat(cj, ci) = mean_cluster_mat(ci, cj);
                end
            end

            % Separation score: S_i = mean(off-diag row i) / diagonal(i)
            for ci = 1:nClusters
                intra_i = mean_cluster_mat(ci, ci);
                if isnan(intra_i) || intra_i <= 0, continue; end
                others = [1:ci-1, ci+1:nClusters];
                inter_i = mean(mean_cluster_mat(ci, others), 'omitnan');
                S_i = inter_i / intra_i;

                if ci <= nTracked
                    S_tracked(iter, ci, m)     = S_i;
                    intra_tracked(iter, ci, m) = intra_i;
                elseif has_null
                    ni = ci - nTracked;
                    S_null(iter, ni, m)     = S_i;
                    intra_null(iter, ni, m) = intra_i;
                end
            end

            D_mean(:,:,m) = D_mean(:,:,m) + mean_cluster_mat;
            D_count(m) = D_count(m) + 1;
        end
    end

    % Normalize accumulated distance matrix
    for m = 1:nMems
        if D_count(m) > 0
            D_mean(:,:,m) = D_mean(:,:,m) / D_count(m);
        end
    end

    results(alpha_idx).alpha         = alpha;
    results(alpha_idx).S_tracked     = S_tracked;
    results(alpha_idx).intra_tracked = intra_tracked;
    results(alpha_idx).D_mean        = D_mean;
    if has_null
        results(alpha_idx).S_null     = S_null;
        results(alpha_idx).intra_null = intra_null;
    end
end

fprintf("\nAll alphas processed.\n");

%% -------- Align to learning onset --------
maxPre       = trackedOffset + nTracked - 1;
maxPost      = nMems - trackedOffset - 1;
totalAligned = maxPre + 1 + maxPost;
x_aligned    = (-maxPre : maxPost);

for ai = 1:numel(alphas_all)
    aligned_S     = nan(nSims, nTracked, totalAligned);
    aligned_intra = nan(nSims, nTracked, totalAligned);

    for iter = 1:nSims
        for k = 1:nTracked
            onset = trackedOffset + k;
            for m = 1:nMems
                aidx = maxPre + (m - onset) + 1;
                if aidx >= 1 && aidx <= totalAligned
                    aligned_S(iter, k, aidx)     = results(ai).S_tracked(iter, k, m);
                    aligned_intra(iter, k, aidx) = results(ai).intra_tracked(iter, k, m);
                end
            end
        end
    end

    results(ai).aligned_S     = aligned_S;
    results(ai).aligned_intra = aligned_intra;
end

%% ======== PLOTS ========
detail_idx = find([results.alpha] == 0.7, 1);
if isempty(detail_idx), detail_idx = ceil(numel(alphas_all)/2); end
alpha_detail = results(detail_idx).alpha;

%% -------- Plot 1: Separation score (single alpha, aligned) --------
figure('Visible', showFig, 'Color', 'w'); hold on;
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 13 7];

aS = results(detail_idx).aligned_S;
mean_S = squeeze(mean(aS, [1,2], 'omitnan'));
std_S  = squeeze(std(aS, 0, [1,2], 'omitnan'));
n_S    = squeeze(sum(~isnan(aS), [1,2]));
err_S  = 1.96 * std_S ./ sqrt(n_S);
v = ~isnan(mean_S);
xv = x_aligned(v); mv = mean_S(v)'; ev = err_S(v)';

patch([xv, fliplr(xv)], [mv-ev, fliplr(mv+ev)], ...
    [0.2 0.5 0.9], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
    'DisplayName', 'Mean \pm 95% CI');
plot(xv, mv, '-', 'Color', [0.1 0.3 0.7], 'LineWidth', 2.5, ...
    'DisplayName', 'Tracked memories');

% Null baseline
if has_null && isfield(results(detail_idx), 'S_null')
    null_flat = results(detail_idx).S_null(:);
    null_flat = null_flat(~isnan(null_flat));
    if ~isempty(null_flat)
        null_mean = mean(null_flat);
        null_err  = 1.96 * std(null_flat) / sqrt(length(null_flat));
        patch([x_aligned(1), x_aligned(1), x_aligned(end), x_aligned(end)], ...
            [null_mean-null_err, null_mean+null_err, null_mean+null_err, null_mean-null_err], ...
            [0.7 0.2 0.2], 'FaceAlpha', 0.15, 'EdgeColor', 'none', ...
            'DisplayName', 'Null \pm CI');
        yline(null_mean, '--', 'Color', [0.7 0.15 0.15], 'LineWidth', 2, ...
            'DisplayName', sprintf('Null (S=%.2f)', null_mean));
    end
end

yline(1, ':k', 'LineWidth', 1, 'DisplayName', 'S = 1 (overlap)');
yl = ylim;
patch([-0.5 -0.5 0.5 0.5], [yl(1) yl(2) yl(2) yl(1)], 'g', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.2, 'DisplayName', 'Learning onset');

xlabel("# New Memories Since Learning");
ylabel("Cluster Separation Score S");
title({"Cluster Separation (trial-level distances)", ...
    sprintf("\\alpha = %.0f%%, N = %d, nSims = %d, nTrials = %d", ...
    100*alpha_detail, N, nSims, nTrialsProbe)});
legend('Location', 'best', 'Box', 'off');
xlim([x_aligned(1), x_aligned(end)]);
box on; set(gca, 'TickLength', [0 0]);

%% -------- Plot 2: Intra-cluster distance (aligned) --------
figure('Visible', showFig, 'Color', 'w'); hold on;
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 13 7];

aI = results(detail_idx).aligned_intra;
mean_I = squeeze(mean(aI, [1,2], 'omitnan'));
std_I  = squeeze(std(aI, 0, [1,2], 'omitnan'));
n_I    = squeeze(sum(~isnan(aI), [1,2]));
err_I  = 1.96 * std_I ./ sqrt(n_I);
vi = ~isnan(mean_I);
xi = x_aligned(vi); mi = mean_I(vi)'; ei = err_I(vi)';

patch([xi, fliplr(xi)], [mi-ei, fliplr(mi+ei)], ...
    [1 0.4 0.4], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', 'Mean \pm CI');
plot(xi, mi, '-', 'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', 'Mean');

yl = ylim;
patch([-0.5 -0.5 0.5 0.5], [yl(1) yl(2) yl(2) yl(1)], 'g', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.2, 'DisplayName', 'Learning onset');

xlabel("# New Memories Since Learning");
ylabel("Mean Intra-cluster Distance (Euclidean)");
title({"Cluster Tightness", ...
    sprintf("\\alpha = %.0f%%, N = %d, nSims = %d", 100*alpha_detail, N, nSims)});
legend('Location', 'best', 'Box', 'off');
xlim([x_aligned(1), x_aligned(end)]);
box on; set(gca, 'TickLength', [0 0]);

%% -------- Plot 3: Heatmap snapshots --------
snapshot_episodes = [30, 40, 45, 50, 55, 60, 70, 80];
mem_labels = "m" + string(40:60);

figure('Visible', showFig, 'Color', 'w');
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 18 10];
nSnaps = length(snapshot_episodes);
nCols = ceil(sqrt(nSnaps));
nRows = ceil(nSnaps / nCols);

D_mat = results(detail_idx).D_mean;

for si = 1:nSnaps
    ep = snapshot_episodes(si);
    if ep > nMems, continue; end
    subplot(nRows, nCols, si);
    D_snap = D_mat(1:nTracked, 1:nTracked, ep);
    imagesc(D_snap); axis square; colormap(parula);

    for k = 1:nTracked
        if ep >= trackedOffset + k
            text(k, -0.3, char(10003), 'Color', 'g', 'FontSize', 8, ...
                'HorizontalAlignment', 'center');
        end
    end

    title(sprintf("Ep %d (%d learned)", ep, sum((40:60) <= ep)));
    xticks(1:3:nTracked); yticks(1:3:nTracked);
    xticklabels(mem_labels(1:3:nTracked)); yticklabels(mem_labels(1:3:nTracked));
    xtickangle(90); set(gca, 'FontSize', 6); colorbar;
end
sgtitle(sprintf("Inter-Cluster Distance Matrix (\\alpha = %.0f%%, N = %d)", ...
    100*alpha_detail, N));

%% -------- Plot 4: Multi-alpha comparison --------
figure('Visible', showFig, 'Color', 'w'); hold on;
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 13 7];

colors_alpha = [0.3 0.3 0.9;
                0.1 0.6 0.5;
                0.9 0.6 0.1;
                0.9 0.3 0.1;
                0.6 0.1 0.6];

for ai = 1:numel(alphas_all)
    aS = results(ai).aligned_S;
    mS = squeeze(mean(aS, [1,2], 'omitnan'));
    vv = ~isnan(mS);
    ci = min(ai, size(colors_alpha, 1));
    plot(x_aligned(vv), mS(vv)', '-', 'Color', colors_alpha(ci,:), ...
        'LineWidth', 2, 'DisplayName', sprintf('\\alpha = %.1f', alphas_all(ai)));
end

yline(1, ':k', 'LineWidth', 1, 'HandleVisibility', 'off');
yl = ylim;
patch([-0.5 -0.5 0.5 0.5], [yl(1) yl(2) yl(2) yl(1)], 'g', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.2, 'DisplayName', 'Learning onset');

xlabel("# New Memories Since Learning");
ylabel("Cluster Separation Score S");
title({"Separation Across Cue Strengths", ...
    sprintf("N = %d, nSims = %d", N, nSims)});
legend('Location', 'best', 'Box', 'off');
xlim([x_aligned(1), x_aligned(end)]);
box on; set(gca, 'TickLength', [0 0]);

%% -------- Save --------
if saveFig
    savePath = fullfile(pwd, 'Results', scaleFolder, "N" + num2str(N));
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    save(fullfile(data_folder, "separability_results_v2.mat"), 'results', ...
        'x_aligned', 'alphas_all', 'has_null', 'n_null', 'nTrialsProbe');
end
