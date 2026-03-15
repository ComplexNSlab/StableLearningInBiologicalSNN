clc; clear;

%% READING AND ACCUMULATING THE DATA
% Get list of folders
nMems = 20; N = 100; noise_strength = 100;
folders = dir(fullfile("Data\N" + num2str(N), "nMems" + num2str(nMems) ,"\noise" + num2str(noise_strength) + "%\"));

isSubfolder = [folders.isdir] & ~ismember({folders.name}, {'.', '..'});
folderPaths = fullfile({folders(isSubfolder).folder}, {folders(isSubfolder).name});

% Initialize final 3×3 cell array to hold concatenated results
finalData = cell(nMems,nMems);
finalMemSimMat = zeros(numel(folderPaths), nMems*100, nMems*100);
data_stats_total = zeros(numel(folderPaths), nMems, nMems, 4);

% Loop over folders
for fIdx = 1:numel(folderPaths)
    clearvars -except fIdx folderPaths finalData nMems finalMemSimMat data_stats_total N noise_strength
    load(fullfile(folderPaths{fIdx}, 'similarityMatrices.mat'), 'Data', 'memMemSimMat', 'data_stats');  % <- Assumes Daata is 3x3 cell array
    finalMemSimMat(fIdx, :, :) = memMemSimMat;
    data_stats_total(fIdx, :, :, :) = data_stats;

    % Loop over 3×3 elements
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
alignedData = cell(1, 2*nMems-1);  % For offsets -2 to +2
offsets = -(nMems-1):(nMems-1);            % Mapping from i - j to alignedData index

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

%% Plotting the decay
% Convert to long format
% allVals = [];
% groupLabels = [];
% Ymeans = [];
% Ymedians = [];
% upperCI = [];
% lowerCI = [];
% p = 10;
% 
% for i = 1:numel(alignedData)
%     x = alignedData{i};
%     Ymeans(i) = mean(x);
%     Ymedians(i) = median(x);
%     upperCI = [upperCI, mean(x) + std(x)/sqrt(6)];
%     lowerCI = [lowerCI, mean(x) - std(x)/sqrt(6)]; 
%     allVals = [allVals, x];
%     groupLabels = [groupLabels, repmat(i, 1, length(x))];
% end
% 
% % Create violin plot
% figure; hold on;
% % boxchart(groupLabels', allVals', 'JitterOutliers','on', 'MarkerStyle','.', 'MarkerSize', 5);  % groupLabels & allVals must be column
% 
% 
% 
% % Overlay mean and median
% xPos = 1:numel(alignedData);
% 
% % Plot mean with red 'x'
% plot(xPos, Ymeans, 'ro-', 'LineWidth', 1.5, 'MarkerSize', 8);
% fill([xPos fliplr(xPos)], [lowerCI fliplr(upperCI)], 'r', 'FaceAlpha', 0.4, 'EdgeColor','none');
% 
% xticks(xPos);
% xticklabels(offsets);
% xlabel('$\Delta m$', 'Interpreter', 'latex');
% ylabel('Correlation Value');
% title('Distribution of NoisyBursts-Memory Similarity');
% text(0.70*2*nMems, 0.7, "Post Learning");
% text(0.20*2*nMems, 0.7, "Pre Learning");
% % legend({'Violin', 'Mean'}, 'Location', 'best');
%% Memories Similarity Statistics

% averagedMat = squeeze(mean(finalMemSimMat, 1));
% 
% figure;
% imagesc(averagedMat);
% cb = colorbar();

%%
grayColor = 0.8*[1 1 1];  % Light gray

figure(Position=[300 300 1000 600]); hold on;

xPos = 1:numel(alignedData);
xline(nMems, LineStyle='--', LineWidth=0.5, Alpha=0.4, HandleVisibility='off');
plot([0], '-', 'Color', grayColor, HandleVisibility='on', DisplayName='single memory');
for i = 1:size(aligned_stats, 1)
    plot(squeeze(aligned_stats(i, :, :))', '-', 'Color', grayColor, HandleVisibility='off');
end

Ymean = squeeze(nanmean(aligned_stats, [1, 2]))';
plot(Ymean, 'ro-', 'LineWidth', 1, DisplayName = 'Mean', MarkerSize=3);
n_samples_per_DeltaM = squeeze(sum(~isnan(aligned_stats), [1, 2]))';
err = squeeze(nanstd(aligned_stats, 0, [1, 2]))'./sqrt(n_samples_per_DeltaM);
fill([xPos, fliplr(xPos)], [Ymean+err, fliplr(Ymean-err)], 'r', 'FaceAlpha', 0.2, 'EdgeColor','none', DisplayName='Mean Error');

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

outputDir = fullfile("Results", "N" + num2str(N));
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
fileName = "NoisyBursts_MemorySimilarity_" + num2str(noise_strength) + "noise";
filePath = fullfile(outputDir, fileName);
exportgraphics(gcf, filePath + ".pdf", 'ContentType', 'vector');
exportgraphics(gcf, filePath + ".png", 'ContentType', 'image');
%%
Y = Ymean(nMems:end);
X = 1+(0:nMems-1);
valid = Y > 0;
X = X(valid); Y = Y(valid);

% fig = figure; hold on;
% loglog(X, Y, 'ko-');
% xlabel('$\Delta m$', 'Interpreter', 'latex');
% ylabel('Pearson Correlation');
% 
% m = polyfit(log(X(1:7)), log(Y(1:7)), 1);
% loglog(X, exp(m(2)) * X.^m(1), 'r--', 'LineWidth', 2);
% legend('Data', sprintf('Fit: Y \\propto X^{%.2f}', m(1)), 'Location', 'best');
% grid on;
% set(gca, 'YScale', 'log', 'XScale', 'log'); 
%%

% Step 1: Prepare X, Y, and N as one structure
record.N = N;    % assign your current N value here
record.X = X;
record.Y = Y;

fname = fullfile("Results", "C(delta_m).mat");

% Step 2: Check if the file exists
if isfile(fname)
    % Load existing data
    data = load(fname, "allRecords");
    if isfield(data, "allRecords")
        allRecords = data.allRecords;
    else
        allRecords = [];
    end
else
    allRecords = [];
end

% Step 3: Append the new record (replace if same N exists)
idx = find(arrayfun(@(r) r.N == N, allRecords), 1);
if isempty(idx)
    allRecords = [allRecords; record];
else
    allRecords(idx) = record; % Replace old entry for this N
end

% Step 4: Save
save(fname, "allRecords");
