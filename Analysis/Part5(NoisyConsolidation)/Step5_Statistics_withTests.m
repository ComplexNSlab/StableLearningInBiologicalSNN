% Step5_VariantA_FilledHollow.m
% =========================================================================
% Variant A: Significant Delta_m shown as FILLED red dots on the mean
% curve; non-significant shown as HOLLOW dots. No text markers.
% =========================================================================

clc; clear;

%% Resolve script directory
scriptDir = fullfile(pwd, 'Analysis', 'Part5(NoisyConsolidation)');
if ~isfolder(fullfile(scriptDir, 'Data'))
    scriptDir = pwd;
end
if ~isfolder(fullfile(scriptDir, 'Data'))
    error('Cannot locate Data folder.');
end

%% READING AND ACCUMULATING THE DATA
nMems = 20; N = 400; noise_strength = 100;
folders = dir(fullfile(scriptDir, 'Data', ['N' num2str(N)], ...
    ['nMems' num2str(nMems)], ['noise' num2str(noise_strength) '%']));
isSubfolder = [folders.isdir] & ~ismember({folders.name}, {'.', '..'});
folderPaths = fullfile({folders(isSubfolder).folder}, {folders(isSubfolder).name});

finalData = cell(nMems, nMems);
finalMemSimMat = zeros(numel(folderPaths), nMems*100, nMems*100);
data_stats_total = zeros(numel(folderPaths), nMems, nMems, 4);

for fIdx = 1:numel(folderPaths)
    clearvars -except fIdx folderPaths finalData nMems finalMemSimMat data_stats_total N noise_strength scriptDir
    load(fullfile(folderPaths{fIdx}, 'similarityMatrices.mat'), 'Data', 'memMemSimMat', 'data_stats');
    finalMemSimMat(fIdx, :, :) = memMemSimMat;
    data_stats_total(fIdx, :, :, :) = data_stats;
    for row = 1:nMems
        for col = 1:nMems
            if ~isempty(Data{row, col})
                finalData{row, col} = [finalData{row, col}, Data{row, col}];
            end
        end
    end
end

%% ALIGNMENT
aligned_stats = nan(size(data_stats_total, 1), nMems, 2*nMems-1);
alignedData = cell(1, 2*nMems-1);
offsets = -(nMems-1):(nMems-1);

for i = 1:nMems
    for j = 1:nMems
        offset = j - i;
        idx = offset - offsets(1) + 1;
        alignedData{idx} = [alignedData{idx}, finalData{i,j}];
        for k = 1:size(aligned_stats, 1)
            aligned_stats(k, i, idx) = data_stats_total(k, i, j, 1);
        end
    end
end

%% STATISTICAL TESTS
baseline_indices = 1:(nMems - 1);
baseline_vals = aligned_stats(:, :, baseline_indices);
baseline_vals = baseline_vals(:);
baseline_vals(isnan(baseline_vals)) = [];
baseline_mean = mean(baseline_vals);
baseline_std  = std(baseline_vals);
baseline_ci95 = baseline_mean + [-1.96, 1.96] * baseline_std ;

post_indices = nMems:(2*nMems - 1);
nTests = numel(post_indices);
pvals_raw = nan(1, nTests);
for t = 1:nTests
    test_vals = aligned_stats(:, :, post_indices(t));
    test_vals = test_vals(:);
    test_vals(isnan(test_vals)) = [];
    % if numel(test_vals) >= 40
        pvals_raw(t) = ranksum(test_vals, baseline_vals, 'tail', 'right');
    % end
end
pvals_corrected = min(pvals_raw * nTests, 1);

% Significance levels for star annotation
sig_level = zeros(1, nTests);  % 0 = n.s.
sig_level(pvals_corrected < 0.05)  = 1;  % *
sig_level(pvals_corrected < 0.01)  = 2;  % **
sig_level(pvals_corrected < 0.001) = 3;  % ***

%% PLOT — Variant A: filled vs hollow dots
grayColor = 0.8 * [1 1 1];
fig = figure('Position', [300 300 1000 600]); hold on;

xPos = 1:numel(alignedData);

