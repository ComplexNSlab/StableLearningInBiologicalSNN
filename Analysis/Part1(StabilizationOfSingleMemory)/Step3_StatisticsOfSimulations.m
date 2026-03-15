
%% Reading Responses in different representations and computing the distances
% clc; clear;
% 
lag = 10; 
% 
N = 400; % NetworkSize
scaleFolder = 'Constant50';

folderPath = fullfile(pwd,"Data", scaleFolder, "N" + num2str(N));
sim_folders = dir(folderPath);
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'}));

signals = zeros(4, length(sim_folders), 1000-lag);
mats = zeros(4, length(sim_folders), 1000, 1000);

for i = 1:length(sim_folders)
    load(fullfile(folderPath,  sim_folders(i).name, "MemoryRepresentations.mat"));
    
    counter = 1;
    for representation = ["spike counts",  "delays", "spike orders together", "spike orders separate"]
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
        corrmat = 1 - squareform(pdist(data, dist_measure));
        mats(counter, i, :, :) = corrmat;
        signals(counter, i, :) = diag(corrmat, lag);
        counter = counter + 1;
    end

end
%% Plotting the average curve for consecutive distances with lag
counter = 1;


savePath = fullfile(pwd, "Results", scaleFolder ,"N" + num2str(N));
if ~exist(savePath, 'dir')
    mkdir(savePath);
end

for representation = ["spike counts",  "delays", "spike orders together", "spike orders separate"]
    if representation.lower == "spike counts"
        dist_measure = 'correlation';
    elseif representation.lower == "delays"
        dist_measure = 'correlation';
    elseif representation.lower == "spike orders together"
        dist_measure = 'spearman';
    elseif representation.lower == "spike orders separate"
        dist_measure = 'spearman';
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     signal = squeeze(signals(counter, :, :));
% 
%     figure('Visible','off');hold on;
%     plot(1- signal', 'Color', 0.5*[1 1 1], HandleVisibility='off')
%     plot(mean(1-signal, 1), LineWidth=4, DisplayName="average across " + num2str(length(sim_folders)) + " simulations")
%     xlabel("Trial (t)")
%     ylabel(sprintf("D(t, t+%d)", lag))
%     title(representation + " Representation")
%     legend();
%     set(gca, 'fontname', 'arial', 'fontsize', 15)
%     print(gcf, fullfile(savePath, "Convergence_"+representation), '-dpdf', '-r600');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     figure('Renderer', 'painters', 'Position', [100 100 1000 1000], 'Visible','off');
%     fsize = 25;
%     mat = squeeze(mean(mats, 2));
%     mat =squeeze(mat(counter, :, :));
%     ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
%     imagesc(1-mat); c = colorbar(); 
% 
%     % Adjust the position of the colorbar to the left
%     c.Units = 'normalized'; % Use normalized units
%     c.Position = [0.15, 0.2, 0.03, 0.6]; % [left, bottom, width, height]
% 
%     c.Label.String = dist_measure + " distance";
%     c.Label.Rotation = 90; % Rotate the label to be vertical
%     c.Label.Position = [-2, 0.6, 0]; % Adjust the position to be centered and beside the colorbar
%     c.Label.FontName = 'Arial'; % Set the font name
%     c.Label.FontSize = fsize; % Set the font size
%     c.Label.FontWeight = 'bold'; % Set the font weight to bold
% 
%     set(gca, 'ydir', 'normal', 'fontname', 'arial', 'FontSize', fsize)
%     xlabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
%     ylabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 0);
%     axis square;
% 
%     xtickangle(-45)
%     set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for x-tick labels
% 
%     ytickangle(-45)
%     set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for y-tick labels
% 
%     % Set x-ticks to top and y-ticks to right
%     set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'right');
%     title(sprintf(representation + " Distance Matrix\n" + "Averaged on %d Simulations" , length(sim_folders)), 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'interpreter', 'latex')
%     % Adjust paper size and position for saving as PDF
%     set(gcf, 'PaperPositionMode', 'auto');
%     set(gcf, 'PaperUnits', 'inches');
%     set(gcf, 'PaperPosition', [0 0 10 10]); % [left, bottom, width, height]
%     set(gcf, 'PaperSize', [10 10]); % [width, height]
%     print(gcf,fullfile(savePath, "AverageSimMatrix_" + representation), '-dpdf', '-r600');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % mat = squeeze(mean(mats, 3));
    % mat = squeeze(mat(counter, :, :));
    % figure(Visible="off"); hold on;
    % plot(mat', 'Color', 0.5*[1 1 1], HandleVisibility='off')
    % plot(mean(mat, 1), DisplayName= sprintf("average on %d simulations", length(sim_folders)), LineWidth=4);
    % title(representation + " Representation")
    % xlabel("Trial (t)")
    % ylabel("Average Correlation")
    % set(gca, 'fontname', 'arial', 'fontsize', 15)
    % 
    % legend();
    % print(gcf,fullfile(savePath, "averageMatrixStatistics_"+representation), '-dpdf', '-r600');
    % 
    
    eps_thresh = 1e-3;
    D = 1-mats;  % D(counter, iter, i, j)
    figure; hold on;
    
    % Get size parameters
    [nCounter, nIter, nTrials, ~] = size(D);
    
    % Loop over each iteration
    for iter = 1:40
        y = zeros(1, nTrials);
        
        % Extract the matrix once for this iter
        mat = squeeze(D(counter, iter, :, :));
        
        % % Compute cumulative sums for efficient submatrix means
        % cum_sum = cumsum(cumsum(mat(end:-1:1, end:-1:1), 1), 2);  % bottom-right to top-left
        % cum_sum = cum_sum(end:-1:1, end:-1:1);  % flip back to top-left origin
        
        % % Total number of elements in each submatrix
        % for t0 = 1:nTrials
        %     block_size = (nTrials - t0 + 1)^2;
        %     total = cum_sum(t0, t0);
        %     y(t0) = total / block_size;
        % end
        % Loop over bottom-right submatrices
        for t0 = 1:nTrials
            submat = mat(t0:end, t0:end);
            y(t0) = max(submat, [], 'all');  % max distance in the submatrix
        end
    
        
        plot(y, 'k');
    end

    counter = counter + 1;
end