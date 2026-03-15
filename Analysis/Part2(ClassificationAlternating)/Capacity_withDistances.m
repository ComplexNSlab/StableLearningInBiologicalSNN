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
%%
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
%%
clc; clear; close all;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfile(fullfile(scriptDir, 'retrievalDistances.csv'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
T = readtable(fullfile(scriptDir, 'retrievalDistances.csv'));

%% Fixed N and alpha
N_target = 400;
alpha_target = 0.10;

T_sub = T(T.N == N_target & abs(T.alpha - alpha_target) < 1e-6, :);
T_sub = sortrows(T_sub, 'M');

% Convert similarities to distances
T_sub.intraMemDist = 1 - T_sub.s_intra_memory;
T_sub.interMemDist = 1 - T_sub.s_inter_mem;

% Separability gap: inter - intra
T_sub.sepGap = T_sub.interMemDist - T_sub.intraMemDist;
% Equivalent to:
% T_sub.sepGap = T_sub.s_intra_memory - T_sub.s_inter_mem;

% Aggregate by M
[G, Mvals] = findgroups(T_sub.M);

meanIntra = splitapply(@mean, T_sub.intraMemDist, G);
meanInter = splitapply(@mean, T_sub.interMemDist, G);
meanSep   = splitapply(@mean, T_sub.sepGap, G);

semIntra = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.intraMemDist, G);
semInter = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.interMemDist, G);
semSep   = splitapply(@(x) std(x)/sqrt(numel(x)), T_sub.sepGap, G);

figure; hold on; grid on;

yyaxis left
errorbar(Mvals, meanIntra, semIntra, 'o-', 'LineWidth', 1.5, ...
    'DisplayName', 'Intra-Memory Distance');
errorbar(Mvals, meanInter, semInter, 'o-', 'LineWidth', 1.5, ...
    'DisplayName', 'Inter-Memory Distance');
ylabel('Mean Distance (1 - Similarity)');

yyaxis right
errorbar(Mvals, meanSep, semSep, '--k', 'LineWidth', 1.8, ...
    'DisplayName', 'Separability Gap');
ylabel('Separability (Inter - Intra)');

xlabel('Number of Memories (M)');
title(sprintf('Distance Metrics vs. M (N = %d, \\alpha = %.2f)', N_target, alpha_target));
set(gca, 'XScale', 'log');
legend('Location', 'best');

%%
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