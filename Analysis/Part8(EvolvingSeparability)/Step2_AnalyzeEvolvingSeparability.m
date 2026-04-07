%% Step2_AnalyzeEvolvingSeparability.m — Part 8
%
% Computes and visualizes the evolving 21×21 separability matrix across
% sequential learning. Uses partial-cue probing data from Step1_Simulation.
%
% At each episode t (after learning memory t):
%   - Build 21 cluster centroids from probe TTFS
%   - Compute 21×21 pairwise distance matrix D(t)
%   - Compute per-memory separation score S_i(t)
%   - Split: S against learned neighbors vs unlearned neighbors
%
% If null-pattern probes are present (columns 22+ in TTFS), also computes
% separation scores for never-learned patterns as a concurrent baseline.
% The null patterns provide a ground-truth "chance" level: what separation
% you get from generic pattern completion at the current weight state.
%
% Produces:
%   1. Aligned S(t) curves: separability from LEARNED vs UNLEARNED memories
%   2. Intra-cluster spread tracking
%   3. Heatmap snapshots of the evolving 21×21 distance matrix
%   4. (If nulls available) Learned vs Null separation comparison
%
% Requires: ttfs_alpha{XX}_mem{1..100}.mat (from Step1_Simulation)

clc; clear;

%% -------- Parameters --------
N              = 400;
nMems          = 100;
nTrialsProbe   = 100;
nTracked       = 21;       % memories 40-60
trackedOffset  = 39;       % memory 40 = tracked index 1
alpha          = 0.7;
scale50Flag    = true;
showFig        = 'on';
saveFig        = false;

if scale50Flag
    scaleFolder = 'Scaled50';
else
    scaleFolder = 'Constant50';
end

alphaTag = sprintf("alpha%d", round(100 * alpha));
data_folder = fullfile(pwd, 'Data', scaleFolder, "N" + num2str(N));

items = dir(data_folder);
folderNames = {items([items.isdir]).name};
subfolderNames = folderNames(~ismember(folderNames, {'.', '..'}));
nSims = length(subfolderNames);

%% -------- Step 1: Load data & compute per-episode metrics --------

% Detect whether null patterns are present by checking first available file
has_null = false;
n_null   = 0;
for iter = 1:nSims
    simDir_check = fullfile(data_folder, subfolderNames{iter});
    fname_check = fullfile(simDir_check, sprintf("ttfs_%s_mem%d.mat", alphaTag, 1));
    if isfile(fname_check)
        info = whos('-file', fname_check, 'ttfs');
        if info.size(2) > nTracked
            has_null = true;
            n_null = info.size(2) - nTracked;
            fprintf("Detected %d null patterns in data.\n", n_null);
        end
        break;
    end
end

S_vs_learned   = nan(nSims, nTracked, nMems);
S_vs_unlearned = nan(nSims, nTracked, nMems);
S_total        = nan(nSims, nTracked, nMems);
spread_all     = nan(nSims, nTracked, nMems);
D_mean         = zeros(nTracked, nTracked, nMems);

% Null pattern metrics (if available)
if has_null
    S_null_total  = nan(nSims, n_null, nMems);   % separation of each null
    spread_null   = nan(nSims, n_null, nMems);
end

