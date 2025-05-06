%% Reading Responses in different representations and computing the distances
% clc; clear;

% N = 600; % NetworkSize
nTrials = 1500;
scaleFolder = 'Scaled50';

folderPath = fullfile(pwd,"Data", scaleFolder, "N" + num2str(N));
sim_folders = dir(folderPath);
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'}));

delays_data = zeros(length(sim_folders), nTrials, N);
spike_counts_data = zeros(length(sim_folders), nTrials, N);

for i = 1:length(sim_folders)
    load(fullfile(folderPath,  sim_folders(i).name, "MemoryRepresentations.mat"), 'delays', 'spike_counts');
    delays_data(i, :, :) = delays; 
    spike_counts_data(i, :, :) = spike_counts;
end

delays_data(delays_data == 0) = nan;


%% === Figure 1: Delays Statistics ===
savePath = fullfile('Results/', scaleFolder ,"N" + num2str(N), "Convergence");
if ~exist(savePath, 'dir'), mkdir(savePath); end
CI = 80;


fig1 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w', 'Visible','off');
hold on;

ci_fill = [1.0 0.85 0.75];  % Light orange for CI
gray_color = [0.5 0.5 0.5 0.1];  % Simulated low-opacity gray

x = 1:nTrials;
y = nanmean(delays_data, 3);
ci_low = prctile(y, (100-CI)/2);
ci_high = prctile(y, (100+CI)/2);

fill([x, fliplr(x)], [ci_high, fliplr(ci_low)], ...
     ci_fill, 'EdgeColor', 'none', 'DisplayName', num2str(CI) + "\% CI");

% Plot gray individual traces
for i = 1:size(y, 1)
    plot(x, y(i,:), 'Color', gray_color, 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

plot(x, median(y), 'Color', [0.85 0.33 0.1], 'LineWidth', 2.5, 'DisplayName', 'Median');

xlabel('Trial', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Time Delay (ms)', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf("Mean First Spike Timing per Trial\n %d simulations, N = %d", length(sim_folders), N))
legend('Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');

set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');

posi = get(gcf, 'Position');
set(gcf, 'PaperSize', posi(3:4));

print(fig1, fullfile(savePath, 'timeDelay'), '-dpdf', '-r600');
print(fig1, fullfile(savePath, 'timeDelay'), '-dpng', '-r600');
Y = y;
%% Finding the thresholds
epsilon = 0.001;          % slope threshold (tune this!)
[nCurves, nTrials] = size(Y);
stabPoints = zeros(1, nCurves);

figure('visible', 'off'); hold on;
yyaxis right
plot([1, nTrials], epsilon*[1, 1], 'r')

for i = 1:nCurves
    y = Y(i, :);
    
    % Compute smoothed slope
    dy = abs(diff(y));
    dy_smooth = abs(movmean(diff(y, 1), 100));
    
    yyaxis left
    plot(smooth(y), 'b-'); 
    yyaxis right 
    plot(dy_smooth, 'r-')


    % Find first trial where slope stays below threshold
    idx = find(dy_smooth > epsilon, 1, "last");

    % If not stable, return NaN
    if isempty(idx) || idx == nTrials-1
        stabPoints(i) = NaN;
    else
        stabPoints(i) = idx;
        plot([idx, idx], [0, 0.04], 'g--')
    end
    

end

yyaxis right
ylabel("dy smoothed")

yyaxis left
ylabel("y")

xlabel("Trials")
hold off;

%% Saving the thresholds results
thresholdPath = fullfile("Data", "Scaled50", "DelaysThreshold.mat");

% Try to load existing struct
if isfile(thresholdPath)
    loaded = load(thresholdPath, 'thresholds');
    if isfield(loaded, 'thresholds')
        thresholds = loaded.thresholds;
    else
        thresholds = struct();  % File exists but variable doesn't
    end
else
    thresholds = struct();      % File doesn't exist
end

% Append or create the field
thresholds.(sprintf('N%d', N)) = stabPoints;

% Save updated struct back
save(thresholdPath, 'thresholds');

%% === Figure 2: Spike Count vs Trial ===

fig2 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w', 'Visible','off');
hold on;

x = 1:nTrials;
y = mean(spike_counts_data, 3);
ci_low = prctile(y, (100-CI)/2);
ci_high = prctile(y, (100+CI)/2);
mean_curve = median(y, 1);

fill([x, fliplr(x)], [ci_high, fliplr(ci_low)], [0.8 1 0.8], ...
     'EdgeColor', 'none', 'DisplayName', num2str(CI) + "\% CI");

gray_color = [0.8 0.8 0.8];
for i = 1:size(y, 1)
    plot(x, y(i,:), 'Color', gray_color, 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

plot(x, mean_curve, 'LineWidth', 2, 'Color', 'g', 'DisplayName', 'Median');

xlabel('Trial', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Spike Count', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf("Mean Firing Rate per Trial\n %d simulations, N = %d", length(sim_folders), N))

legend('Location', 'northwest', 'Interpreter', 'latex', 'Box', 'off');
set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');

posi = get(gcf, 'Position');
set(gcf, 'PaperSize', posi(3:4));

print(fig2, fullfile(savePath, 'spikeCount'), '-dpdf', '-r600');
print(fig2, fullfile(savePath,'spikeCount'), '-dpng', '-r600');
Y = y;
%% Finding the thresholds
epsilon = 0.005;          % slope threshold (tune this!)
Y = y;
[nCurves, nTrials] = size(Y);
stabPoints = zeros(1, nCurves);

figure('visible', 'off'); hold on;
yyaxis right
plot([1, nTrials], epsilon*[1, 1], 'r')

for i = 1:nCurves
    y = Y(i, :);
    
    % Compute smoothed slope
    dy = abs(diff(y));
    dy_smooth = movmean(diff(y, 1), 100);
    
    yyaxis left
    plot(smooth(y), 'b-'); 
    yyaxis right 
    plot(dy_smooth, 'r-')


    % Find first trial where slope stays below threshold
    idx = find(dy_smooth > epsilon, 1, "last");

    % If not stable, return NaN
    if isempty(idx) || idx == nTrials-1
        stabPoints(i) = NaN;
    else
        stabPoints(i) = idx;
        plot([idx, idx], [0, 0.04], 'g--')
    end
    

end

yyaxis right
ylabel("dy smoothed")

yyaxis left
ylabel("y")

xlabel("Trials")
hold off;

%% Saving the thresholds results
thresholdPath = fullfile("Data", "Scaled50", "SpikeCountsThreshold.mat");

% Try to load existing struct
if isfile(thresholdPath)
    loaded = load(thresholdPath, 'thresholds');
    if isfield(loaded, 'thresholds')
        thresholds = loaded.thresholds;
    else
        thresholds = struct();  % File exists but variable doesn't
    end
else
    thresholds = struct();      % File doesn't exist
end

% Append or create the field
thresholds.(sprintf('N%d', N)) = stabPoints;

% Save updated struct back
save(thresholdPath, 'thresholds');
