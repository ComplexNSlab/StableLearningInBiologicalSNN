% Step06_WeightStabilization.m
% =========================================================================
% Structural (synaptic weight) stabilisation analysis.
%
% For each network size and each simulation run, the script:
%   1. Loads saved weight snapshots (w_save from Patch1.mat).
%   2. Computes the mean absolute trial-to-trial weight change (delta-W)
%      across all existing synapses.
%   3. Applies a plateau-based criterion: finds the trial after the peak
%      delta-W where the smoothed curve falls and stays below
%      plateau + alpha*(peak − plateau) for holdWin consecutive samples.
%   4. Saves per-run stabilisation trials, thresholds, peak values, and
%      raw/smoothed delta-W curves to WeightStabilityResults.mat.
%
% INPUTS:
%   Data/{scaleFolder}/Trials{X}/N{N}/*/Patch1.mat  (contains obj.w_save)
%
% OUTPUTS:
%   Results/WeightStabilityResults.mat
% =========================================================================

%% Querying on the raw data to get delta w signals (this block takes time)
clear; clc;

% ---------------- SETTINGS FROM CONFIG ----------------
cfg = jsondecode(fileread('config.json'));
N_list      = cfg.networkSizes(:)';
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end
baseRoot    = fullfile(pwd, "Data", scaleFolder, trialsSubfolder);

% ---------------- ANALYSIS PARAMETERS ----------------
saveStride  = 5;       % weights saved every 5 actual trials

% Smoothing & hold parameters from config (converted to saved-snapshot units)
assert(isfield(cfg, 'smoothTrials'),  'config.json missing "smoothTrials"');
assert(isfield(cfg, 'holdTrials'),    'config.json missing "holdTrials"');
assert(isfield(cfg, 'stabilityFrac'), 'config.json missing "stabilityFrac"');
smoothWin = round(cfg.smoothTrials / saveStride);
holdWin   = round(cfg.holdTrials / saveStride);
alpha     = cfg.stabilityFrac;

tailFrac    = 0.20;    % last 20% of curve defines plateau
tailMinPts  = 20;      % minimum number of points in tail

% ------------------------------------------------
Results = struct();

% -------- Count total number of folders first --------
totalSteps = 0;
folderCache = cell(numel(N_list),1);

for iN = 1:numel(N_list)
    N = N_list(iN);
    baseFolder = fullfile(baseRoot, "N" + num2str(N));

    if ~isfolder(baseFolder)
        folderCache{iN} = [];
        continue;
    end

    items = dir(baseFolder);
    items = items([items.isdir]);
    items = items(~ismember({items.name}, {'.','..'}));

    folderCache{iN} = items;
    totalSteps = totalSteps + numel(items);
end

if totalSteps == 0
    error('No simulation folders found.');
end

% -------- Waitbar --------
hWait = waitbar(0, 'Starting analysis...');
cleanupObj = onCleanup(@() closeWaitbarSafe(hWait));

stepCount = 0;

for iN = 1:numel(N_list)
    N = N_list(iN);
    fprintf('\nProcessing N = %d\n', N);

    baseFolder = fullfile(baseRoot, "N" + num2str(N));
    items = folderCache{iN};

    if isempty(items)
        warning('Folder not found or empty: %s', baseFolder);
        continue;
    end

    nItems = numel(items);
    folderNames   = strings(nItems,1);
    validMask     = false(nItems,1);

    stabTrial     = nan(nItems,1);   % actual trial number
    stabIdxSaved  = nan(nItems,1);   % saved-sample index

    threshUsed    = nan(nItems,1);
    peakValUsed   = nan(nItems,1);
    peakTrial     = nan(nItems,1);
    plateauUsed   = nan(nItems,1);

    deltaCurvesRaw    = cell(nItems,1);
    deltaCurvesSmooth = cell(nItems,1);

    for k = 1:nItems
        stepCount = stepCount + 1;

        waitbar(stepCount / totalSteps, hWait, ...
            sprintf('Processing N=%d (%d/%d), sim %d/%d', ...
            N, iN, numel(N_list), k, nItems));

        folderNames(k) = string(items(k).name);
        matFile = fullfile(baseFolder, items(k).name, "Patch1.mat");

        if ~isfile(matFile)
            warning('Missing file: %s', matFile);
            continue;
        end

        S = load(matFile, 'obj');
        if ~isfield(S, 'obj')
            warning('No obj in: %s', matFile);
            continue;
        end

        obj = S.obj;
        W = single(obj.w_save);             % N x N x Tsave
        A = logical(obj.Adjacency_matrix);  % N x N
        Ne = obj.Ne;

        if ndims(W) ~= 3
            warning('Skipping %s because w_save is not 3D.', matFile);
            continue;
        end

        [N1, N2, Tsave] = size(W);
        if N1 ~= N || N2 ~= N || ~isequal(size(A), [N N])
            warning('Skipping %s because dimensions do not match N=%d.', matFile, N);
            continue;
        end

        % Restrict to excitatory-to-excitatory (EE) synapses only —
        % STDP only modifies EE weights, so EI/IE/II are static.
        A_ee = false(size(A));
        A_ee(1:Ne, 1:Ne) = A(1:Ne, 1:Ne);

        % Flatten weights to [N^2 x Tsave], then keep existing EE edges only
        W2 = reshape(W, N*N, Tsave);
        W2 = W2(A_ee(:), :);    % [nEdges_ee x Tsave]

        % Drop synapses that stay zero for the entire simulation
        % (edge exists in adjacency but STDP never activates it)
        activeMask = any(W2 ~= 0, 2);
        W2 = W2(activeMask, :);

        if isempty(W2) || size(W2,2) < 2
            warning('Skipping %s because no valid EE edge/time data.', matFile);
            continue;
        end

        % Mean absolute trial-to-trial change across existing synapses
        % This is computed between saved weight snapshots
        dW = mean(abs(diff(W2, 1, 2)), 1);   % [1 x (Tsave-1)]

        % Smooth curve
        dW_s = movmean(dW, smoothWin);

        % ---- Plateau-based structural stabilization ----
        [peakVal, peakIdx] = max(dW_s);

        nTail = max(tailMinPts, round(tailFrac * numel(dW_s)));
        nTail = min(nTail, numel(dW_s));
        plateauVal = median(dW_s(end-nTail+1:end), 'omitnan');

        % threshold between peak and plateau
        thr = plateauVal + alpha * (peakVal - plateauVal);

        % Search only after peak
        below = dW_s <= thr;

        tStar_idx = NaN;
        if (numel(dW_s) - peakIdx + 1) >= holdWin
            runConv = conv(double(below(peakIdx:end)), ones(1, holdWin), 'valid');
            idxLocal = find(runConv == holdWin, 1, 'first');
            if ~isempty(idxLocal)
                tStar_idx = peakIdx + idxLocal - 1;
            end
        end

        % Convert saved index to actual trials
        % dW index m corresponds roughly to saved snapshot transition m -> m+1
        % each saved snapshot is separated by saveStride actual trials
        if ~isnan(tStar_idx)
            tStar_trial = tStar_idx * saveStride;
        else
            tStar_trial = NaN;
        end

        deltaCurvesRaw{k}    = dW;
        deltaCurvesSmooth{k} = dW_s;

        stabIdxSaved(k) = tStar_idx;
        stabTrial(k)    = tStar_trial;
        threshUsed(k)   = thr;
        peakValUsed(k)  = peakVal;
        peakTrial(k)    = peakIdx * saveStride;
        plateauUsed(k)  = plateauVal;

        validMask(k)    = true;
    end

    % Keep valid entries only
    Results(iN).N = N;
    Results(iN).folderNames = folderNames(validMask);

    Results(iN).stabTrial = stabTrial(validMask);         % actual trials
    Results(iN).stabIdxSaved = stabIdxSaved(validMask);   % saved-sample index

    Results(iN).threshold = threshUsed(validMask);
    Results(iN).peakValue = peakValUsed(validMask);
    Results(iN).peakTrial = peakTrial(validMask);
    Results(iN).plateauValue = plateauUsed(validMask);

    Results(iN).deltaRaw = {deltaCurvesRaw{validMask}};
    Results(iN).deltaSmooth = {deltaCurvesSmooth{validMask}};

    Results(iN).nValid = sum(validMask);
    Results(iN).nTotal = nItems;

    fprintf('  Loaded %d / %d simulations\n', Results(iN).nValid, Results(iN).nTotal);

    if Results(iN).nValid > 0
        nConv = sum(~isnan(Results(iN).stabTrial));
        fprintf('  Structural plateau convergence: %d / %d\n', nConv, Results(iN).nValid);

        if nConv > 0
            fprintf('  Median structural stabilization trial: %.1f\n', ...
                median(Results(iN).stabTrial(~isnan(Results(iN).stabTrial))));
        end
    end
end

waitbar(1, hWait, 'Done.');

% -------- helper function --------
function closeWaitbarSafe(h)
    if ~isempty(h) && isvalid(h)
        close(h);
    end
end
%% Saving the results 

paramTag = sprintf('frac%03d_smooth%d_hold%d', ...
    round(alpha * 100), smoothWin * saveStride, holdWin * saveStride);
saveFolder = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);
if ~isfolder(saveFolder)
    mkdir(saveFolder);
end

analysisParams = struct();
analysisParams.N_list     = N_list;
analysisParams.baseRoot   = baseRoot;
analysisParams.saveStride = saveStride;
analysisParams.smoothWin  = smoothWin;
analysisParams.holdWin    = holdWin;
analysisParams.tailFrac   = tailFrac;
analysisParams.tailMinPts = tailMinPts;
analysisParams.alpha      = alpha;
analysisParams.paramTag   = paramTag;

partialFile = fullfile(saveFolder, 'WeightStabilityResults.mat');
save(partialFile, 'Results', 'analysisParams', '-v7.3');

fprintf('Saved to %s\n', partialFile);