% Baseline lines
yline(baseline_mean, ':', 'Color', [0.4 0.4 0.8], 'LineWidth', 1, ...
    'DisplayName', 'Baseline mean');
yline(baseline_ci95(1), '--', 'Color', [0.6 0.6 0.9], 'LineWidth', 0.8, ...
    'HandleVisibility', 'off');
yline(baseline_ci95(2), '--', 'Color', [0.6 0.6 0.9], 'LineWidth', 0.8, ...
    'DisplayName', 'Baseline $\pm 1.96$ SD');

% Vertical line at Delta_m = 0
xline(nMems, 'LineStyle', '--', 'LineWidth', 0.5, 'Alpha', 0.4, ...
    'HandleVisibility', 'off');

% Gray traces
plot([0], '-', 'Color', grayColor, 'HandleVisibility', 'on', ...
    'DisplayName', 'Single memory');
for i = 1:size(aligned_stats, 1)
    plot(squeeze(aligned_stats(i, :, :))', '-', 'Color', grayColor, ...
        'HandleVisibility', 'off');
end

% Grand mean +/- SEM
Ymean = squeeze(nanmean(aligned_stats, [1, 2]))';
n_samples_per_DeltaM = squeeze(sum(~isnan(aligned_stats), [1, 2]))';
err = squeeze(nanstd(aligned_stats, 0, [1, 2]))' ./ sqrt(n_samples_per_DeltaM);

fill([xPos, fliplr(xPos)], [Ymean + err, fliplr(Ymean - err)], ...
    'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'SEM');

% Mean curve as line only (no markers yet)
plot(xPos, Ymean, 'r-', 'LineWidth', 1, 'HandleVisibility', 'off');

% Pre-learning dots: all hollow (no test)
pre_indices = 1:(nMems - 1);
plot(xPos(pre_indices), Ymean(pre_indices), 'ro', 'MarkerSize', 5, ...
    'LineWidth', 1, 'HandleVisibility', 'off');

% Post-learning dots: all filled red
plot(xPos(post_indices), Ymean(post_indices), 'ro', 'MarkerSize', 5, ...
    'LineWidth', 1, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');

% Significance stars above post-learning dots (stacked vertically)
starY_base = 0.01;   % vertical offset above dot
starY_gap  = 0.008;  % vertical spacing between each star
for t = 1:nTests
    if sig_level(t) > 0
        xStar = post_indices(t);
        for s = 1:sig_level(t)
            yStar = Ymean(xStar) + starY_base + (s - 1) * starY_gap;
            text(xStar, yStar, '*', 'HorizontalAlignment', 'center', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0 0]);
        end
    end
end

% Labels
xticks(xPos);
xticklabels(offsets);
xlabel('$\Delta m$', 'Interpreter', 'latex');
ylabel('Pearson Correlation');
legend('Box', 'off', 'Location', 'northwest', 'Interpreter', 'latex');
yline(0, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5, 'HandleVisibility', 'off');
ylim([-0.15, 0.25]);
title('Spontaneous Replay Similarity vs. Memory Distance', ...
    'FontWeight', 'bold');

% Pre / Post Learning labels
yLbl = 0.1;
text(mean(pre_indices), yLbl, 'Pre Learning', 'HorizontalAlignment', 'center', ...
    'FontAngle', 'italic', ...
    'Color', [0.4 0.4 0.4]);
text(mean(post_indices), yLbl, 'Post Learning', 'HorizontalAlignment', 'center', ...
    'FontAngle', 'italic', ...
    'Color', [0.4 0.4 0.4]);

set(gcf, 'Color', 'w');

%% EXPORT
outputDir = fullfile(scriptDir, 'Results', ['N' num2str(N)]);
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
fileName = "NoisyBursts_MemorySimilarity_" + num2str(noise_strength) + "noise";
outFilePath = fullfile(outputDir, fileName);
exportgraphics(gcf, outFilePath + ".pdf", 'ContentType', 'vector');
exportgraphics(gcf, outFilePath + ".png", 'ContentType', 'image');
fprintf('exported to:\n  %s.pdf\n  %s.png\n', outFilePath, outFilePath);
