%% SeparabilityCapacityAnalysis.m
% Analysis of memory capacity and distinguishability.
%
% Experiment: A network of N neurons encodes M memories, then retrieves
% each memory AND each of M non-memories (random patterns) using a partial
% cue of strength alpha. Four similarity measures are computed:
%
%   s_intra_memory : coherence of repeated retrievals of the same memory
%   s_inter_mem    : confusion between different memories' retrievals
%   s_intra_rand   : coherence of repeated retrievals of the same non-memory
%   s_inter_rand   : confusion between memory and non-memory retrievals
%
% If the network has truly learned, memories should be retrieved more
% coherently (s_intra_memory > s_intra_rand) and be more separable from
% each other than random patterns are.

%% Load data
clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

N_list     = sort(unique(T.N));
alpha_list = sort(unique(T.alpha));
M_list     = sort(unique(T.M));

fprintf('Data: %d rows | N = {%s} | M = %d–%d | alpha = %.2f–%.2f\n', ...
    height(T), strjoin(string(N_list), ', '), min(M_list), max(M_list), ...
    min(alpha_list), max(alpha_list));

% Representative alpha for single-alpha panels
alpha_rep = 0.1;
if ~any(abs(alpha_list - alpha_rep) < 1e-6)
    alpha_rep = alpha_list(round(end/2));
end

% Subplot layout for per-N panels
nN    = length(N_list);
nCols = ceil(sqrt(nN));
nRows = ceil(nN / nCols);

safeSEM = @(x) std(x, 'omitnan') / sqrt(sum(~isnan(x)));

%% 1. Similarity Landscape — All 4 raw measures vs M
% The "big picture": how does each similarity measure evolve as memory
% load increases? One subplot per network size, at alpha = alpha_rep.
%
% What to look for:
%  - s_intra_memory (blue)  should start high and decline with M
%  - s_intra_rand   (gray)  should be lower — the random baseline
%  - The gap between them is the "learning signal"
%  - s_inter_mem    (red)   should stay low — distinct memories
%  - s_inter_rand   (orange) tracks memory-vs-random confusion

figure('Name', 'Similarity Landscape', 'Position', [50 50 1400 800]);

measures = {'s_intra_memory', 's_intra_rand', 's_inter_mem', 's_inter_rand'};
labels   = {'Intra-Memory', 'Intra-Random', 'Inter-Memory', 'Memory-vs-Random'};
colors   = [0.2 0.4 0.8;  0.5 0.5 0.5;  0.8 0.2 0.2;  0.9 0.6 0.1];
styles   = {'-o', '--s', '-^', '--d'};

for ni = 1:nN
    T_sub = T(T.N == N_list(ni) & abs(T.alpha - alpha_rep) < 1e-6, :);
    if isempty(T_sub), continue; end

    [G, Mvals] = findgroups(T_sub.M);

    subplot(nRows, nCols, ni); hold on; grid on;

    for mi = 1:4
        mu  = splitapply(@mean, T_sub.(measures{mi}), G);
        sem = splitapply(safeSEM, T_sub.(measures{mi}), G);
        errorbar(Mvals, mu, sem, styles{mi}, 'Color', colors(mi,:), ...
            'LineWidth', 1.2, 'MarkerSize', 3, 'DisplayName', labels{mi});
    end

    set(gca, 'XScale', 'log');
    xlabel('M'); ylabel('Similarity');
    title(sprintf('N = %d', N_list(ni)));
    ylim([0 1]);
    if ni == nN, legend('Location', 'bestoutside', 'FontSize', 7); end
end
sgtitle(sprintf('Similarity Landscape (\\alpha = %.2f)', alpha_rep), 'FontSize', 14);

%% 2. Memory vs Random Coherence — Has the network learned?
% Direct comparison: s_intra_memory (solid) vs s_intra_rand (dashed)
% for selected cue strengths. Solid above dashed = network has learned.
% When they converge, memories become indistinguishable from random.

alpha_show = [0.1, 0.3, 0.5, 0.8];
alpha_show = alpha_show(ismember(round(alpha_show,2), round(alpha_list,2)));

figure('Name', 'Memory vs Random Coherence', 'Position', [50 50 1400 800]);

for ni = 1:nN
    subplot(nRows, nCols, ni); hold on; grid on;
    cmap_as = cool(length(alpha_show));

    for ai = 1:length(alpha_show)
        T_sub = T(T.N == N_list(ni) & abs(T.alpha - alpha_show(ai)) < 1e-6, :);
        if isempty(T_sub), continue; end

        [G, Mvals] = findgroups(T_sub.M);
        mu_mem  = splitapply(@mean, T_sub.s_intra_memory, G);
        mu_rand = splitapply(@mean, T_sub.s_intra_rand, G);

        plot(Mvals, mu_mem, '-o', 'Color', cmap_as(ai,:), ...
            'LineWidth', 1.5, 'MarkerSize', 3, ...
            'DisplayName', sprintf('\\alpha=%.1f', alpha_show(ai)));
        plot(Mvals, mu_rand, '--', 'Color', cmap_as(ai,:), ...
            'LineWidth', 1, 'HandleVisibility', 'off');
    end

    set(gca, 'XScale', 'log');
    xlabel('M'); ylabel('Retrieval Coherence');
    title(sprintf('N = %d', N_list(ni)));
    ylim([0 1]);
    if ni == nN, legend('Location', 'bestoutside', 'FontSize', 7); end
