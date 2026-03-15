clc; clear;

set(groot, 'DefaultAxesFontName', 'Times New Roman')
set(groot, 'DefaultTextInterpreter', 'latex');
set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
set(groot, 'DefaultLegendInterpreter', 'latex');
set(groot, 'DefaultAxesFontSize', 14);
set(groot, 'DefaultTextFontSize', 14);
set(groot, 'DefaultLegendFontSize', 13);

%% USER SETTINGS
show_figs   = 'off';   % 'on' for diagnostics
N_list      = 100:100:1000;
nTrials     = 1500;
scaleFolder = 'Scaled50';

smoothWin   = 100;     % smoothing window on representation curves
holdWin     = 50;      % must stay near plateau this many consecutive trials
tailFrac    = 0.20;    % last 20% used for plateau estimate
tailMinPts  = 50;      % minimum tail length
alphaDelay  = 0.10;    % tolerance fraction for delays
alphaSpike  = 0.10;    % tolerance fraction for spike counts

%% Load existing threshold structs if they exist
delayPath = fullfile("Data", scaleFolder, "Trials1500", "DelaysThreshold_plateau.mat");
spikePath = fullfile("Data", scaleFolder, "Trials1500", "SpikeCountsThreshold_plateau.mat");

if isfile(delayPath)
    S = load(delayPath, 'thresholds');
    if isfield(S, 'thresholds')
        delayThresholds = S.thresholds;
    else
        delayThresholds = struct();
    end
else
    delayThresholds = struct();
end

if isfile(spikePath)
    S = load(spikePath, 'thresholds');
    if isfield(S, 'thresholds')
        spikeThresholds = S.thresholds;
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

    folderPath = fullfile(pwd, "Data", scaleFolder, "Trials1500", "N" + num2str(N));
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
            delays_data(i,:,:) = delays;
        end

        if isfield(S, 'spike_counts')
            spike_counts_data(i,:,:) = S.spike_counts;
        end
    end

    %% Build one curve per run
    Y_delay = squeeze(nanmean(delays_data, 3));        % [nRuns x nTrials]
    Y_spike = squeeze(mean(spike_counts_data, 3));     % [nRuns x nTrials]

    %% Compute plateau-based stabilization trials
    [stabDelay, plateauDelay, thrDelay] = compute_plateau_thresholds( ...
        Y_delay, smoothWin, holdWin, tailFrac, tailMinPts, alphaDelay);

    [stabSpike, plateauSpike, thrSpike] = compute_plateau_thresholds( ...
        Y_spike, smoothWin, holdWin, tailFrac, tailMinPts, alphaSpike);

    %% Save into structs
    fieldN = sprintf('N%d', N);

    delayThresholds.(fieldN) = stabDelay;
    delayThresholds.([fieldN '_plateau']) = plateauDelay;
    delayThresholds.([fieldN '_thr']) = thrDelay;

    spikeThresholds.(fieldN) = stabSpike;
    spikeThresholds.([fieldN '_plateau']) = plateauSpike;
    spikeThresholds.([fieldN '_thr']) = thrSpike;

    fprintf('  Delay converged: %d / %d\n', sum(~isnan(stabDelay)), numel(stabDelay));
    if any(~isnan(stabDelay))
        fprintf('  Median delay stabilization: %.1f\n', median(stabDelay(~isnan(stabDelay))));
    end

    fprintf('  Spike converged: %d / %d\n', sum(~isnan(stabSpike)), numel(stabSpike));
    if any(~isnan(stabSpike))
        fprintf('  Median spike stabilization: %.1f\n', median(stabSpike(~isnan(stabSpike))));
    end

    %% Optional diagnostic figures
    if strcmpi(show_figs, 'on')
        make_debug_plot(Y_delay, stabDelay, plateauDelay, thrDelay, smoothWin, ...
            sprintf('Delay plateau criterion, N=%d', N));
        make_debug_plot(Y_spike, stabSpike, plateauSpike, thrSpike, smoothWin, ...
            sprintf('Spike-count plateau criterion, N=%d', N));
    end
end

%% Save output
save(delayPath, 'delayThresholds');
save(spikePath, 'spikeThresholds');

fprintf('\nSaved plateau-based delay thresholds to:\n%s\n', delayPath);
fprintf('Saved plateau-based spike-count thresholds to:\n%s\n', spikePath);

%% ============================================================
function [stabPoints, plateauVals, threshVals] = compute_plateau_thresholds( ...
    Y, smoothWin, holdWin, tailFrac, tailMinPts, alpha)

    nCurves = size(Y, 1);

    stabPoints  = nan(1, nCurves);
    plateauVals = nan(1, nCurves);
    threshVals  = nan(1, nCurves);

    for i = 1:nCurves
        y = Y(i, :);

        if all(isnan(y))
            continue;
        end

        yFilled = fillmissing(y, 'linear', 'EndValues', 'nearest');
        ySmooth = movmean(yFilled, smoothWin);

        nTail = max(tailMinPts, round(tailFrac * numel(ySmooth)));
        nTail = min(nTail, numel(ySmooth));
        plateauVal = median(ySmooth(end-nTail+1:end), 'omitnan');

        nInit = min(100, numel(ySmooth));
        initDist = median(abs(ySmooth(1:nInit) - plateauVal), 'omitnan');

        if isnan(initDist) || initDist == 0
            plateauVals(i) = plateauVal;
            threshVals(i) = NaN;
            stabPoints(i) = NaN;
            continue;
        end

        thr = alpha * initDist;
        distToPlateau = abs(ySmooth - plateauVal);

        below = distToPlateau <= thr;

        tStar = NaN;
        if numel(below) >= holdWin
            runConv = conv(double(below), ones(1, holdWin), 'valid');
            idx = find(runConv == holdWin, 1, 'first');
            if ~isempty(idx)
                tStar = idx;
            end
        end

        stabPoints(i)  = tStar;
        plateauVals(i) = plateauVal;
        threshVals(i)  = thr;
    end
end

%% ============================================================
function make_debug_plot(Y, stabPoints, plateauVals, threshVals, smoothWin, figTitle)
    figure('Color', 'w'); hold on;

    nShow = min(10, size(Y,1));
    idxShow = find(~isnan(stabPoints), nShow, 'first');
    if isempty(idxShow)
        title([figTitle ' (no valid runs)']);
        return;
    end

    for k = 1:numel(idxShow)
        i = idxShow(k);
        y = Y(i,:);
        yFilled = fillmissing(y, 'linear', 'EndValues', 'nearest');
        ySmooth = movmean(yFilled, smoothWin);

        plot(ySmooth, 'LineWidth', 1.5);
        yline(plateauVals(i), ':k', 'HandleVisibility', 'off');
        yline(plateauVals(i)+threshVals(i), '--r', 'HandleVisibility', 'off');
        yline(plateauVals(i)-threshVals(i), '--r', 'HandleVisibility', 'off');

        if ~isnan(stabPoints(i))
            xline(stabPoints(i), '--g', 'HandleVisibility', 'off');
        end
    end

    xlabel('Trial');
    ylabel('Representation value');
    title(figTitle);
    grid on;
end