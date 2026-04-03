% Step09_RadialStabilization.m
% =========================================================================
% Radial (polar-decomposition) stabilisation analysis.
%
% For each network size and each simulation run, the script:
%   1. Loads saved weight snapshots (w_save from Patch1.mat).
%   2. Restricts to active EE synapses (nonzero at least once).
%   3. Computes the radial change Delta_r(t) = ||g(t+1)|| - ||g(t)||
%      (change in L2 norm of the weight vector).
%   4. Also computes the angular change Delta_theta(t) = arccos(...)
%      (rotation of the weight vector on the hypersphere).
%   5. Applies a zero-crossing stabilisation criterion on smoothed |Delta_r|:
%      finds the trial after the peak where |Delta_r| stays below a small
%      absolute threshold for holdWin consecutive saved samples.
%   6. Saves per-run results to Results/RadialStabilityResults.mat.
%
% Because Delta_r converges to a true zero (unlike the L1 measure in
% Step06 which has a nonzero rotational residual), the stabilisation
% criterion is simpler and more robust.
%
% INPUTS:
%   Data/{scaleFolder}/{trialsSubfolder}/N{N}/*/Patch1.mat
%
% OUTPUTS:
%   Results/RadialStabilityResults.mat
% =========================================================================

%% Main analysis (this block takes time)
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
baseRoot = fullfile(pwd, "Data", scaleFolder, trialsSubfolder);

% ---------------- ANALYSIS PARAMETERS ----------------
saveStride  = 5;       % weights saved every 5 actual trials

% Smoothing & hold parameters from config (converted to saved-snapshot units)
if isfield(cfg, 'smoothTrials')
    smoothWin = round(cfg.smoothTrials / saveStride);
else
    smoothWin = 20;
end
if isfield(cfg, 'holdTrials')
    holdWin = round(cfg.holdTrials / saveStride);
else
    holdWin = 30;
end

tailFrac    = 0.20;    % last 20% of curve defines plateau
tailMinPts  = 20;      % minimum number of points in tail

% Stability fraction: read from config for consistency with Step04/Step06.
% thr = plateau + stabilityFrac * (peak - plateau)
% Plateau is computed from the tail, not assumed to be zero.
if isfield(cfg, 'stabilityFrac')
    alpha = cfg.stabilityFrac;
else
    alpha = 0.10;
end

% ------------------------------------------------
Results = struct();

% -------- Count total number of folders first --------
totalSteps = 0;
folderCache = cell(numel(N_list), 1);

for iN = 1:numel(N_list)
    N = N_list(iN);
    baseFolder = fullfile(baseRoot, "N" + num2str(N));

    if ~isfolder(baseFolder)
        folderCache{iN} = [];
        continue;
    end

    items = dir(baseFolder);
    items = items([items.isdir]);
    items = items(~ismember({items.name}, {'.', '..'}));

    folderCache{iN} = items;
    totalSteps = totalSteps + numel(items);
end

if totalSteps == 0
    error('No simulation folders found.');
end

% -------- Waitbar --------
hWait = waitbar(0, 'Starting radial analysis...');
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
    folderNames   = strings(nItems, 1);
    validMask     = false(nItems, 1);

    stabTrial     = nan(nItems, 1);
    stabIdxSaved  = nan(nItems, 1);
    threshUsed    = nan(nItems, 1);
    peakAbsDr     = nan(nItems, 1);
    peakTrial     = nan(nItems, 1);
    plateauUsed   = nan(nItems, 1);

    drCurvesRaw       = cell(nItems, 1);
    drCurvesSmooth    = cell(nItems, 1);
    dthetaCurvesRaw   = cell(nItems, 1);
    dthetaCurvesSmooth = cell(nItems, 1);
    normCurves        = cell(nItems, 1);
    nActiveSyn        = nan(nItems, 1);

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

        % Restrict to excitatory-to-excitatory (EE) synapses only
        A_ee = false(size(A));
        A_ee(1:Ne, 1:Ne) = A(1:Ne, 1:Ne);

        % Flatten weights, keep existing EE edges
        W2 = reshape(W, N*N, Tsave);
        W2 = W2(A_ee(:), :);

        % Drop synapses that stay zero for the entire simulation
        activeMask = any(W2 ~= 0, 2);
        W2 = W2(activeMask, :);

        if isempty(W2) || size(W2, 2) < 2
            warning('Skipping %s because no valid EE edge/time data.', matFile);
            continue;
        end

        nActiveSyn(k) = size(W2, 1);

        % ---- Radial change: Delta_r(t) = ||g(t+1)|| - ||g(t)|| ----
        norms = vecnorm(W2, 2, 1);          % [1 x Tsave]
        dr = diff(norms);                    % [1 x (Tsave-1)]

        % ---- Angular change: Delta_theta(t) ----
        dotprods = sum(W2(:, 1:end-1) .* W2(:, 2:end), 1);
        norm_prod = norms(1:end-1) .* norms(2:end);
        norm_prod(norm_prod == 0) = eps;
        cos_theta = dotprods ./ norm_prod;
        cos_theta = min(max(cos_theta, -1), 1);
        dtheta = acos(cos_theta);            % [1 x (Tsave-1)], radians

        % Smooth
        dr_s     = movmean(dr, smoothWin);
        dtheta_s = movmean(dtheta, smoothWin);

        % ---- Stabilisation criterion on |Delta_r| ----
        % Compute plateau from tail, same method as Step06 (not assumed zero)
        abs_dr_s = abs(dr_s);
        [peakVal, peakIdx] = max(abs_dr_s);

        nTail = max(tailMinPts, round(tailFrac * numel(abs_dr_s)));
        nTail = min(nTail, numel(abs_dr_s));
        plateauVal = median(abs_dr_s(end-nTail+1:end), 'omitnan');

        thr = plateauVal + alpha * (peakVal - plateauVal);

        below = abs_dr_s <= thr;

        tStar_idx = NaN;
        if (numel(abs_dr_s) - peakIdx + 1) >= holdWin
            runConv = conv(double(below(peakIdx:end)), ones(1, holdWin), 'valid');
            idxLocal = find(runConv == holdWin, 1, 'first');
            if ~isempty(idxLocal)
                tStar_idx = peakIdx + idxLocal - 1;
            end
        end

        if ~isnan(tStar_idx)
            tStar_trial = tStar_idx * saveStride;
        else
            tStar_trial = NaN;
        end

        drCurvesRaw{k}       = dr;
        drCurvesSmooth{k}    = dr_s;
        dthetaCurvesRaw{k}   = dtheta;
        dthetaCurvesSmooth{k} = dtheta_s;
        normCurves{k}        = norms;

        stabIdxSaved(k) = tStar_idx;
        stabTrial(k)    = tStar_trial;
        threshUsed(k)   = thr;
        peakAbsDr(k)    = peakVal;
        peakTrial(k)    = peakIdx * saveStride;
        plateauUsed(k)  = plateauVal;

        validMask(k) = true;
    end

    % Store results for this network size
    Results(iN).N           = N;
    Results(iN).folderNames = folderNames(validMask);

    Results(iN).stabTrial    = stabTrial(validMask);
    Results(iN).stabIdxSaved = stabIdxSaved(validMask);
    Results(iN).threshold    = threshUsed(validMask);
    Results(iN).peakAbsDr    = peakAbsDr(validMask);
    Results(iN).peakTrial    = peakTrial(validMask);
    Results(iN).plateauValue = plateauUsed(validMask);

    Results(iN).drRaw        = {drCurvesRaw{validMask}};
    Results(iN).drSmooth     = {drCurvesSmooth{validMask}};
    Results(iN).dthetaRaw    = {dthetaCurvesRaw{validMask}};
    Results(iN).dthetaSmooth = {dthetaCurvesSmooth{validMask}};
    Results(iN).norms        = {normCurves{validMask}};
    Results(iN).nActiveSyn   = nActiveSyn(validMask);

    Results(iN).nValid = sum(validMask);
    Results(iN).nTotal = nItems;

    fprintf('  Loaded %d / %d simulations\n', Results(iN).nValid, Results(iN).nTotal);

    if Results(iN).nValid > 0
        nConv = sum(~isnan(Results(iN).stabTrial));
        fprintf('  Radial convergence: %d / %d\n', nConv, Results(iN).nValid);

        if nConv > 0
            fprintf('  Median radial stabilization trial: %.1f\n', ...
                median(Results(iN).stabTrial(~isnan(Results(iN).stabTrial))));
        end
    end
end

waitbar(1, hWait, 'Done.');

%% Saving the results

paramTag = sprintf('frac%03d_smooth%d_hold%d', ...
    round(alpha * 100), smoothWin * saveStride, holdWin * saveStride);
saveFolder = fullfile(pwd, 'Results', 'StabilizationResults');
if ~isfolder(saveFolder)
    mkdir(saveFolder);
end

analysisParams = struct();
analysisParams.N_list      = N_list;
analysisParams.baseRoot    = baseRoot;
analysisParams.saveStride  = saveStride;
analysisParams.smoothWin   = smoothWin;
analysisParams.holdWin     = holdWin;
analysisParams.tailFrac    = tailFrac;
analysisParams.tailMinPts  = tailMinPts;
analysisParams.alpha       = alpha;
analysisParams.paramTag    = paramTag;

outFile = fullfile(saveFolder, sprintf('RadialStabilityResults_%s.mat', paramTag));
save(outFile, 'Results', 'analysisParams', '-v7.3');

fprintf('\nSaved to %s\n', outFile);

% -------- helper function --------
function closeWaitbarSafe(h)
    if ~isempty(h) && isvalid(h)
        close(h);
    end
end
