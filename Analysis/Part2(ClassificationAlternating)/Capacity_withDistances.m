%% Section 1: Intra/Inter Distance & Separability vs M (single N, single alpha)
% Plots intra-memory distance, inter-memory distance, and their
% separability gap as a function of M for fixed N and alpha.

clc; clear;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

figure; hold on; grid on;

% === Set fixed parameters ===
for N_target = [400];
    alpha_target = 0.1;   % Choose the alpha you want to fix
    
    % === Filter rows ===
    T_sub = T(T.N == N_target & abs(T.alpha - alpha_target) < 1e-6, :);
    T_sub = sortrows(T_sub, 'M');
    
    % === Plot ===
    plot(T_sub.M, 1-T_sub.s_intra_memory, 'o', 'DisplayName', 'Intra-Memory');
    % plot(T_sub.M, 1-T_sub.s_intra_rand, '-s', 'DisplayName', 'Intra-Random');
    plot(T_sub.M, 1-T_sub.s_inter_mem, 'o', 'DisplayName', 'Inter-Memory');
    % plot(T_sub.M, 1-T_sub.s_inter_rand, '-^', 'DisplayName', 'Inter-Random');
    
    xlabel('Number of Memories (M)');
    ylabel('Mean Distance (1 - Similarity)');
    title(sprintf('Distance Metrics vs. M (N = %d, \\alpha = %.2f)', N_target, alpha_target));
    legend('Location', 'best');
    
    sep = abs(T_sub.s_intra_memory - T_sub.s_inter_mem);
    % figure; 
    plot(T_sub.M, sep, '--k', 'LineWidth', 1.5, 'DisplayName', 'Separability');
end
set(gca, 'xscale', 'log')
% ylim([0 1])
%% Section 2: Separability Ratio vs M for different N (fixed alpha)
% For a fixed alpha, plots the separability ratio (intra/inter similarity)
% vs M for each network size N. Reveals how capacity scales with N.

clc; clear;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

% === Set fixed alpha ===
alpha_target = 0.8;

% === Get all unique network sizes (N) ===
N_list = unique(T.N);

% === Initialize plot ===
figure; hold on; grid on;

colors = lines(length(N_list));

for i = 1:length(N_list)
    N_val = N_list(i);

    % Filter by N and alpha
    T_sub = T(T.N == N_val & abs(T.alpha - alpha_target) < 1e-6, :);
    if isempty(T_sub), continue; end

    T_sub = sortrows(T_sub, 'M');

    % Compute separability ratio
    sep = T_sub.s_intra_memory./T_sub.s_inter_mem ;

    % Plot
    plot(T_sub.M, sep, '-', ...
        'DisplayName', sprintf('N = %d', N_val), ...
        'LineWidth', 1.5, 'Color', colors(i,:));
end

xlabel('Number of Memories (M)');
ylabel('Separability Ratio (Intra / Inter Similarity)');
title(sprintf('Separability vs. M for Different N (\\alpha = %.2f)', alpha_target));
legend('Location', 'best');
set(gca, 'xscale', 'log');
%% Section 3: Intra/Inter Distance & Separability vs M with Error Bars (single N, single alpha)
% Top subplot: intra-memory and inter-memory distances (mean ± SEM).
% Bottom subplot: separability gap (inter - intra distance).

clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

N_target = 400;
alpha_target = 0.80;

T_sub = T(T.N == N_target & abs(T.alpha - alpha_target) < 1e-6, :);
T_sub = sortrows(T_sub, 'M');

% Convert similarities to distances
T_sub.intraMemDist = 1 - T_sub.s_intra_memory;
T_sub.interMemDist = 1 - T_sub.s_inter_mem;

% Separability gap: inter - intra
T_sub.sepGap = T_sub.interMemDist - T_sub.intraMemDist;

% Aggregate by M
[G, Mvals] = findgroups(T_sub.M);

meanIntra = splitapply(@mean, T_sub.intraMemDist, G);
meanInter = splitapply(@mean, T_sub.interMemDist, G);
meanSep   = splitapply(@mean, T_sub.sepGap, G);

semIntra = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.intraMemDist, G);
semInter = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.interMemDist, G);
semSep   = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.sepGap, G);

figure;

% --- Top subplot: distances ---
subplot(2,1,1); hold on; grid on;
errorbar(Mvals, meanIntra, semIntra, 'o-', 'LineWidth', 1.5, ...
    'Color', [0 0.45 0.74], 'DisplayName', 'Intra-Memory Distance');
errorbar(Mvals, meanInter, semInter, 's-', 'LineWidth', 1.5, ...
    'Color', [0.85 0.33 0.10], 'DisplayName', 'Inter-Memory Distance');
ylabel('Mean Distance (1 - Similarity)');
set(gca, 'XScale', 'log');
legend('Location', 'best');
title(sprintf('Distance Metrics vs. M (N = %d, \\alpha = %.2f)', N_target, alpha_target));

