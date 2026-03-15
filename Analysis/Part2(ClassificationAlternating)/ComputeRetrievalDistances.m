clc; clear;
scriptDir = fileparts(mfilename('fullpath'));
if ~isfolder(fullfile(scriptDir, 'Data'))
    scriptDir = fullfile(pwd, 'Analysis', 'Part2(ClassificationAlternating)');
end
rootDir = fullfile(scriptDir, 'Data'); % your data folder
resultsFile = fullfile(scriptDir, 'retrievalDistances.csv');

% Read previous results if they exist
if isfile(resultsFile)
    prevResults = readtable(resultsFile);
else
    prevResults = table();
end

files = dir(fullfile(rootDir, '**', 'alpha_*.mat'));
nFiles = numel(files);

% Prepare result container
results = [];

% Loop through files sequentially
for k = 1:nFiles
    result = processFile_serial(files(k), prevResults);
    
    if ~isempty(result) && ~isnan(result.N)
        results = [results; result];  % accumulate struct array
    end
    
    % if mod(k, 50) == 0 || k == nFiles
    fprintf('Processed %d/%d files\n', k, nFiles);
    % end
end

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


%% Define the processFile_parfeval helper as a subfunction:
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

    if already_done || M > 256
        result = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
            's_intra_memory', NaN, 's_intra_rand', NaN, ...
            's_inter_mem', NaN, 's_inter_rand', NaN);
        return;
    end

    try
        S = load(filePath);
        [~, sort_idx] = sort(S.Y_memoryClass);
        dmat = utils.ComputePearsonSimilarity( ...
            S.X_responseActivity(sort_idx, :), ...
            S.X_responseActivity(sort_idx, :), 10, 500);
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
            's_inter_rand', nanmean(s_inter_rnd(:)));
        
    catch err
        warning("Error in %s: %s", filePath, err.message);
        result = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
            's_intra_memory', NaN, 's_intra_rand', NaN, ...
            's_inter_mem', NaN, 's_inter_rand', NaN);
    end
end
