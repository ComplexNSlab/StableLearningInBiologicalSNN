% Step2_ConvergenceOfSingleMemory.m
% =========================================================================
% Visualises convergence of a single simulation's memory representations.
%
% Loads the latest simulation for a given N and produces:
%   1. Spike order vs trial (excitatory/inhibitory ranked separately)
%      — each neuron is a colored line showing its rank drifting over trials.
%   2. Spike order vs trial (all neurons ranked together).
%   3. Trial-by-trial similarity (Pearson or Spearman) heatmap for a
%      chosen representation (spike counts, delays, or spike orders).
%   4. Mean correlation vs trial.
%   5. Consecutive-trial distance D(t, t+lag) converging to zero.
%
% PARAMETERS (set at top of script):
%   N           — network size to load
%   scaleFolder — 'Scaled50' or 'Constant50'
%
% INPUTS:
%   Data/{scaleFolder}/N{N}/{latestSim}/MemoryRepresentations.mat
%   Data/{scaleFolder}/N{N}/{latestSim}/Patch*.mat  (for net object)
%
% OUTPUTS:
%   Results/  — PDF and PNG of each figure (print calls currently commented out)
% =========================================================================

% This script should be run when you have a recording directory of a simulation
clc; clear;

cfg = jsondecode(fileread('config.json'));
N = cfg.N;
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

% default selection of latest simulation
folderPath = fullfile(pwd, "Data", scaleFolder, trialsSubfolder, "N" + num2str(N));
sim_folders = dir(folderPath);
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'})); 
[~, latestIdx] = max([sim_folders.datenum]);
latestSim = sim_folders(latestIdx).name;
filePath = fullfile(folderPath, latestSim);

% loading net object
data_files = dir(filePath);
data_files = data_files(~ismember({data_files.name}, {'.', '..'})); 
dataFiles = data_files(contains({data_files.name}, "Patch"));
[~, latestIdx] = max([dataFiles.datenum]);
latestData = dataFiles(latestIdx).name;
net = load(fullfile(filePath, latestData), 'obj'); net = net.obj;

clearvars -except net filePath;

load(filePath + filesep + "MemoryRepresentations.mat");

clearvars filePath
%% Spike Order vs Trials (Separate)

% Network Size
N = net.N; Ne = net.Ne; Ni = net.Ni;

figure('Renderer', 'painters','Name', "Single Neuron Spike Order", 'Visible','on' )
fsize = 15;
temp = orders_separate(1:1:end, :);
temp(temp == 0) = nan;

%active_ex_cells = find(temp(end, :) ~= 0 & temp(end, :) <= net.Ne);
%active_inh_cells = find(temp(end, :) ~= 0 & temp(end, :) > net.Ne);

stable_order_ex = orders_separate(end, 1:Ne);
stable_order_inh = orders_separate(end, Ne+1:end)-Ne;
stable_order_ex(stable_order_ex == 0) = net.Ne-sum(stable_order_ex == 0)+1:net.Ne;
stable_order_inh(stable_order_inh == -Ne) = net.Ni-sum(stable_order_inh == -Ne)+1:net.Ni;

colormap_ex = jet(Ne);
colormap_ex = colormap_ex(stable_order_ex, :);

colormap_inh = jet(Ni);
colormap_inh = colormap_inh(stable_order_inh, :);

hold on 
wsize = 1.5;
for cell_id =1:Ne
    
    plot(temp(1:end, cell_id), 'color', colormap_ex(cell_id, :), LineWidth= wsize)
end
for cell_id = Ne+1:N
    
    plot(temp(1:end, cell_id), 'color', colormap_inh(cell_id-Ne, :), LineWidth= wsize)
end

xlabel("Trial")
ylabel("Single Neuron Spike Order")
title("First to Fire Order Vector")
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
% print(gcf, "Results" + filesep + 'SpikeOrderSeparate.pdf', '-dpdf', '-vector', '-r300');
% print(gcf, "Results" + filesep + 'SpikeOrderSeparate.png', '-dpng', '-r300');

%% Spike Order vs Trials (Together)
figure('Renderer', 'painters','Name', "Single Neuron Spike Order", 'Visible','on' )
fsize = 15;
temp = orders_together(1:1:end, :);
temp(temp == 0) = nan;

stable_order = orders_together(end, :);
stable_order(stable_order == 0) = net.N-sum(stable_order == 0)+1:net.N;

cm = jet(net.N);
cm = cm(stable_order, :);

hold on 
wsize = 1.0;
for cell_id =1:net.N
    
    plot(temp(1:end, cell_id), 'color', cm(cell_id, :), LineWidth= wsize)