end
sgtitle('Memory Coherence (solid) vs Random Baseline (dashed)', 'FontSize', 14);

%% 3. Memory Advantage — Learning signal across all conditions
% Delta = s_intra_memory - s_intra_rand.
% Positive = network retrieves memories more coherently than non-memories.
% This controls for baseline activity — a pure measure of learning.

figure('Name', 'Memory Advantage', 'Position', [50 50 1400 800]);

for ni = 1:nN
    subplot(nRows, nCols, ni); hold on; grid on;
    cmap_alpha = turbo(length(alpha_list));

    for ai = 1:length(alpha_list)
        T_sub = T(T.N == N_list(ni) & abs(T.alpha - alpha_list(ai)) < 1e-6, :);
        if isempty(T_sub), continue; end

        T_sub.advantage = T_sub.s_intra_memory - T_sub.s_intra_rand;
        [G, Mvals] = findgroups(T_sub.M);
        mu = splitapply(@mean, T_sub.advantage, G);

        plot(Mvals, mu, '-', 'Color', cmap_alpha(ai,:), 'LineWidth', 0.8, ...
            'DisplayName', sprintf('\\alpha=%.2f', alpha_list(ai)));
    end

    set(gca, 'XScale', 'log');
    xlabel('M'); ylabel('\Delta = s_{intra,mem} - s_{intra,rand}');
    title(sprintf('N = %d', N_list(ni)));
    yline(0, '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    if ni == nN, legend('Location', 'bestoutside', 'FontSize', 5); end
end
sgtitle('Memory Advantage over Random (> 0 = network learned)', 'FontSize', 14);

%% 4. Separability: Memory vs Random — Capacity criterion
% Memory separability  = s_intra_memory - s_inter_mem
%   (memory retrieval looks like itself, not other memories)
% Random "separability" = s_intra_rand - s_inter_rand
%   (baseline: how "separable" are random patterns the network never learned?)
%
% When memory separability drops to random level, capacity is reached.

figure('Name', 'Separability Comparison', 'Position', [50 50 1400 800]);

for ni = 1:nN
    T_sub = T(T.N == N_list(ni) & abs(T.alpha - alpha_rep) < 1e-6, :);
    if isempty(T_sub), continue; end

    T_sub.sep_mem  = T_sub.s_intra_memory - T_sub.s_inter_mem;
    T_sub.sep_rand = T_sub.s_intra_rand   - T_sub.s_inter_rand;

    [G, Mvals] = findgroups(T_sub.M);
    mu_mem  = splitapply(@mean,   T_sub.sep_mem,  G);
    sem_mem = splitapply(safeSEM, T_sub.sep_mem,  G);
    mu_rnd  = splitapply(@mean,   T_sub.sep_rand, G);
    sem_rnd = splitapply(safeSEM, T_sub.sep_rand, G);

    subplot(nRows, nCols, ni); hold on; grid on;
    errorbar(Mvals, mu_mem, sem_mem, '-o', 'Color', [0.2 0.4 0.8], ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Memory');
    errorbar(Mvals, mu_rnd, sem_rnd, '--s', 'Color', [0.6 0.6 0.6], ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Random');

    set(gca, 'XScale', 'log');
    xlabel('M'); ylabel('Separability (intra - inter)');
    title(sprintf('N = %d', N_list(ni)));
    yline(0, ':k', 'HandleVisibility', 'off');
    if ni == 1, legend('Location', 'best', 'FontSize', 8); end
end
sgtitle(sprintf('Memory Separability vs Random Separability (\\alpha = %.2f)', ...
    alpha_rep), 'FontSize', 14);

%% 5. Critical Capacity vs Network Size
% M_crit = M where memory separability falls to random-separability level.
% This is a principled, non-arbitrary threshold: the network can no longer
% separate memories better than it "separates" random patterns.
% Uses log-interpolation for smooth estimates.

capacityTable = table('Size', [0 3], ...
    'VariableTypes', {'double','double','double'}, ...
    'VariableNames', {'N','alpha','M_crit'});

for ai = 1:length(alpha_list)
    a_val = alpha_list(ai);
    for ni = 1:length(N_list)
        T_sub = T(T.N == N_list(ni) & abs(T.alpha - a_val) < 1e-6, :);
        if isempty(T_sub)
            capacityTable = [capacityTable; {N_list(ni), a_val, NaN}];
            continue;
        end

        % delta = memory_separability - random_separability
        T_sub.delta = (T_sub.s_intra_memory - T_sub.s_inter_mem) ...
                    - (T_sub.s_intra_rand   - T_sub.s_inter_rand);

        [G, Mvals] = findgroups(T_sub.M);
        mu_delta = splitapply(@mean, T_sub.delta, G);

        % Find crossing: delta goes from positive to ≤ 0
        idx = find(mu_delta(1:end-1) > 0 & mu_delta(2:end) <= 0, 1, 'first');
        if ~isempty(idx)
            % Log-interpolation between bracketing M values
            logM = log(Mvals);
            M_crit_val = exp(logM(idx) + (logM(idx+1) - logM(idx)) * ...
                mu_delta(idx) / (mu_delta(idx) - mu_delta(idx+1)));
        elseif all(mu_delta > 0)
            M_crit_val = max(Mvals);  % capacity exceeds tested range
        else
            M_crit_val = NaN;
        end

        capacityTable = [capacityTable; {N_list(ni), a_val, M_crit_val}];
    end
end

% --- Plot ---
figure('Name', 'Critical Capacity vs N', 'Position', [100 100 800 500]);
hold on; grid on;
cmap_alpha = turbo(length(alpha_list));

for ai = 1:length(alpha_list)
    ct = capacityTable(abs(capacityTable.alpha - alpha_list(ai)) < 1e-6, :);
    valid = ~isnan(ct.M_crit);
    if any(valid)
        plot(ct.N(valid), ct.M_crit(valid), '-o', 'Color', cmap_alpha(ai,:), ...
            'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('\\alpha=%.2f', alpha_list(ai)));
    end
end

xlabel('Network Size (N)');
ylabel('Critical Capacity M_{crit}');
title('Capacity vs Network Size (sep_{mem} = sep_{rand} crossing)');
legend('Location', 'bestoutside', 'FontSize', 7);
set(gca, 'XScale', 'log', 'YScale', 'log');

%% 6. Capacity Scaling — M_crit / N
% If capacity scales linearly with N (Hopfield-like), M_crit/N is constant.
% Sub-linear scaling means larger networks are proportionally less efficient.

figure('Name', 'Capacity Scaling', 'Position', [100 100 800 500]);
hold on; grid on;

for ai = 1:length(alpha_list)
    ct = capacityTable(abs(capacityTable.alpha - alpha_list(ai)) < 1e-6, :);
    valid = ~isnan(ct.M_crit);
    if any(valid)
        plot(ct.N(valid), ct.M_crit(valid) ./ ct.N(valid), '-o', ...
            'Color', cmap_alpha(ai,:), 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('\\alpha=%.2f', alpha_list(ai)));
    end
end

xlabel('Network Size (N)');
ylabel('M_{crit} / N');
title('Capacity Scaling — Is M_{crit} Proportional to N?');
legend('Location', 'bestoutside', 'FontSize', 7);
yline(0.138, ':k', 'Hopfield limit (0.138N)', 'FontSize', 8, ...
    'LabelHorizontalAlignment', 'left');

%% 7. Capacity vs Cue Strength (alpha)
% For each N, how does cue strength modulate capacity?

figure('Name', 'Capacity vs Alpha', 'Position', [100 100 800 500]);
hold on; grid on;
cmap_N = lines(length(N_list));

for ni = 1:length(N_list)
    ct = capacityTable(capacityTable.N == N_list(ni), :);
    valid = ~isnan(ct.M_crit);
    if any(valid)
        plot(ct.alpha(valid), ct.M_crit(valid), '-o', 'Color', cmap_N(ni,:), ...
            'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('N=%d', N_list(ni)));
    end
end

xlabel('Cue Strength (\alpha)');
ylabel('Critical Capacity M_{crit}');
title('How Cue Strength Affects Capacity');
legend('Location', 'best');

%% 8. Capacity Heatmap — M_crit(N, alpha)
capMat = NaN(length(N_list), length(alpha_list));
for ai = 1:length(alpha_list)
    for ni = 1:length(N_list)
        idx = capacityTable.N == N_list(ni) & ...
              abs(capacityTable.alpha - alpha_list(ai)) < 1e-6;
        if any(idx)
            capMat(ni, ai) = capacityTable.M_crit(idx);
        end
    end
end

figure('Name', 'Capacity Heatmap', 'Position', [100 100 900 500]);
imagesc(alpha_list, 1:length(N_list), capMat);
set(gca, 'YDir', 'normal', 'YTick', 1:length(N_list), ...
    'YTickLabel', string(N_list));
colorbar;
colormap(turbo);
xlabel('\alpha (cue strength)');
ylabel('Network Size (N)');
title('Critical Capacity M_{crit}');

for r = 1:size(capMat, 1)
    for c = 1:size(capMat, 2)
        if ~isnan(capMat(r, c))
            text(alpha_list(c), r, sprintf('%.0f', capMat(r, c)), ...
                'HorizontalAlignment', 'center', 'FontSize', 6, 'Color', 'w');
        end
    end
end