% --- Bottom subplot: separability gap ---
subplot(2,1,2); hold on; grid on;
errorbar(Mvals, meanSep, semSep, 'o-k', 'LineWidth', 1.5, ...
    'DisplayName', 'Separability Gap');
yline(0, '--r', 'LineWidth', 1, 'DisplayName', 'No Separability');
ylabel('Separability (Inter - Intra)');
xlabel('Number of Memories (M)');
set(gca, 'XScale', 'log');
legend('Location', 'best');

%% Section 4: Separability Gap vs M for different N with Error Bars (fixed alpha)
% For a fixed alpha, plots the separability gap (intra - inter similarity)
% vs M for each N, with SEM error bars. Shows capacity scaling across network sizes.

clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

alpha_target = 0.80;
N_list = unique(T.N);

figure; hold on; grid on;
colors = lines(length(N_list));

for i = 1:length(N_list)
    N_val = N_list(i);

    T_sub = T(T.N == N_val & abs(T.alpha - alpha_target) < 1e-6, :);
    if isempty(T_sub), continue; end

    T_sub = sortrows(T_sub, 'M');

    % Separability gap from similarities
    T_sub.sepGap = T_sub.s_intra_memory - T_sub.s_inter_mem;

    [G, Mvals] = findgroups(T_sub.M);
    meanSep = splitapply(@mean, T_sub.sepGap, G);
    semSep  = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.sepGap, G);

    errorbar(Mvals, meanSep, semSep, '-', ...
        'DisplayName', sprintf('N = %d', N_val), ...
        'LineWidth', 1.5, 'Color', colors(i,:));
end

xlabel('Number of Memories (M)');
ylabel('Separability (Inter - Intra)');
title(sprintf('Separability vs. M for Different N (\\alpha = %.2f)', alpha_target));
legend('Location', 'best');
set(gca, 'XScale', 'log');

%% Section 5: Separability Gap vs M for different alpha values (fixed N)
% Overlays separability gap curves for multiple alpha values at a fixed N.
% Shows how cue strength affects capacity.

clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

N_target = 400;
alpha_list = [0.05, 0.10, 0.20, 0.40, 0.5, 0.60, 0.80];

figure; hold on; grid on;
colors = parula(length(alpha_list));

for i = 1:length(alpha_list)
    alpha_val = alpha_list(i);

    T_sub = T(T.N == N_target & abs(T.alpha - alpha_val) < 1e-6, :);
    if isempty(T_sub), continue; end

    T_sub = sortrows(T_sub, 'M');

    % Separability gap (in distance space: inter - intra)
    T_sub.sepGap = (1 - T_sub.s_inter_mem) - (1 - T_sub.s_intra_memory);
    % Equivalent to: T_sub.s_intra_memory - T_sub.s_inter_mem

    [G, Mvals] = findgroups(T_sub.M);
    meanSep = splitapply(@mean, T_sub.sepGap, G);
    semSep  = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.sepGap, G);

    errorbar(Mvals, meanSep, semSep, 'o-', ...
        'DisplayName', sprintf('\\alpha = %.2f', alpha_val), ...
        'LineWidth', 1.5, 'Color', colors(i,:));
end

yline(0, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');
xlabel('Number of Memories (M)');
ylabel('Separability Gap (Inter - Intra Distance)');
title(sprintf('Separability vs. M for Different \\alpha (N = %d)', N_target));
legend('Location', 'best');
set(gca, 'XScale', 'log');

%% Section 6: Normalized Separability vs M for different alpha (fixed N)
% Separability normalized by its value at M_min for each alpha.
% Shows relative degradation: 1 = no loss, 0 = full collapse.

clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

N_target = 400;
alpha_list = [0.05, 0.10, 0.20, 0.40, 0.50, 0.60, 0.80];

figure; hold on; grid on;
colors = parula(length(alpha_list));

for i = 1:length(alpha_list)
    alpha_val = alpha_list(i);

    T_sub = T(T.N == N_target & abs(T.alpha - alpha_val) < 1e-6, :);
    if isempty(T_sub), continue; end

    T_sub.sepGap = T_sub.s_intra_memory - T_sub.s_inter_mem;

    [G, Mvals] = findgroups(T_sub.M);
    meanSep = splitapply(@mean, T_sub.sepGap, G);
    semSep  = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.sepGap, G);

    % Normalize by value at smallest M
    sep0 = meanSep(1);
    if sep0 == 0, continue; end

    errorbar(Mvals, meanSep / sep0, semSep / sep0, 'o-', ...
        'DisplayName', sprintf('\\alpha = %.2f', alpha_val), ...
        'LineWidth', 1.5, 'Color', colors(i,:));
end