for iter = 1:nSims
    fprintf("Simulation %d/%d: %s\n", iter, nSims, subfolderNames{iter});
    simDir = fullfile(data_folder, subfolderNames{iter});

    centroids = nan(nTracked, N, nMems);
    spreads   = nan(nTracked, nMems);
    if has_null
        centroids_null = nan(n_null, N, nMems);
        spreads_null   = nan(n_null, nMems);
    end

    % --- Compute centroids & spreads from partial-cue TTFS ---
    for m = 1:nMems
        fname = fullfile(simDir, sprintf("ttfs_%s_mem%d.mat", alphaTag, m));
        if ~isfile(fname)
            continue;
        end
        loaded = load(fname, 'ttfs');   % ttfs: (N, 21+n_null, nTrialsProbe)

        for k = 1:nTracked
            trials = squeeze(loaded.ttfs(:, k, :));   % (N, nTrialsProbe)
            % Replace NaN (non-firing) with 0 for distance computation
            % so non-firing neurons contribute equally across memories
            trials(isnan(trials)) = 0;
            mu = mean(trials, 2);
            centroids(k, :, m) = mu;
            spreads(k, m) = mean(vecnorm(trials - mu, 2, 1));
        end

        % Null pattern centroids & spreads
        if has_null
            for ni = 1:n_null
                trials_n = squeeze(loaded.ttfs(:, nTracked + ni, :));
                trials_n(isnan(trials_n)) = 0;
                mu_n = mean(trials_n, 2);
                centroids_null(ni, :, m) = mu_n;
                spreads_null(ni, m) = mean(vecnorm(trials_n - mu_n, 2, 1));
            end
        end
    end

    spread_all(iter, :, :) = spreads;

    % --- At each episode, compute pairwise distances & separation scores ---
    for m = 1:nMems
        C = squeeze(centroids(:, :, m));            % (nTracked, N)
        if all(isnan(C(:))), continue; end
        D = squareform(pdist(C, 'euclidean'));       % (nTracked, nTracked)

        % Which tracked memories have been learned by episode m?
        is_learned = false(nTracked, 1);
        for k = 1:nTracked
            onset_k = trackedOffset + k;
            is_learned(k) = (m >= onset_k);
        end

        for ki = 1:nTracked
            intra = spreads(ki, m);
            if isnan(intra) || intra <= 0, continue; end

            others = [1:ki-1, ki+1:nTracked];
            learned_others   = others(is_learned(others));
            unlearned_others = others(~is_learned(others));

            % Total separation
            S_total(iter, ki, m) = mean(D(ki, others)) / intra;

            % Separation from learned neighbors
            if ~isempty(learned_others)
                S_vs_learned(iter, ki, m) = mean(D(ki, learned_others)) / intra;
            end

            % Separation from unlearned neighbors
            if ~isempty(unlearned_others)
                S_vs_unlearned(iter, ki, m) = mean(D(ki, unlearned_others)) / intra;
            end
        end

        % Accumulate distance matrix for mean across sims
        D_mean(:, :, m) = D_mean(:, :, m) + D;

        % --- Null pattern separation scores ---
        if has_null
            for ni = 1:n_null
                intra_n = spreads_null(ni, m);
                if isnan(intra_n) || intra_n <= 0, continue; end
                % Distance from null centroid to all 21 tracked centroids
                null_cent = centroids_null(ni, :, m);
                d_to_tracked = vecnorm(C - null_cent, 2, 2)'; % (1, nTracked)
                S_null_total(iter, ni, m) = mean(d_to_tracked) / intra_n;
            end
        end
    end
end

D_mean = D_mean / nSims;
fprintf("All metrics computed.\n");

%% -------- Step 2: Align to learning onset --------
maxPre       = trackedOffset + nTracked - 1;     % 59
maxPost      = nMems - trackedOffset - 1;         % 60
totalAligned = maxPre + 1 + maxPost;

aligned_S_total     = nan(nSims, nTracked, totalAligned);
aligned_S_learned   = nan(nSims, nTracked, totalAligned);
aligned_S_unlearned = nan(nSims, nTracked, totalAligned);
aligned_spread      = nan(nSims, nTracked, totalAligned);

for iter = 1:nSims
    for k = 1:nTracked
        onset = trackedOffset + k;
        for m = 1:nMems
            aidx = maxPre + (m - onset) + 1;
            aligned_S_total(iter, k, aidx)     = S_total(iter, k, m);
            aligned_S_learned(iter, k, aidx)   = S_vs_learned(iter, k, m);
            aligned_S_unlearned(iter, k, aidx) = S_vs_unlearned(iter, k, m);
            aligned_spread(iter, k, aidx)      = spread_all(iter, k, m);
        end
    end
end

x_aligned = (-maxPre : maxPost);

%% -------- Plot 1: S vs learned & unlearned on same axes --------
figure('Visible', showFig, 'Color', 'w'); hold on;
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 13 7];

% --- S vs unlearned ---
mean_u = squeeze(mean(aligned_S_unlearned, [1,2], 'omitnan'));
std_u  = squeeze(std(aligned_S_unlearned, 0, [1,2], 'omitnan'));
n_u    = squeeze(sum(~isnan(aligned_S_unlearned), [1,2]));
err_u  = 1.96 * std_u ./ sqrt(n_u);
vu = ~isnan(mean_u);
xu = x_aligned(vu); mu_u = mean_u(vu)'; eu = err_u(vu)';

patch([xu, fliplr(xu)], [mu_u-eu, fliplr(mu_u+eu)], ...
    [0.2 0.5 0.9], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
    'DisplayName', 'vs Unlearned \pm CI');
plot(xu, mu_u, '-', 'Color', [0.2 0.45 0.85], 'LineWidth', 2.5, ...
    'DisplayName', 'S vs Unlearned');