end


xlabel("Trial")
ylabel("Single Neuron Spike Order")
title("First to Fire Order Vector")
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
% print(gcf, "Results" + filesep + 'SpikeOrderTogether.pdf', '-dpdf', '-vector', '-r300');
% print(gcf, "Results" + filesep + 'SpikeOrderTogether.png', '-dpng', '-r300');

%% Similarity Matrix of responses across Trials
% choose your desired representation measure of the memory
representation = "spike counts";

clear data;
if representation.lower == "spike counts"
    data = spike_counts;
    dist_measure = 'correlation';
elseif representation.lower == "delays"
    data = delays;
    dist_measure = 'correlation';
elseif representation.lower == "spike orders together"
    data = orders_together;
    dist_measure = 'spearman';
elseif representation.lower == "spike orders separate"
    data = orders_separate;
    dist_measure = 'spearman';
end

corrmat = 1-squareform(pdist(data, dist_measure));

% Create the heatmap

figure('Renderer', 'painters', 'Position', [100 100 1000 1000], 'Visible','on'); % Adjust position and size as needed
fsize = 25; % font size


% Create axes with the desired position and size
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]

imagesc(corrmat, 'Parent', ax)
colormap parula;
c = colorbar;

% Adjust the position of the colorbar to the left
c.Units = 'normalized'; % Use normalized units
c.Position = [0.15, 0.2, 0.03, 0.6]; % [left, bottom, width, height]

c.Label.String = dist_measure;
c.Label.Rotation = 90; % Rotate the label to be vertical
c.Label.Position = [-2, 0.3, 0]; % Adjust the position to be centered and beside the colorbar
c.Label.FontName = 'Arial'; % Set the font name
c.Label.FontSize = fsize; % Set the font size
c.Label.FontWeight = 'bold'; % Set the font weight to bold

% Set the title and axis labels with consistent font properties
xlabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
ylabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 0);

% Fix the aspect ratio to square
axis square;

set(gca, 'YDir', 'normal')

xtickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for x-tick labels

ytickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for y-tick labels

% Set x-ticks to top and y-ticks to right
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'right');

% Adjust paper size and position for saving as PDF
set(gcf, 'PaperPositionMode', 'auto');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 10 10]); % [left, bottom, width, height]
set(gcf, 'PaperSize', [10 10]); % [width, height]


title(representation + " Similarity Matrix", 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold')
% Save the figure as a PDF with higher resolution
% print(gcf, "Results" + filesep + 'Spearman_Corr_Matrix.pdf', '-dpdf', '-vector', '-r300');
% print(gcf, "Results" + filesep + 'Spearman_Corr_Matrix.png', '-dpng', '-r300');

%%
figure('Renderer', 'painters','Visible','off');
mean_corr = mean(corrmat, 2); % Average correlation for each trial
plot(1:length(mean_corr), mean_corr, 'LineWidth', 2);
xlabel('Trial');
ylabel('Mean Spearman Correlation');
title('Average Correlation Over Time');
grid on;
% print(gcf, "Results" + filesep + 'aveCorr.pdf', '-dpdf', '-vector', '-r300');
% print(gcf, "Results" + filesep + 'aveCorr.png', '-dpng', '-r300');


%% Consecutive distance converging to zero
figure('Renderer', 'painters','Visible', 'on'); 
lag = 1;
plot(1-diag(corrmat, lag))
xlabel("Trial Number", 'FontWeight','bold')
ylabel(sprintf("D(t+%d, t)", lag), 'FontWeight','bold')
title("Distance between Responses with lag")
set(gca, 'fontsize', 15, 'fontName', 'arial')
print(gcf, "Results" + filesep + 'consecDist.pdf', '-dpdf', '-vector', '-r300');
print(gcf, "Results" + filesep + 'consecDist.png', '-dpng', '-r300');

% save(net.RecordingDirectory + filesep + "MemoryRepresentations.mat", representation + "_corrmat", '-append')

%%
% figure; hold on;
% coeff = pca(corrmat);
% cm = jet(1000);
% for pc = 1:1
%     scatter(1:1000, coeff(:,pc), 50, cm, 'filled');
% end
% cb = colorbar(); cb.Label.String = "Trial Number"; caxis([1 1000]); colormap("jet");
% xlabel('Trial');
% ylabel('First Principal Component');
% title('PCA of Correlation Matrix');
% grid on;
% print(gcf, 'Spearman_Corr_Matrix.pdf', '-dpdf', '-vector', '-r300');
% print(gcf, 'Spearman_Corr_Matrix.png', '-dpng', '-r300');
