% Step5_Statistics.m
% =========================================================================
% Aggregates and visualises Pearson similarity statistics from noisy-
% consolidation simulations (Part 5).
%
% WORKFLOW:
%   1. Loads similarityMatrices.mat from every simulation folder matching
%      the (N, nMems, noise_strength) configuration.
%   2. Concatenates the per-pair similarity values (finalData) and the
%      summary statistics (data_stats_total) across simulations.
%   3. Re-indexes the nMems x nMems similarity matrix by the diagonal
%      offset  Delta_m = j - i  so that columns represent the "distance"
%      between memory indices rather than absolute memory pairs.
%   4. Plots the aligned similarity vs Delta_m with per-simulation traces
%      (gray) and the grand mean +/- SEM (red).
%   5. Exports the figure to PDF and PNG under Results/N{N}/.
%   6. Saves the positive-tail of the mean curve (Delta_m >= 0, Y > 0) to
%      Results/C(delta_m).mat, replacing any previous entry for the same N.
%
% DATA FOLDER STRUCTURE (relative to this script):
%   Data/
%     N{N}/
%       nMems{nMems}/
%         noise{noise_strength}%/
%           {simID}/
%             similarityMatrices.mat   (contains Data, memMemSimMat, data_stats)
%
% OUTPUTS:
%   Results/N{N}/NoisyBursts_MemorySimilarity_{noise_strength}noise.pdf
%   Results/N{N}/NoisyBursts_MemorySimilarity_{noise_strength}noise.png
%   Results/C(delta_m).mat   (struct array allRecords with fields N, X, Y)
% =========================================================================

clc; clear;

%% Resolve script directory
% Try several possible working directories: pwd may be the project root,
% the script folder itself, or somewhere else entirely.
scriptDir = fullfile(pwd, 'Analysis', 'Part5(NoisyConsolidation)');
if ~isfolder(fullfile(scriptDir, 'Data'))
    scriptDir = pwd;  % pwd is already the script folder
end
if ~isfolder(fullfile(scriptDir, 'Data'))
    error('Cannot locate Data folder. cd to the project root or the script folder before running.');
end

%% READING AND ACCUMULATING THE DATA
nMems = 20; N = 400; noise_strength = 100;
folders = dir(fullfile(scriptDir, 'Data', ['N' num2str(N)], ...
    ['nMems' num2str(nMems)], ['noise' num2str(noise_strength) '%']));

isSubfolder = [folders.isdir] & ~ismember({folders.name}, {'.', '..'});
folderPaths = fullfile({folders(isSubfolder).folder}, {folders(isSubfolder).name});

% Initialize nMems x nMems cell array to hold concatenated similarity values
finalData = cell(nMems,nMems);
finalMemSimMat = zeros(numel(folderPaths), nMems*100, nMems*100);
data_stats_total = zeros(numel(folderPaths), nMems, nMems, 4);

% Loop over folders
for fIdx = 1:numel(folderPaths)
    clearvars -except fIdx folderPaths finalData nMems finalMemSimMat data_stats_total N noise_strength scriptDir
    load(fullfile(folderPaths{fIdx}, 'similarityMatrices.mat'), 'Data', 'memMemSimMat', 'data_stats');
    finalMemSimMat(fIdx, :, :) = memMemSimMat;
    data_stats_total(fIdx, :, :, :) = data_stats;

    % Loop over nMems x nMems elements and concatenate
    for row = 1:nMems
        for col = 1:nMems
            if ~isempty(Data{row, col})
                % Concatenate current data with what's already in finalData
                finalData{row, col} = [finalData{row, col}, Data{row, col}];
            end
        end
    end
end
%% ALIGNMENT OF DATA

aligned_stats = nan(size(data_stats_total, 1), nMems, 2*nMems-1);
alignedData = cell(1, 2*nMems-1);  % One bin per offset -(nMems-1) to +(nMems-1)
offsets = -(nMems-1):(nMems-1);    % Diagonal offset values

