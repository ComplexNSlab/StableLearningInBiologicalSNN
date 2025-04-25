
%% Reading Responses in different representations and computing the distances
clc; clear;

lag = 100; 


sim_folders = dir("Data");
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'}));

signals = zeros(4, length(sim_folders), 1000-lag);
mats = zeros(4, length(sim_folders), 1000, 1000);

for i = 1:length(sim_folders)
    load("Data" + filesep +  sim_folders(i).name + filesep + "MemoryRepresentations.mat");
    
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
    signal = squeeze(signals(counter, :, :));

    figure('Visible','off');hold on;
    plot(1- signal', 'Color', 0.5*[1 1 1], HandleVisibility='off')
    plot(mean(1-signal, 1), LineWidth=4, DisplayName="average across " + num2str(length(sim_folders)) + " simulations")
    xlabel("Trial (t)")
    ylabel(sprintf("D(t, t+%d)", lag))
    title(representation + " Representation")
    legend();
    set(gca, 'fontname', 'arial', 'fontsize', 15)
    print(gcf, "Results" + filesep + "Convergence_"+representation, '-dpdf', '-r300');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure('Renderer', 'painters', 'Position', [100 100 1000 1000], 'Visible','off');
    fsize = 25;
    mat = squeeze(mean(mats, 2));
    mat =squeeze(mat(counter, :, :));
    ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
    imagesc(mat); c = colorbar(); 

    % Adjust the position of the colorbar to the left
    c.Units = 'normalized'; % Use normalized units
    c.Position = [0.15, 0.2, 0.03, 0.6]; % [left, bottom, width, height]

    c.Label.String = dist_measure;
    c.Label.Rotation = 90; % Rotate the label to be vertical
    c.Label.Position = [-2, 0.3, 0]; % Adjust the position to be centered and beside the colorbar
    c.Label.FontName = 'Arial'; % Set the font name
    c.Label.FontSize = fsize; % Set the font size
    c.Label.FontWeight = 'bold'; % Set the font weight to bold

    set(gca, 'ydir', 'normal', 'fontname', 'arial', 'FontSize', fsize)
    xlabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
    ylabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 0);
    axis square;

    xtickangle(-45)
    set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for x-tick labels

    ytickangle(-45)
    set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for y-tick labels

    % Set x-ticks to top and y-ticks to right
    set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'right');
    title(sprintf("Averaged on %d Simulations, " + representation + " Similarity Matrix", length(sim_folders)), 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold')
    % Adjust paper size and position for saving as PDF
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 10 10]); % [left, bottom, width, height]
    set(gcf, 'PaperSize', [10 10]); % [width, height]
    print(gcf,"Results" + filesep +  "AverageSimMatrix_" + representation, '-dpdf', '-r300');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    mat = squeeze(mean(mats, 3));
    mat = squeeze(mat(counter, :, :));
    figure(Visible="off"); hold on;
    plot(mat', 'Color', 0.5*[1 1 1], HandleVisibility='off')
    plot(mean(mat, 1), DisplayName= sprintf("average on %d simulations", length(sim_folders)), LineWidth=4);
    title(representation + " Representation")
    xlabel("Trial (t)")
    ylabel("Average Correlation")
    set(gca, 'fontname', 'arial', 'fontsize', 15)
    
    legend();
    print(gcf,"Results" + filesep +  "averageMatrixStatistics_"+representation, '-dpdf', '-r300');

    counter = counter + 1;
end