% --- S vs learned ---
mean_l = squeeze(mean(aligned_S_learned, [1,2], 'omitnan'));
std_l  = squeeze(std(aligned_S_learned, 0, [1,2], 'omitnan'));
n_l    = squeeze(sum(~isnan(aligned_S_learned), [1,2]));
err_l  = 1.96 * std_l ./ sqrt(n_l);
vl = ~isnan(mean_l);
xl = x_aligned(vl); ml = mean_l(vl)'; el = err_l(vl)';

patch([xl, fliplr(xl)], [ml-el, fliplr(ml+el)], ...
    [0.9 0.4 0.2], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
    'DisplayName', 'vs Learned \pm CI');
plot(xl, ml, '-', 'Color', [0.9 0.45 0.1], 'LineWidth', 2.5, ...
    'DisplayName', 'S vs Learned');

% --- Reference lines & shading ---
yline(1, '--k', 'LineWidth', 1.2, 'DisplayName', 'Overlap (S=1)');
yl = ylim; ymin = yl(1); ymax = yl(2);
patch([-0.5 -0.5 0.5 0.5], [ymin ymax ymax ymin], 'g', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.2, 'DisplayName', 'onset of learning');

xlabel("# New Memories Since Learning");
ylabel("Separation Score S");
title({"Separability: Learned vs Unlearned Neighbors", ...
    sprintf("\\alpha = %.0f%%, N = %d, nSims = %d", 100*alpha, N, nSims)});
legend('Location', 'northwest', 'Box', 'off');
xlim([x_aligned(1), x_aligned(end)]);
box on; set(gca, 'TickLength', [0 0]);

%% -------- Plot 2: Intra-cluster spread --------
figure('Visible', showFig, 'Color', 'w'); hold on;
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 13 7];

mean_sp = squeeze(mean(aligned_spread, [1,2], 'omitnan'));
std_sp  = squeeze(std(aligned_spread, 0, [1,2], 'omitnan'));
n_sp    = squeeze(sum(~isnan(aligned_spread), [1,2]));
err_sp  = 1.96 * std_sp ./ sqrt(n_sp);
vs = ~isnan(mean_sp);
xs = x_aligned(vs); ms = mean_sp(vs)'; es = err_sp(vs)';

patch([xs, fliplr(xs)], [ms-es, fliplr(ms+es)], ...
    [1 0.4 0.4], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', 'Mean \pm CI');
plot(xs, ms, '-', 'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', 'Mean');

yl = ylim; ymin = yl(1); ymax = yl(2);
patch([-0.5 -0.5 0.5 0.5], [ymin ymax ymax ymin], 'g', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.2, 'DisplayName', 'onset of learning');

xlabel("# New Memories Since Learning");
ylabel("Intra-cluster Spread");
title({"Cluster Tightness During Sequential Learning", ...
    sprintf("\\alpha = %.0f%%, N = %d, nSims = %d", 100*alpha, N, nSims)});
legend('Location', 'northwest', 'Box', 'off');
xlim([x_aligned(1), x_aligned(end)]);
box on; set(gca, 'TickLength', [0 0]);

%% -------- Plot 3: Heatmap snapshots of D(t) at key timepoints --------
snapshot_episodes = [30, 40, 45, 50, 55, 60, 70, 80];
mem_labels = "m" + string(40:60);

figure('Visible', showFig, 'Color', 'w');
fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 18 10];
nSnaps = length(snapshot_episodes);
nCols = ceil(sqrt(nSnaps));
nRows = ceil(nSnaps / nCols);

for si = 1:nSnaps
    ep = snapshot_episodes(si);
    if ep > nMems, continue; end
    subplot(nRows, nCols, si);
    D_snap = D_mean(:, :, ep);
    imagesc(D_snap); axis square; colormap(parula);

    % Mark which memories are learned by this episode
    for k = 1:nTracked
        onset_k = trackedOffset + k;
        if ep >= onset_k
            text(k, -0.3, char(10003), 'Color', 'g', 'FontSize', 8, ...
                'HorizontalAlignment', 'center');
        end
    end

    title(sprintf("After ep %d (%d learned)", ep, sum((40:60) <= ep)));
    xticks(1:nTracked); yticks(1:nTracked);
    xticklabels(mem_labels); yticklabels(mem_labels);
    xtickangle(90); set(gca, 'FontSize', 6);
    colorbar;
end
sgtitle(sprintf("Evolving 21x21 Distance Matrix (\\alpha = %.0f%%, N = %d)", ...
    100*alpha, N));

