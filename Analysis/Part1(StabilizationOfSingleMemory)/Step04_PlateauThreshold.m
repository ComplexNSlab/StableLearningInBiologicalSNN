% Step04_PlateauThreshold.m
% =========================================================================
% Plateau-based stabilisation detection for latency and firing-rate
% representations across all network sizes.
%
% For each N and each simulation run, the script:
%   1. Computes the mean first-spike latency and mean spike count per trial.
%   2. Estimates a plateau value from the last 20% of the smoothed curve.
%   3. Defines a tolerance band = alpha * |initial_value − plateau|.
%   4. Finds the first trial where the smoothed curve stays within the
%      band for holdWin consecutive trials — this is the stabilisation trial.
%
% This is the PREFERRED method over Step04_SlopeThreshold.m.
%
% INPUTS:
%   Data/{scaleFolder}/Trials{X}/N{N}/*/MemoryRepresentations.mat
%
% OUTPUTS:
%   Results/StabilizationResults/{paramTag}/DelaysThreshold_plateau.mat
%   Results/StabilizationResults/{paramTag}/SpikeCountsThreshold_plateau.mat
%   Results/StabilizationResults/{paramTag}/SpikeOrderThreshold_plateau.mat
% =========================================================================

clc; clear;

%% USER SETTINGS
cfg = jsondecode(fileread('config.json'));
N_list      = cfg.networkSizes(:)';
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

show_figs   = 'on';   % 'on' for diagnostics
nTrials     = cfg.nTrials;

% Smoothing & hold parameters from config (in trial units)
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
smoothWin  = cfg.smoothTrials;
holdWin    = cfg.holdTrials;
tailFrac    = 0.20;    % last 20% used for plateau estimate
tailMinPts  = 50;      % minimum tail length
alphaDelay  = cfg.stabilityFrac;
alphaSpike  = cfg.stabilityFrac;
N_representative = cfg.N;  % network size for convergence curves saved to .mat

%% Build parameter-stamped results subfolder
paramTag = sprintf('frac%03d_smooth%d_hold%d', ...
    round(alphaDelay * 100), smoothWin, holdWin);
resultsDir = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

%% Load existing threshold structs if they exist
delayPath = fullfile(resultsDir, 'DelaysThreshold_plateau.mat');
spikePath = fullfile(resultsDir, 'SpikeCountsThreshold_plateau.mat');
orderPath = fullfile(resultsDir, 'SpikeOrderThreshold_plateau.mat');

if isfile(delayPath)
    S = load(delayPath, 'delayThresholds');
    if isfield(S, 'delayThresholds')
        delayThresholds = S.delayThresholds;
    else
        delayThresholds = struct();
    end
else
    delayThresholds = struct();
end

if isfile(spikePath)
    S = load(spikePath, 'spikeThresholds');
    if isfield(S, 'spikeThresholds')
        spikeThresholds = S.spikeThresholds;
    else
        spikeThresholds = struct();
    end
else
    spikeThresholds = struct();
end

if isfile(orderPath)
    S = load(orderPath, 'orderThresholds');
    if isfield(S, 'orderThresholds')
        orderThresholds = S.orderThresholds;
    else
        orderThresholds = struct();
    end
else
    orderThresholds = struct();
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
    orders_data = nan(nRuns, nTrials, N);

    for i = 1:nRuns
        filePath = fullfile(folderPath, sim_folders(i).name, "MemoryRepresentations.mat");
        if ~isfile(filePath)
            warning('Missing file: %s', filePath);
            continue;
        end

        S = load(filePath, 'delays', 'spike_counts', 'orders_together');

        if isfield(S, 'delays')
            delays = S.delays;
            delays(delays == 0) = nan;
            delays_data(i,:,:) = delays;
        end

        if isfield(S, 'spike_counts')
            spike_counts_data(i,:,:) = S.spike_counts;
        end

        if isfield(S, 'orders_together')
            orders_data(i,:,:) = S.orders_together;
        end
    end

    %% Build one curve per run
    Y_delay = squeeze(nanmean(delays_data, 3));        % [nRuns x nTrials]
    Y_spike = squeeze(mean(spike_counts_data, 3));     % [nRuns x nTrials]

    %% Build correlation-with-final curve for spike order
    %  Non-spiking neurons (order == 0) are assigned rank N+1 ("tied for
    %  last") so the Spearman correlation captures both neuron recruitment
    %  and ordering changes.
    Y_order = nan(nRuns, nTrials);
    for i = 1:nRuns
        ord_i = squeeze(orders_data(i, :, :));  % [nTrials x N]
        if all(isnan(ord_i(:))), continue; end
        ord_i(ord_i == 0) = N + 1;  % non-spiking → last rank
        final_ord = ord_i(end, :);
        for t = 1:nTrials
            Y_order(i, t) = corr(ord_i(t,:)', final_ord', 'Type', 'Spearman');
        end
    end

    %% Compute plateau-based stabilization trials
    [stabDelay, plateauDelay, thrDelay] = compute_plateau_thresholds( ...
        Y_delay, smoothWin, holdWin, tailFrac, tailMinPts, alphaDelay);

    [stabSpike, plateauSpike, thrSpike] = compute_plateau_thresholds( ...
        Y_spike, smoothWin, holdWin, tailFrac, tailMinPts, alphaSpike);

    [stabOrder, plateauOrder, thrOrder] = compute_plateau_thresholds( ...
        Y_order, smoothWin, holdWin, tailFrac, tailMinPts, alphaDelay);

    %% Save into structs
    fieldN = sprintf('N%d', N);

    delayThresholds.(fieldN) = stabDelay;
    delayThresholds.([fieldN '_plateau']) = plateauDelay;
    delayThresholds.([fieldN '_thr']) = thrDelay;

    spikeThresholds.(fieldN) = stabSpike;
    spikeThresholds.([fieldN '_plateau']) = plateauSpike;
    spikeThresholds.([fieldN '_thr']) = thrSpike;

    orderThresholds.(fieldN) = stabOrder;
    orderThresholds.([fieldN '_plateau']) = plateauOrder;
    orderThresholds.([fieldN '_thr']) = thrOrder;

    fprintf('  Delay converged: %d / %d\n', sum(~isnan(stabDelay)), numel(stabDelay));
    if any(~isnan(stabDelay))
        fprintf('  Median delay stabilization: %.1f\n', median(stabDelay(~isnan(stabDelay))));
    end

    fprintf('  Spike converged: %d / %d\n', sum(~isnan(stabSpike)), numel(stabSpike));
    if any(~isnan(stabSpike))
        fprintf('  Median spike stabilization: %.1f\n', median(stabSpike(~isnan(stabSpike))));
    end

    fprintf('  Order converged: %d / %d\n', sum(~isnan(stabOrder)), numel(stabOrder));
    if any(~isnan(stabOrder))
        fprintf('  Median order stabilization: %.1f\n', median(stabOrder(~isnan(stabOrder))));
    end

    %% Optional diagnostic figures
    if strcmpi(show_figs, 'on')
        make_debug_plot(Y_delay, stabDelay, plateauDelay, thrDelay, smoothWin, ...
            sprintf('Delay plateau criterion, N=%d', N));
        make_debug_plot(Y_spike, stabSpike, plateauSpike, thrSpike, smoothWin, ...
            sprintf('Spike-count plateau criterion, N=%d', N));
        make_debug_plot(Y_order, stabOrder, plateauOrder, thrOrder, smoothWin, ...
            sprintf('Spike-order plateau criterion, N=%d', N));
    end

    %% Store convergence curves for representative N (plotted by Step04b)
    if N == N_representative
        convCurves.Y_delay = Y_delay;
        convCurves.Y_spike = Y_spike;
        convCurves.Y_order = Y_order;
        convCurves.N       = N;
        convCurves.nTrials = nTrials;
    end
end

%% Save output
save(delayPath, 'delayThresholds');
save(spikePath, 'spikeThresholds');
save(orderPath, 'orderThresholds');

if exist('convCurves', 'var')
    convPath = fullfile(resultsDir, 'ConvergenceCurves.mat');
    save(convPath, 'convCurves');
    fprintf('Saved convergence curves for N=%d to:\n%s\n', convCurves.N, convPath);
end

fprintf('\nSaved plateau-based delay thresholds to:\n%s\n', delayPath);
fprintf('Saved plateau-based spike-count thresholds to:\n%s\n', spikePath);
fprintf('Saved plateau-based spike-order thresholds to:\n%s\n', orderPath);

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