% ComputeRetrievalDistances.m
% =========================================================================
% Computes pairwise Pearson similarity metrics from retrieval response data
% and appends results to 'retrievalDistances.csv'.
%
% For each simulation file (alpha_XX.mat), the script:
%   1. Loads recall responses (X_responseActivity) and class labels
%      (Y_memoryClass) — 100 trials per class (M memories + 1 random).
%   2. Computes the full pairwise Pearson similarity matrix.
%   3. Reshapes into a (M+1)x(M+1) block-averaged similarity matrix.
%   4. Extracts per-simulation statistics:
%        - s_intra_memory:   mean within-memory similarity (avg of M diagonal blocks)
%        - s_intra_rand:     within-random-class similarity (last diagonal block)
%        - s_inter_mem:      mean between-memory similarity (upper triangle of MxM)
%        - s_inter_rand:     mean random-to-memory similarity
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
% INCREMENTAL:
%   Previously computed rows (matched by simID, N, M, alpha) are skipped.
%   Only new files are processed and appended to the CSV.
%
% NOTE:
%   Adjust the M threshold in processFile_serial (currently M > 5) to
%   control which simulations are processed.
% =========================================================================

clc; clear;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfolder(fullfile(scriptDir, 'Data'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
rootDir = fullfile(scriptDir, 'Data'); % your data folder
resultsFile = fullfile(scriptDir, 'retrievalDistances.csv');

% Read previous results if they exist
if isfile(resultsFile)
    prevResults = readtable(resultsFile, 'TextType', 'string');
else
    prevResults = table();
end

files = dir(fullfile(rootDir, '**', 'alpha_*.mat'));
nFiles = numel(files);

% Classify files by M
M_THRESHOLD = 100;

fileM = NaN(nFiles, 1);
for k = 1:nFiles
    parts_k = strsplit(fullfile(files(k).folder, files(k).name), filesep);
    for i = 1:numel(parts_k)
        if ~isempty(regexp(parts_k{i}, '^\d+memories$', 'once'))
            fileM(k) = str2double(regexprep(parts_k{i}, '\D', ''));
            break;
        end
    end
end

idxSmall = find(fileM <= M_THRESHOLD | isnan(fileM));
idxLarge = find(fileM > M_THRESHOLD);

% Pre-allocate cell array
resultCell = cell(nFiles, 1);

% --- Process small-M files sequentially ---
if ~isempty(idxSmall)
    nSmall = numel(idxSmall);
    smallFiles = files(idxSmall);
    smallResults = cell(nSmall, 1);
    for k = 1:nSmall
        smallResults{k} = processFile_serial(smallFiles(k), prevResults);
        if mod(k, 5) == 0 || k == x
            fprintf('[small-M] Processed %d/%d files (%.1f%%)\n', k, nSmall, k/nSmall*100);
        end
    end
    resultCell(idxSmall) = smallResults;
end

% --- Process large-M files with limited workers to avoid OOM ---
if ~isempty(idxLarge)
    nLarge = numel(idxLarge);
    fprintf('Processing %d large-M files (M > %d) sequentially...\n', ...
        nLarge, M_THRESHOLD);
    largeFiles = files(idxLarge);
    largeResults = cell(nLarge, 1);
    for k = 1:nLarge
        largeResults{k} = processFile_serial(largeFiles(k), prevResults);
        if mod(k, 5) == 0 || k == nLarge
            fprintf('[large-M] Processed %d/%d files (%.1f%%)\n', k, nLarge, k/nLarge*100);
        end
    end
    resultCell(idxLarge) = largeResults;
end

% Collect valid results
results = [];
for k = 1:nFiles
    r = resultCell{k};
    if ~isempty(r) && ~isnan(r.N)
        results = [results; r];
    end
end
fprintf('Done. %d new results out of %d total files.\n', numel(results), nFiles);

% Convert struct array to table and merge with previous
if ~isempty(results)
    newTable = struct2table(results);
    
    if iscell(newTable.simID)
        newTable.simID = string(newTable.simID);
    end
    
    if ~isempty(prevResults)
        finalTable = [prevResults; newTable];
        finalTable = unique(finalTable, 'rows');
    else
        finalTable = newTable;
    end
    
    finalTable = movevars(finalTable, 'simID', 'Before', 1);
    writetable(finalTable, resultsFile);
    disp('New results appended and saved.');
else
    disp('No new files found or processed.');
end


%% processFile_serial — Extract similarity metrics from one alpha_XX.mat
%  INPUT:
%    file        — struct from dir() with .folder and .name fields
%    prevResults — table of previously computed results (for skip logic)
%
%  OUTPUT:
%    result — struct with fields: simID, N, M, alpha,
%             s_intra_memory, s_intra_rand, s_inter_mem, s_inter_rand,
%             std_intra_memory, std_inter_mem
%             Returns NaN-filled struct if file is skipped or errors.
%
%  ALGORITHM:
%    1. Parse simID, N, M, alpha from the file path / filename.
%    2. Skip if already in prevResults or M exceeds threshold.
%    3. Load .mat → sort trials by class → Pearson similarity matrix.
%    4. Reshape to (M+1)x(M+1) block matrix (mean over 100x100 trial pairs).
%    5. Diagonal blocks → intra-class similarity.
%       Upper triangle → inter-class similarity.
%       Last row/col → random class comparisons.
function result = processFile_serial(file, prevResults)
    filePath = fullfile(file.folder, file.name);
    parts = strsplit(filePath, filesep);

    % Get simID (folder before recallsResponses)
    recallsIdx = find(strcmp(parts, 'recallsResponses'), 1, 'last');
    if isempty(recallsIdx) || recallsIdx < 2
        simID = "unknown";
    else
        simID = string(parts{recallsIdx - 1});
    end

    % Extract N and M
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

    already_done = ~isempty(prevResults) && ...
        any(prevResults.simID == simID & prevResults.N == N & ...
            prevResults.M == M & abs(prevResults.alpha - alpha) < 1e-10);

    if already_done
        result = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
            's_intra_memory', NaN, 's_intra_rand', NaN, ...
            's_inter_mem', NaN, 's_inter_rand', NaN, ...
            'std_intra_memory', NaN, 'std_inter_mem', NaN);
        return;
    end

    try
        S = load(filePath);
        [~, sort_idx] = sort(S.Y_memoryClass);
        dmat = utils.ComputePearsonSimilarity( ...
            S.X_responseActivity(sort_idx, :), ...
            S.X_responseActivity(sort_idx, :), 10, 500, false);
        dmat(logical(eye(size(dmat)))) = NaN;
        dmat = reshape(dmat, 100, M+1, 100, M+1);
        dmat = permute(dmat, [2, 4, 1, 3]);
        dmat = nanmean(dmat, [3, 4]);

        s_inter_mem = triu(dmat(1:M, 1:M), 1);
        s_inter_rnd = dmat(end, 1:M);
        s_intra_mem = diag(dmat); 
        s_intra_rand = s_intra_mem(end); 
        s_intra_mem = s_intra_mem(1:end-1);

        result = struct('simID', simID, ...
            'N', N, ...
            'M', M, ...
            'alpha', alpha, ...
            's_intra_memory', nanmean(s_intra_mem), ...
            's_intra_rand', s_intra_rand, ...
            's_inter_mem', nanmean(s_inter_mem(:)), ...
            's_inter_rand', nanmean(s_inter_rnd(:)), ...
            'std_intra_memory', nanstd(s_intra_mem), ...
            'std_inter_mem', nanstd(s_inter_mem(:)));
        
    catch err
        warning("Error in %s: %s", filePath, err.message);
        result = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
            's_intra_memory', NaN, 's_intra_rand', NaN, ...
            's_inter_mem', NaN, 's_inter_rand', NaN, ...
            'std_intra_memory', NaN, 'std_inter_mem', NaN);
    end
end

