% This sctipt should be run when you have a recording directory of a simulation
clc;clear;

% defualt selection of latest simulation
sim_folders = dir("Data");
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'})); 
[~, latestIdx] = max([sim_folders.datenum]);
latestSim = sim_folders(latestIdx).name;
filePath = fullfile("Data", latestSim);

% loading net object
data_files = dir(filePath);
data_files = data_files(~ismember({data_files.name}, {'.', '..'})); 
dataFiles = data_files(contains({data_files.name}, "Patch"));
[~, latestIdx] = max([dataFiles.datenum]);
latestData = dataFiles(latestIdx).name;
net = load(fullfile(filePath, latestData), 'obj'); net = net.obj;

clearvars -except net;

load(net.RecordingDirectory + filesep + "MemoryRepresentations.mat");

%% Spike Order vs Trials (Separate)
figure('Renderer', 'painters','Name', "Single Neuron Spike Order", 'Visible','off' )
fsize = 15;
temp = orders_separate(1:1:end, :);
temp(temp == 0) = nan;

%active_ex_cells = find(temp(end, :) ~= 0 & temp(end, :) <= net.Ne);
%active_inh_cells = find(temp(end, :) ~= 0 & temp(end, :) > net.Ne);

stable_order_ex = orders_separate(end, 1:320);
stable_order_inh = orders_separate(end, 321:end)-320;
stable_order_ex(stable_order_ex == 0) = net.Ne-sum(stable_order_ex == 0)+1:net.Ne;
stable_order_inh(stable_order_inh == -320) = net.Ni-sum(stable_order_inh == -320)+1:net.Ni;

colormap_ex = jet(320);
colormap_ex = colormap_ex(stable_order_ex, :);

colormap_inh = jet(80);
colormap_inh = colormap_inh(stable_order_inh, :);

hold on 
wsize = 1.5;
for cell_id =1:320
    
    plot(temp(1:end, cell_id), 'color', colormap_ex(cell_id, :), LineWidth= wsize)
end
for cell_id = 321:400
    
    plot(temp(1:end, cell_id), 'color', colormap_inh(cell_id-320, :), LineWidth= wsize)
end

xlabel("Trial")
ylabel("Single Neuron Spike Order")
title("First to Fire Order Vector")
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
print(gcf, "Results" + filesep + 'SpikeOrderSeparate.pdf', '-dpdf', '-vector', '-r300');
print(gcf, "Results" + filesep + 'SpikeOrderSeparate.png', '-dpng', '-r300');

%% Spike Order vs Trials (Together)
figure('Renderer', 'painters','Name', "Single Neuron Spike Order", 'Visible','off' )
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
print(gcf, "Results" + filesep + 'SpikeOrderTogether.pdf', '-dpdf', '-vector', '-r300');
print(gcf, "Results" + filesep + 'SpikeOrderTogether.png', '-dpng', '-r300');

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

figure('Renderer', 'painters', 'Position', [100 100 1000 1000], 'Visible','off' ); % Adjust position and size as needed
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
print(gcf, "Results" + filesep + 'Spearman_Corr_Matrix.pdf', '-dpdf', '-vector', '-r300');
print(gcf, "Results" + filesep + 'Spearman_Corr_Matrix.png', '-dpng', '-r300');

%%
figure('Renderer', 'painters','Visible','off');
mean_corr = mean(corrmat, 2); % Average correlation for each trial
plot(1:length(mean_corr), mean_corr, 'LineWidth', 2);
xlabel('Trial');
ylabel('Mean Spearman Correlation');
title('Average Correlation Over Time');
grid on;
print(gcf, "Results" + filesep + 'aveCorr.pdf', '-dpdf', '-vector', '-r300');
print(gcf, "Results" + filesep + 'aveCorr.png', '-dpng', '-r300');


%% Consecutive distance converging to zero
figure('Renderer', 'painters','Visible', 'off'); 
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