%% -------- Plot 4: Learned (aligned) vs Null baseline --------
if has_null
    % Align tracked-memory S_total to onset (already done above)
    % Null has no onset — compute mean S_null across episodes (flat baseline)

    figure('Visible', showFig, 'Color', 'w'); hold on;
    fig = gcf; fig.Units = 'inches'; fig.Position = [1 1 13 7];

    % --- Tracked memories (aligned, only post-learning) ---
    mean_t = squeeze(mean(aligned_S_total, [1,2], 'omitnan'));
    std_t  = squeeze(std(aligned_S_total, 0, [1,2], 'omitnan'));
    n_t    = squeeze(sum(~isnan(aligned_S_total), [1,2]));
    err_t  = 1.96 * std_t ./ sqrt(n_t);
    vt = ~isnan(mean_t);
    xt = x_aligned(vt); mt = mean_t(vt)'; et = err_t(vt)';

    patch([xt, fliplr(xt)], [mt-et, fliplr(mt+et)], ...
        [0.2 0.6 0.3], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
        'DisplayName', 'Learned \pm CI');
    plot(xt, mt, '-', 'Color', [0.1 0.5 0.15], 'LineWidth', 2.5, ...
        'DisplayName', 'Learned memories');

    % --- Null patterns (flat band across episodes) ---
    % Mean and CI across (nSims × n_null × nMems)
    null_flat = S_null_total(:);
    null_flat = null_flat(~isnan(null_flat));
    null_mean = mean(null_flat);
    null_err  = 1.96 * std(null_flat) / sqrt(length(null_flat));

    patch([x_aligned(1), x_aligned(1), x_aligned(end), x_aligned(end)], ...
        [null_mean-null_err, null_mean+null_err, null_mean+null_err, null_mean-null_err], ...
        [0.7 0.2 0.2], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'DisplayName', 'Null \pm CI');
    yline(null_mean, '--', 'Color', [0.7 0.15 0.15], 'LineWidth', 2, ...
        'DisplayName', sprintf('Null baseline (S=%.2f)', null_mean));

    % Also show null as time series (it may drift with weight state)
    null_ts_mean = squeeze(mean(S_null_total, [1,2], 'omitnan'));  % (nMems,1)
    % Map raw episodes to aligned x-axis: use trackedOffset+11 as center
    % (middle of tracked window = memory 50)
    center_mem = trackedOffset + 11;  % episode 50
    x_null_ts = (1:nMems) - center_mem;
    vn = ~isnan(null_ts_mean);
    plot(x_null_ts(vn), null_ts_mean(vn), ':', 'Color', [0.6 0.1 0.1], ...
        'LineWidth', 1.5, 'DisplayName', 'Null (episode trace)');

    % --- Onset marker ---
    yl = ylim; ymin = yl(1); ymax = yl(2);
    patch([-0.5 -0.5 0.5 0.5], [ymin ymax ymax ymin], 'g', ...
        'EdgeColor', 'none', 'FaceAlpha', 0.2, 'DisplayName', 'Learning onset');

    xlabel("# New Memories Since Learning");
    ylabel("Separation Score S");
    title({"Learned vs Never-Learned Separation Scores", ...
        sprintf("\\alpha = %.0f%%, N = %d, nSims = %d, nNull = %d", ...
        100*alpha, N, nSims, n_null)});
    legend('Location', 'northwest', 'Box', 'off');
    xlim([x_aligned(1), x_aligned(end)]);
    box on; set(gca, 'TickLength', [0 0]);
else
    fprintf("No null patterns detected — run updated Step1 to get null baseline.\n");
end

%% -------- Save --------
if saveFig
    savePath = fullfile(pwd, 'Results', scaleFolder, "N" + num2str(N));
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    print(1, fullfile(savePath, sprintf("S_learned_vs_unlearned_%s", alphaTag)), '-dpng', '-r600');
    print(2, fullfile(savePath, sprintf("spread_%s", alphaTag)), '-dpng', '-r600');
    print(3, fullfile(savePath, sprintf("heatmap_snapshots_%s", alphaTag)), '-dpng', '-r600');
    saveVars = {'S_total', 'S_vs_learned', 'S_vs_unlearned', 'spread_all', ...
                'D_mean', 'aligned_S_total', 'aligned_S_learned', ...
                'aligned_S_unlearned', 'aligned_spread', 'x_aligned'};
    if has_null
        print(4, fullfile(savePath, sprintf("S_learned_vs_null_%s", alphaTag)), '-dpng', '-r600');
        saveVars = [saveVars, {'S_null_total', 'spread_null'}];
    end
    save(fullfile(data_folder, sprintf("separability_partialcue_%s.mat", alphaTag)), ...
        saveVars{:});
end
