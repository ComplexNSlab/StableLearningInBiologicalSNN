% Step04_SlopeThreshold.m  (SUPERSEDED by Step04_PlateauThreshold.m)
% =========================================================================
% Detects the trial at which delay and spike-count representations
% stabilise, using a SLOPE-THRESHOLD method (smoothed |dY/dt| < epsilon),
% across all network sizes specified in config.json.
%
% NOTE: computeStabilizationTrialsForRepresentations.m implements a more
%       robust plateau-proximity criterion and covers all network sizes.
%       This script is kept for reference / reproducibility of older results.
%
% WORKFLOW:
%   1. Loops over every N in cfg.networkSizes.
%   2. For each N, loads all simulations (1500-trial runs).
%   3. Plots mean first-spike delay per trial with confidence interval.
%   4. Finds the last trial where the smoothed slope exceeds epsilon —
%      this is the stabilisation point for each simulation.
%   5. Saves per-N threshold vectors to .mat files.
%   6. Repeats steps 3-5 for spike counts.
%
% PARAMETERS:
%   epsilon     — slope threshold (0.001 for delays, 0.002 for spike counts)
%
% OUTPUTS:
%   Data/{scaleFolder}/Trials{X}/DelaysThreshold.mat
%   Data/{scaleFolder}/Trials{X}/SpikeCountsThreshold.mat
%   Results/{scaleFolder}/Trials{X}/N{N}/Convergence/*.pdf, *.png
% =========================================================================

%% Setup

clc; clear;
set(groot, 'DefaultAxesFontName', 'Times New Roman')
set(groot, 'DefaultTextInterpreter', 'latex');
set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
set(groot, 'DefaultLegendInterpreter', 'latex');
set(groot, 'DefaultAxesFontSize', 14);
set(groot, 'DefaultTextFontSize', 14);
set(groot, 'DefaultLegendFontSize', 13);

%% USER SETTINGS

cfg = jsondecode(fileread('config.json'));
show_figs   = 'off';
N_list      = cfg.networkSizes(:)';
nTrials     = cfg.nTrials;
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end
CI = 80;

%% Load existing threshold structs if they exist
delayThresholdPath = fullfile("Data", scaleFolder, trialsSubfolder, "DelaysThreshold.mat");
spikeThresholdPath = fullfile("Data", scaleFolder, trialsSubfolder, "SpikeCountsThreshold.mat");

if isfile(delayThresholdPath)
    loaded = load(delayThresholdPath, 'thresholds');
    if isfield(loaded, 'thresholds')
        delayThresholds = loaded.thresholds;
    else
        delayThresholds = struct();
    end
else
    delayThresholds = struct();
end

if isfile(spikeThresholdPath)
    loaded = load(spikeThresholdPath, 'thresholds');
    if isfield(loaded, 'thresholds')
        spikeThresholds = loaded.thresholds;
    else
        spikeThresholds = struct();
    end
else
    spikeThresholds = struct();
end

%% Loop over network sizes
for iN = 1:numel(N_list)
    N = N_list(iN);
    fprintf('\nProcessing N = %d\n', N);

    folderPath = fullfile(pwd, "Data", scaleFolder, trialsSubfolder, "N" + num2str(N));
    sim_folders = dir(folderPath);
    sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'}));

    if isempty(sim_folders)
        warning('No simulation folders found for N=%d', N);
        continue;
    end

    nRuns = numel(sim_folders);

    delays_data = nan(nRuns, nTrials, N);
    spike_counts_data = nan(nRuns, nTrials, N);

    for i = 1:nRuns
        filePath = fullfile(folderPath, sim_folders(i).name, "MemoryRepresentations.mat");
        if ~isfile(filePath)
            warning('Missing file: %s', filePath);
            continue;
        end
        S = load(filePath, 'delays', 'spike_counts');
        if isfield(S, 'delays')
            delays = S.delays;
            delays(delays == 0) = nan;
            delays_data(i, :, :) = delays;
        end
        if isfield(S, 'spike_counts')
            spike_counts_data(i, :, :) = S.spike_counts;
        end
    end

    savePath = fullfile('Results/', scaleFolder, trialsSubfolder, "N" + num2str(N), "Convergence");
    if ~exist(savePath, 'dir'), mkdir(savePath); end

    %% === Figure 1: Delays Statistics ===

    fig1 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w', 'Visible', show_figs);
    hold on;

    ci_fill = [1.0 0.85 0.75];
    gray_color = [0.5 0.5 0.5 0.1];

    x = 1:nTrials;
    y = nanmean(delays_data, 3);
    ci_low = prctile(y, (100-CI)/2);
    ci_high = prctile(y, (100+CI)/2);

    fill([x, fliplr(x)], [ci_high, fliplr(ci_low)], ...
         ci_fill, 'EdgeColor', 'none', 'DisplayName', num2str(CI) + "\% CI");

    for i = 1:size(y, 1)
        plot(x, y(i,:), 'Color', gray_color, 'LineWidth', 0.5, 'HandleVisibility', 'off');
    end

    plot(x, median(y), 'Color', [0.85 0.33 0.1], 'LineWidth', 2.5, 'DisplayName', 'Median');

    xlabel('Trial', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('Time Delay (ms)', 'Interpreter', 'latex', 'FontSize', 14);
    title(sprintf("Mean First Spike Timing per Trial\n %d simulations, N = %d", nRuns, N))
    legend('Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');

    set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');

    posi = get(gcf, 'Position');
    set(gcf, 'PaperSize', posi(3:4));

    print(fig1, fullfile(savePath, 'timeDelay'), '-dpdf', '-r600');
    print(fig1, fullfile(savePath, 'timeDelay'), '-dpng', '-r600');

    %% Finding the delay thresholds
    Y = y;
    epsilon = 0.001;
    [nCurves, nT] = size(Y);
    stabPoints = zeros(1, nCurves);

    figure('visible', show_figs); hold on;
    yyaxis right
    plot([1, nT], epsilon*[1, 1], 'r')

    for i = 1:nCurves
        yi = Y(i, :);

        dy = abs(diff(yi));
        dy_smooth = abs(movmean(diff(yi, 1), 100));

        yyaxis left
        plot(smooth(yi), 'b-');
        yyaxis right
        plot(dy_smooth, 'r-')

        idx = find(dy_smooth > epsilon, 1, "last");

        if isempty(idx) || idx == nT-1
            stabPoints(i) = NaN;
        else
            stabPoints(i) = idx;
            plot([idx, idx], [0, 0.04], 'g--')
        end
    end

    yyaxis right; ylabel("dy smoothed")
    yyaxis left;  ylabel("y")
    xlabel("Trials")
    title(sprintf('Delay slope threshold, N=%d', N))
    hold off;

    delayThresholds.(sprintf('N%d', N)) = stabPoints;

    fprintf('  Delay converged: %d / %d\n', sum(~isnan(stabPoints)), numel(stabPoints));
    if any(~isnan(stabPoints))
        fprintf('  Median delay stabilization: %.1f\n', median(stabPoints(~isnan(stabPoints))));
    end

    %% === Figure 2: Spike Count vs Trial ===

    fig2 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w', 'Visible', show_figs);
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
    title(sprintf("Mean Firing Rate per Trial\n %d simulations, N = %d", nRuns, N))

    legend('Location', 'northwest', 'Interpreter', 'latex', 'Box', 'off');
    set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');

    posi = get(gcf, 'Position');
    set(gcf, 'PaperSize', posi(3:4));

    print(fig2, fullfile(savePath, 'spikeCount'), '-dpdf', '-r600');
    print(fig2, fullfile(savePath, 'spikeCount'), '-dpng', '-r600');

    %% Finding the spike count thresholds
    Y = y;
    epsilon = 0.002;
    [nCurves, nT] = size(Y);
    stabPoints = zeros(1, nCurves);

    figure('visible', show_figs); hold on;
    yyaxis right
    plot([1, nT], epsilon*[1, 1], 'r')

    for i = 1:nCurves
        yi = Y(i, :);

        dy = abs(diff(yi));
        dy_smooth = movmean(diff(yi, 1), 100);

        yyaxis right
        plot(dy_smooth, 'r-')

        idx = find(dy_smooth > epsilon, 1, "last");

        if isempty(idx) || idx == nT-1 || yi(idx) < 1
            stabPoints(i) = NaN;
            yyaxis left
            plot(smooth(yi), 'b-');
        else
            stabPoints(i) = idx;
            plot([idx, idx], [0, 0.04], 'k--')
            yyaxis left
            plot(smooth(yi), 'g-');
        end
    end

    yyaxis right; ylabel("dy smoothed")
    yyaxis left;  ylabel("y")
    xlabel("Trials")
    title(sprintf('Spike-count slope threshold, N=%d', N))
    hold off;

    spikeThresholds.(sprintf('N%d', N)) = stabPoints;

    fprintf('  Spike converged: %d / %d\n', sum(~isnan(stabPoints)), numel(stabPoints));
    if any(~isnan(stabPoints))
        fprintf('  Median spike stabilization: %.1f\n', median(stabPoints(~isnan(stabPoints))));
    end
end

%% Save output
thresholds = delayThresholds;
save(delayThresholdPath, 'thresholds');

thresholds = spikeThresholds;
save(spikeThresholdPath, 'thresholds');

fprintf('\nSaved slope-based delay thresholds to:\n%s\n', delayThresholdPath);
fprintf('Saved slope-based spike-count thresholds to:\n%s\n', spikeThresholdPath);
