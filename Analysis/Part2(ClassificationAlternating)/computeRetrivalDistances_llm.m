% ComputeRetrievalDistances.m
% =========================================================================
% Computes pairwise Pearson similarity metrics from retrieval response data
% and saves results to 'retrievalDistances.csv'.
%
% OVERVIEW:
%   For each simulation file (alpha_XX.mat), this script:
%     1. Loads recall response activity (X_responseActivity) and class
%        labels (Y_memoryClass) from .mat files under Data/.
%     2. Computes the full pairwise Pearson similarity matrix between all
%        response vectors (100 trials × (M+1) classes: M memories + 1 random).
%     3. Reshapes into a (M+1)×(M+1) block-averaged similarity matrix.
%     4. Extracts four key metrics:
%        - s_intra_memory: mean diagonal (within-memory similarity, M values)
%        - s_intra_rand:   diagonal entry for the random class
%        - s_inter_mem:    mean upper-triangle (between-memory similarity)
%        - s_inter_rand:   similarity between random class and each memory
%        - std_intra_memory: std of within-memory similarities across M memories
%        - std_inter_mem:    std of all pairwise inter-memory similarities
%
% DATA FOLDER STRUCTURE:
%   Data/
%     N{size}/                           e.g., N100, N400, N800
%       {M}memories/                     e.g., 10memories, 50memories
%         {simID}/                       e.g., Apr_14_2025_14_32_49
%           recallsResponses/
%             alpha_{percent}.mat        e.g., alpha_10.mat (alpha = 0.10)
%
% CONFIGURATION:
%   N_FILTER  — Set this to restrict processing to specific network sizes.
%               e.g., [100 200] processes only N=100 and N=200.
%               Set to [] to process all N values (default).
%   M_MAX     — Skip files with M > M_MAX (default: 256).
%
% BACKFILL MODE:
%   If the CSV already exists but is missing newer columns (e.g.,
%   std_intra_memory, std_inter_mem), the script automatically detects this
%   and reprocesses only those rows to fill in the missing values, without
%   recomputing already-complete rows.
%
% USAGE:
%   1. Set N_FILTER below to choose which N values to process.
%   2. Run the script. Progress is shown via a waitbar.
%   3. Results are appended/merged into retrievalDistances.csv.
%   4. Run again with a different N_FILTER to incrementally add more data.
% =========================================================================

clc; clear;

% ========================= CONFIGURATION =================================
N_FILTER = [100];    % Which N values to process. [] = all. e.g., [100 200 400]
M_MAX    = 10;   % Skip simulations with more than this many memories
% =========================================================================