for i = 1:nMems
    for j = 1:nMems
        offset = j - i;                         % diagonal offset
        idx = offset - offsets(1) + 1;          % convert to 1-based index
        alignedData{idx} = [alignedData{idx}, finalData{i,j}];
        for k = 1:size(aligned_stats, 1)
            aligned_stats(k, i, idx) = data_stats_total(k, i, j, 1);
        end
    end
end

%% PLOT: C(Delta_m) — similarity vs memory offset
% Gray traces = individual simulations; red = grand mean +/- SEM.
grayColor = 0.8*[1 1 1];

figure(Position=[300 300 1000 600]); hold on;

xPos = 1:numel(alignedData);

% Vertical line at Delta_m = 0 (boundary between pre- and post-learning)
xline(nMems, LineStyle='--', LineWidth=0.5, Alpha=0.4, HandleVisibility='off');

% Per-simulation traces (gray)
plot(NaN, NaN, '-', 'Color', grayColor, HandleVisibility='on', DisplayName='Single simulation');
for i = 1:size(aligned_stats, 1)
    plot(squeeze(aligned_stats(i, :, :))', '-', 'Color', grayColor, HandleVisibility='off');
end

% Grand mean +/- SEM (red)
Ymean = squeeze(nanmean(aligned_stats, [1, 2]))';
plot(Ymean, 'r-', 'LineWidth', 1.5, DisplayName='Mean', MarkerSize=2, Marker='o');
n_samples_per_DeltaM = squeeze(sum(~isnan(aligned_stats), [1, 2]))';
err = squeeze(nanstd(aligned_stats, 0, [1, 2]))'./sqrt(n_samples_per_DeltaM);
fill([xPos, fliplr(xPos)], [Ymean+err, fliplr(Ymean-err)], ...
    'r', 'FaceAlpha', 0.2, 'EdgeColor','none', DisplayName='SEM');

xticks(xPos);
xticklabels(offsets);
xlabel('$\Delta m$', 'Interpreter', 'latex');
ylabel('Pearson Correlation');
title(sprintf('Distribution of NoisyBursts-Memory Similarity\n %d neurons, %d\\%% noise, %d simulation, %d samples ', N, noise_strength, size(aligned_stats, 1), size(aligned_stats, 1)*nMems), 'Interpreter','latex');
legend('Box','off', Location='northwest');
text(0.70*2*nMems, 0.1, "Post Learning");
text(0.20*2*nMems, 0.1, "Pre Learning");
yline(0, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5, 'HandleVisibility','off');
ylim([-0.15, 0.25]);
set(gca, 'fontName', 'Times New Roman', 'fontsize', 16)

set(gcf, 'Color', 'w');

%% EXPORT FIGURE
outputDir = fullfile(scriptDir, 'Results', ['N' num2str(N)]);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
fileName = "NoisyBursts_MemorySimilarity_" + num2str(noise_strength) + "noise";
outFilePath = fullfile(outputDir, fileName);
exportgraphics(gcf, outFilePath + ".pdf", 'ContentType', 'vector');
exportgraphics(gcf, outFilePath + ".png", 'ContentType', 'image');

%% EXTRACT POSITIVE-TAIL DECAY CURVE
% Keep only the Delta_m >= 0 portion (post-learning) where correlation > 0.
Y = Ymean(nMems:end);
X = 1 + (0:nMems-1);       % Delta_m values: 1, 2, ..., nMems
valid = Y > 0;
X = X(valid); Y = Y(valid);

%% SAVE DECAY CURVE TO RESULTS — used by Step6_C_Delta_m_fit.m
% Each record stores (N, X, Y). If a record for the same N already exists
% it is replaced; otherwise the new record is appended.
record.N = N;
record.X = X;
record.Y = Y;

fname = fullfile(scriptDir, 'Results', 'C(delta_m).mat');

if isfile(fname)
    data = load(fname, "allRecords");
    if isfield(data, "allRecords")
        allRecords = data.allRecords;
    else
        allRecords = [];
    end
else
    allRecords = [];
end

idx = find(arrayfun(@(r) r.N == N, allRecords), 1);
if isempty(idx)
    allRecords = [allRecords; record];
else
    allRecords(idx) = record;
end

save(fname, "allRecords");