yline(1, '--k', 'LineWidth', 1, 'HandleVisibility', 'off');
yline(0, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');
xlabel('Number of Memories (M)');
ylabel('Normalized Separability (relative to M_{min})');
title(sprintf('Relative Separability Degradation vs. M (N = %d)', N_target));
legend('Location', 'best');
set(gca, 'XScale', 'log');

%% Section 7: Retrieval Quality — Memory vs Random intra-cluster similarity (fixed N)
% Compares intra-memory similarity against intra-random similarity.
% If they converge, the network is no longer retrieving — responses to
% learnt cues look the same as responses to random cues.

clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

N_target = 400;
alpha_list = [0.05, 0.10, 0.20, 0.40, 0.50, 0.60, 0.80];

figure;
colors = parula(length(alpha_list));

% --- Top: ratio of intra-memory / intra-random similarity ---
subplot(2,1,1); hold on; grid on;
for i = 1:length(alpha_list)
    alpha_val = alpha_list(i);

    T_sub = T(T.N == N_target & abs(T.alpha - alpha_val) < 1e-6, :);
    if isempty(T_sub), continue; end

    % Retrieval advantage: how much tighter are memory clusters vs random
    T_sub.ratio = T_sub.s_intra_memory ./ T_sub.s_intra_rand;

    [G, Mvals] = findgroups(T_sub.M);
    meanRatio = splitapply(@mean, T_sub.ratio, G);
    semRatio  = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.ratio, G);

    errorbar(Mvals, meanRatio, semRatio, 'o-', ...
        'DisplayName', sprintf('\\alpha = %.2f', alpha_val), ...
        'LineWidth', 1.5, 'Color', colors(i,:));
end
yline(1, '--r', 'LineWidth', 1, 'DisplayName', 'No Advantage');
ylabel('Intra-Memory / Intra-Random Similarity');
title(sprintf('Retrieval Quality vs. M (N = %d)', N_target));
set(gca, 'XScale', 'log');
legend('Location', 'best');

% --- Bottom: raw intra-memory vs intra-random for one alpha ---
subplot(2,1,2); hold on; grid on;
alpha_show = 0.20;
T_sub = T(T.N == N_target & abs(T.alpha - alpha_show) < 1e-6, :);
T_sub = sortrows(T_sub, 'M');

[G, Mvals] = findgroups(T_sub.M);
meanMem  = splitapply(@mean, T_sub.s_intra_memory, G);
semMem   = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.s_intra_memory, G);
meanRand = splitapply(@mean, T_sub.s_intra_rand, G);
semRand  = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.s_intra_rand, G);

errorbar(Mvals, meanMem, semMem, 'o-', 'LineWidth', 1.5, ...
    'Color', [0 0.45 0.74], 'DisplayName', 'Intra-Memory');
errorbar(Mvals, meanRand, semRand, 's-', 'LineWidth', 1.5, ...
    'Color', [0.85 0.33 0.10], 'DisplayName', 'Intra-Random');
ylabel('Mean Similarity');
xlabel('Number of Memories (M)');
title(sprintf('Memory vs Random Cluster Tightness (N = %d, \\alpha = %.2f)', N_target, alpha_show));
set(gca, 'XScale', 'log');
legend('Location', 'best');

%% Section 8: d-prime Discriminability vs M for different N (fixed alpha)
% Computes d-prime = (mean_intra - mean_inter) / pooled_std per (N, M).
% Unlike the raw separability gap, d-prime accounts for trial-to-trial
% variance, so it should track with F1 and drop as capacity is reached.
% Only includes (N, M) groups with at least 3 replicates.

clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

alpha_target = 0.10;
N_list = unique(T.N);

figure; hold on; grid on;
colors = lines(length(N_list));

for i = 1:length(N_list)
    N_val = N_list(i);

    T_sub = T(T.N == N_val & abs(T.alpha - alpha_target) < 1e-6, :);
    if isempty(T_sub), continue; end

    [G, Mvals] = findgroups(T_sub.M);

    meanIntra = splitapply(@mean, T_sub.s_intra_memory, G);
    meanInter = splitapply(@mean, T_sub.s_inter_mem, G);
    stdIntra  = splitapply(@std,  T_sub.s_intra_memory, G);
    stdInter  = splitapply(@std,  T_sub.s_inter_mem, G);
    nReps     = splitapply(@numel, T_sub.s_intra_memory, G);

    % Pooled std
    pooledStd = sqrt((stdIntra.^2 + stdInter.^2) / 2);

    % Only keep groups with enough replicates and nonzero variance
    valid = nReps >= 3 & pooledStd > 1e-6;
    dprime = (meanIntra(valid) - meanInter(valid)) ./ pooledStd(valid);

    plot(Mvals(valid), dprime, 'o-', ...
        'DisplayName', sprintf('N = %d', N_val), ...
        'LineWidth', 1.5, 'Color', colors(i,:));
end

yline(0, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');
xlabel('Number of Memories (M)');
ylabel("d' (Discriminability)");
title(sprintf("d' vs. M for Different N (\\alpha = %.2f)", alpha_target));
legend('Location', 'best');
set(gca, 'XScale', 'log');