scriptDir = fileparts(mfilename('fullpath'));
if ~isfolder(fullfile(scriptDir, 'Data'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
rootDir = fullfile(scriptDir, 'Data');
resultsFile = fullfile(scriptDir, 'retrievalDistances.csv');

% --- Load previous results (if any) -------------------------------------
if isfile(resultsFile)
    prevResults = readtable(resultsFile, 'TextType', 'string');
else
    prevResults = table();
end

% --- Backfill detection: check if new columns are missing ----------------
needsBackfill = ~isempty(prevResults) && ...
    (~ismember('std_intra_memory', prevResults.Properties.VariableNames) || ...
     ~ismember('std_inter_mem', prevResults.Properties.VariableNames));

if ~isempty(prevResults) && ~ismember('std_intra_memory', prevResults.Properties.VariableNames)
    prevResults.std_intra_memory = NaN(height(prevResults), 1);
end
if ~isempty(prevResults) && ~ismember('std_inter_mem', prevResults.Properties.VariableNames)
    prevResults.std_inter_mem = NaN(height(prevResults), 1);
end

% --- Discover all .mat files and optionally filter by N ------------------
allFiles = dir(fullfile(rootDir, '**', 'alpha_*.mat'));

if ~isempty(N_FILTER)
    % Extract N from each file path and keep only those matching N_FILTER
    keepMask = false(numel(allFiles), 1);
    for k = 1:numel(allFiles)
        parts = strsplit(allFiles(k).folder, filesep);
        for j = 1:numel(parts)
            if ~isempty(regexp(parts{j}, '^N\d+$', 'once'))
                fileN = str2double(regexprep(parts{j}, '\D', ''));
                if ismember(fileN, N_FILTER)
                    keepMask(k) = true;
                end
                break;
            end
        end
    end
    files = allFiles(keepMask);
    fprintf('Filtered to N = [%s]: %d / %d files.\n', ...
        num2str(N_FILTER), numel(files), numel(allFiles));
else
    files = allFiles;
    fprintf('Processing all %d files (no N filter).\n', numel(files));
end

nFiles = numel(files);
if nFiles == 0
    disp('No files to process.'); return;
end

% --- Pre-filter: remove files already fully processed --------------------
% This avoids sending prevResults into the loop and skipping inside.
if ~isempty(prevResults) && ismember('simID', prevResults.Properties.VariableNames)
    toProcess = false(nFiles, 1);
    for k = 1:nFiles
        [simID, N, M, alpha] = parseFileInfo(files(k));
        rowMatch = any(prevResults.simID == simID & prevResults.N == N & ...
                       prevResults.M == M & abs(prevResults.alpha - alpha) < 1e-10);
        if needsBackfill && rowMatch
            toProcess(k) = true;   % needs std columns backfilled
        elseif ~rowMatch && M <= M_MAX
            toProcess(k) = true;   % new file
        end
    end
    files = files(toProcess);
    fprintf('After filtering done/skipped: %d files to process.\n', numel(files));
    nFiles = numel(files);
    if nFiles == 0
        disp('All files already processed.'); return;
    end
end

% --- Process files sequentially with incremental saving ------------------
SAVE_EVERY = 50;  % save progress to CSV every N files
newResults = [];

hWait = waitbar(0, sprintf('Processing 0/%d files...', nFiles));
for k = 1:nFiles
    result = processFile(files(k), M_MAX);
    
    if ~isempty(result) && ~isnan(result.N)
        newResults = [newResults; result];
    end
    
    % Incremental save every SAVE_EVERY files (protects against crashes)
    if mod(k, SAVE_EVERY) == 0 && ~isempty(newResults)
        saveResults(newResults, prevResults, needsBackfill, resultsFile);
        fprintf('  [checkpoint] Saved after %d/%d files (%d new results).\n', k, nFiles, numel(newResults));
    end
    
    waitbar(k/nFiles, hWait, sprintf('Processing %d/%d files (%.1f%%)', k, nFiles, k/nFiles*100));
end
close(hWait);

% --- Final save ----------------------------------------------------------
if ~isempty(newResults)
    saveResults(newResults, prevResults, needsBackfill, resultsFile);
end
fprintf('Done. %d new results from %d files.\n', numel(newResults), nFiles);


%% ========================================================================
%  processFile — Extract similarity metrics from a single alpha_XX.mat file
%  ========================================================================
%  INPUT:
%    file   — struct from dir() with .folder and .name fields
%    M_MAX  — skip files with M > M_MAX
%
%  OUTPUT:
%    result — struct with fields: simID, N, M, alpha, s_intra_memory,
%             s_intra_rand, s_inter_mem, s_inter_rand,
%             std_intra_memory, std_inter_mem
%             Returns NaN fields if file should be skipped.
%
%  ALGORITHM:
%    1. Parse simID, N, M, alpha from the file path and filename.
%    2. Load the .mat file containing:
%       - X_responseActivity: (nTrials × nTimebins) response matrix
%         where nTrials = 100 * (M+1) — 100 trials per class (M memories + 1 random)
%       - Y_memoryClass: (nTrials × 1) class labels
%    3. Sort trials by class, compute full pairwise Pearson similarity.
%    4. Reshape into (M+1) × (M+1) block matrix (avg over 100×100 trial pairs).
%    5. Extract intra/inter memory and random similarity statistics.
% =========================================================================
function result = processFile(file, M_MAX)
    emptyResult = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
        's_intra_memory', NaN, 's_intra_rand', NaN, ...
        's_inter_mem', NaN, 's_inter_rand', NaN, ...
        'std_intra_memory', NaN, 'std_inter_mem', NaN);

    [simID, N, M, alpha] = parseFileInfo(file);

    if M > M_MAX
        result = emptyResult; return;
    end

    % --- Load data and compute similarity matrix -------------------------
    try
        filePath = fullfile(file.folder, file.name);
        S = load(filePath);
        
        % Sort trials by class so the similarity matrix has block structure
        [~, sort_idx] = sort(S.Y_memoryClass);
        X = S.X_responseActivity(sort_idx, :);  % (100*(M+1)) × nTimebins
        
        % Full pairwise Pearson similarity (bottleneck for large M)
        % Suppress the internal waitbar by auto-closing it
        oldCreateFcn = get(0, 'DefaultFigureCreateFcn');
        set(0, 'DefaultFigureVisible', 'off');
        dmat = utils.ComputePearsonSimilarity(X, X, 10, 500);
        set(0, 'DefaultFigureVisible', 'on');
        % Close any leftover waitbar figures
        delete(findall(0, 'Type', 'figure', 'Tag', 'TMWWaitbar'));
        
        % Remove self-similarity (diagonal)
        dmat(logical(eye(size(dmat)))) = NaN;
        
        % Reshape: (100*(M+1))² → (100, M+1, 100, M+1)
        % Then average over trials within each class pair → (M+1) × (M+1)
        dmat = reshape(dmat, 100, M+1, 100, M+1);
        dmat = permute(dmat, [2, 4, 1, 3]);   % (M+1, M+1, 100, 100)
        dmat = nanmean(dmat, [3, 4]);           % (M+1) × (M+1) block avg

        % --- Extract metrics ---------------------------------------------
        s_inter_mem  = triu(dmat(1:M, 1:M), 1);   % between-memory pairs
        s_inter_rnd  = dmat(end, 1:M);              % random-to-memory
        s_intra_all  = diag(dmat);                  % within-class (M+1 values)
        s_intra_rand = s_intra_all(end);            % random class
        s_intra_mem  = s_intra_all(1:end-1);        % M memory classes

        result = struct('simID', simID, ...
            'N', N, 'M', M, 'alpha', alpha, ...
            's_intra_memory', nanmean(s_intra_mem), ...
            's_intra_rand',   s_intra_rand, ...
            's_inter_mem',    nanmean(s_inter_mem(:)), ...
            's_inter_rand',   nanmean(s_inter_rnd(:)), ...
            'std_intra_memory', nanstd(s_intra_mem), ...
            'std_inter_mem',    nanstd(s_inter_mem(:)));
        
    catch err
        warning("Error in %s: %s", fullfile(file.folder, file.name), err.message);
        result = emptyResult;
    end
end

%% ========================================================================
%  parseFileInfo — Extract simID, N, M, alpha from a file struct
% =========================================================================
function [simID, N, M, alpha] = parseFileInfo(file)
    parts = strsplit(fullfile(file.folder, file.name), filesep);
    
    recallsIdx = find(strcmp(parts, 'recallsResponses'), 1, 'last');
    if isempty(recallsIdx) || recallsIdx < 2
        simID = "unknown";
    else
        simID = string(parts{recallsIdx - 1});
    end
    
    N = NaN; M = NaN;
    for i = 1:numel(parts)
        if ~isempty(regexp(parts{i}, '^N\d+$', 'once'))
            N = str2double(regexprep(parts{i}, '\D', ''));
        end
        if ~isempty(regexp(parts{i}, '^\d+memories$', 'once'))
            M = str2double(regexprep(parts{i}, '\D', ''));
        end
    end
    
    alpha = sscanf(file.name, 'alpha_%d.mat') / 100;
end

%% ========================================================================
%  saveResults — Merge new results with previous and write to CSV
% =========================================================================
function saveResults(newResults, prevResults, needsBackfill, resultsFile)
    newTable = struct2table(newResults);
    if iscell(newTable.simID), newTable.simID = string(newTable.simID); end
    
    if needsBackfill && ~isempty(prevResults)
        for r = 1:height(newTable)
            matchIdx = prevResults.simID == newTable.simID(r) & ...
                       prevResults.N == newTable.N(r) & ...
                       prevResults.M == newTable.M(r) & ...
                       abs(prevResults.alpha - newTable.alpha(r)) < 1e-10;
            if any(matchIdx)
                prevResults.std_intra_memory(matchIdx) = newTable.std_intra_memory(r);
                prevResults.std_inter_mem(matchIdx) = newTable.std_inter_mem(r);
            else
                prevResults = [prevResults; newTable(r,:)];
            end
        end
        finalTable = prevResults;
    else
        if ~isempty(prevResults)
            finalTable = [prevResults; newTable];
            finalTable = unique(finalTable, 'rows');
        else
            finalTable = newTable;
        end
    end
    
    finalTable = movevars(finalTable, 'simID', 'Before', 1);
    writetable(finalTable, resultsFile);
end
