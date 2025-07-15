clc; clear;

%% READING AND ACCUMULATING THE DATA
% Get list of folders
nMems = 20;
folders = dir(fullfile("Data\N400\", "nMems" + num2str(nMems) ,"\noise100%\"));

isSubfolder = [folders.isdir] & ~ismember({folders.name}, {'.', '..'});
folderPaths = fullfile({folders(isSubfolder).folder}, {folders(isSubfolder).name});

% Initialize final 3×3 cell array to hold concatenated results
finalData = cell(nMems,nMems);
finalMemSimMat = zeros(numel(folderPaths)-1, nMems*100, nMems*100);
data_stats_total = zeros(numel(folderPaths)-1, nMems, nMems, 4);

% Loop over folders
for fIdx = 1:numel(folderPaths)-1
    clearvars -except fIdx folderPaths finalData nMems finalMemSimMat data_stats_total
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
allVals = [];
groupLabels = [];
Ymeans = [];
Ymedians = [];
upperCI = [];
lowerCI = [];
p = 10;

for i = 1:numel(alignedData)
    x = alignedData{i};
    Ymeans(i) = mean(x);
    Ymedians(i) = median(x);
    upperCI = [upperCI, mean(x) + std(x)/sqrt(6)];
    lowerCI = [lowerCI, mean(x) - std(x)/sqrt(6)]; 
    allVals = [allVals, x];
    groupLabels = [groupLabels, repmat(i, 1, length(x))];
end

% Create violin plot
figure; hold on;
% boxchart(groupLabels', allVals', 'JitterOutliers','on', 'MarkerStyle','.', 'MarkerSize', 5);  % groupLabels & allVals must be column



% Overlay mean and median
xPos = 1:numel(alignedData);

% Plot mean with red 'x'
plot(xPos, Ymeans, 'ro-', 'LineWidth', 1.5, 'MarkerSize', 8);
fill([xPos fliplr(xPos)], [lowerCI fliplr(upperCI)], 'r', 'FaceAlpha', 0.4, 'EdgeColor','none');

xticks(xPos);
xticklabels(offsets);
xlabel('$\Delta m$', 'Interpreter', 'latex');
ylabel('Correlation Value');
title('Distribution of NoisyBursts-Memory Similarity');
text(0.70*2*nMems, 0.7, "Post Learning");
text(0.20*2*nMems, 0.7, "Pre Learning");
% legend({'Violin', 'Mean'}, 'Location', 'best');
%% Memories Similarity Statistics

% averagedMat = squeeze(mean(finalMemSimMat, 1));
% 
% figure;
% imagesc(averagedMat);
% cb = colorbar();

%%
grayColor = 0.8*[1 1 1];  % Light gray

figure(Position=[300 300 1000 600]); hold on;

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
title(sprintf('Distribution of NoisyBursts-Memory Similarity\n %d simulation, %d samples ', size(aligned_stats, 1), size(aligned_stats, 1)*nMems), 'Interpreter','latex');
legend('Box','off', Location='northwest');
text(0.70*2*nMems, 0.1, "Post Learning");
text(0.20*2*nMems, 0.1, "Pre Learning");
yline(0, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5, 'HandleVisibility','off');

set(gca, 'fontName', 'Times New Roman', 'fontsize', 16)

set(gcf, 'Color', 'w');
exportgraphics(gcf, 'Results\\NoisyBursts_MemorySimilarity.pdf', 'ContentType','vector')
