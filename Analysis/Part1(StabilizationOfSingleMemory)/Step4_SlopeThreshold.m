% Step4_SlopeThreshold.m  (SUPERSEDED by computeStabilizationTrialsForRepresentations.m)
% =========================================================================
% Detects the trial at which delay and spike-count representations
% stabilise, using a SLOPE-THRESHOLD method (smoothed |dY/dt| < epsilon).
%
% NOTE: computeStabilizationTrialsForRepresentations.m implements a more
%       robust plateau-proximity criterion and covers all network sizes.
%       This script is kept for reference / reproducibility of older results.
%
% WORKFLOW:
%   1. Loads all simulations for a fixed N (1500-trial runs).
%   2. Plots mean first-spike delay per trial with confidence interval.
%   3. Finds the last trial where the smoothed slope exceeds epsilon —
%      this is the stabilisation point for each simulation.
%   4. Saves per-N threshold vectors to .mat files.
%   5. Repeats steps 2-4 for spike counts.
%
% PARAMETERS:
%   N           — network size (hardcoded to 400)
%   epsilon     — slope threshold (0.001 for delays, 0.002 for spike counts)
%
% OUTPUTS:
%   Data/Scaled50/Trials1500/DelaysThreshold.mat
%   Data/Scaled50/Trials1500/SpikeCountsThreshold.mat
%   Results/{scaleFolder}/Trials1500/N{N}/Convergence/*.pdf, *.png
% =========================================================================

%% Reading Responses in different representations and computing the distances

clc; clear;
set(groot, 'DefaultAxesFontName', 'Times New Roman')
set(groot, 'DefaultTextInterpreter', 'latex');
set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
set(groot, 'DefaultLegendInterpreter', 'latex');
set(groot, 'DefaultAxesFontSize', 14);
set(groot, 'DefaultTextFontSize', 14);
set(groot, 'DefaultLegendFontSize', 13);


%%

cfg = jsondecode(fileread('config.json'));
show_figs = 'on';
N = cfg.N;
nTrials = cfg.nTrials;
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

folderPath = fullfile(pwd, "Data", scaleFolder, trialsSubfolder, "N" + num2str(N));
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

savePath = fullfile('Results/', scaleFolder, trialsSubfolder, "N" + num2str(N), "Convergence");
if ~exist(savePath, 'dir'), mkdir(savePath); end
CI = 80;

%% === Figure 1: Delays Statistics ===

fig1 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w', 'Visible',show_figs);
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

figure('visible', show_figs); hold on;
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
thresholdPath = fullfile("Data", scaleFolder, trialsSubfolder, "DelaysThreshold.mat");

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

fig2 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w', 'Visible',show_figs);
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
epsilon = 0.002;          % slope threshold (tune this!)
[nCurves, nTrials] = size(Y);
stabPoints = zeros(1, nCurves);

figure('visible', show_figs); hold on;
yyaxis right
plot([1, nTrials], epsilon*[1, 1], 'r')

for i = 1:nCurves
    y = Y(i, :);
    
    % Compute smoothed slope
    dy = abs(diff(y));
    dy_smooth = movmean(diff(y, 1), 100);
    

    yyaxis right 
    plot(dy_smooth, 'r-')


    % Find first trial where slope stays below threshold
    idx = find(dy_smooth > epsilon, 1, "last");

    % If not stable, return NaN
    if isempty(idx) || idx == nTrials-1 || y(idx) < 1
        stabPoints(i) = NaN;
        yyaxis left
        plot(smooth(y), 'b-'); 
    else
        stabPoints(i) = idx;
        plot([idx, idx], [0, 0.04], 'k--')
        yyaxis left
        plot(smooth(y), 'g-'); 
    end
    

end

yyaxis right
ylabel("dy smoothed")

yyaxis left
ylabel("y")

xlabel("Trials")
hold off;

%% Saving the thresholds results
thresholdPath = fullfile("Data", scaleFolder, trialsSubfolder, "SpikeCountsThreshold.mat");

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
