clc; clear;
rootDir = 'Data'; % your data folder
split_ratio = 0.6;
resultsFile = 'classification_metrics_table.csv';

% Read previous results if exists
if isfile(resultsFile)I 
    prevResults = readtable(resultsFile);
else
    
    prevResults = table();
end

files = dir(fullfile(rootDir, '**', 'alpha_*.mat'));
nFiles = numel(files); 

% Set up parallel pool
pool = gcp('nocreate');
if isempty(pool)
    pool = parpool(8); % or parpool('local', desiredNumWorkers)
end

% Helper function (see below for definition)
% function result = processFile_parfeval(file, split_ratio, prevResults)
%     % (copy the extraction and classification code from your parfor above)
%     % ...as a subfunction at the end of the script
% end

% Submit all jobs
futures(nFiles,1) = parallel.FevalFuture;
for k = fliplr(1:nFiles)
    futures(k) = parfeval(pool, @processFile_parfeval, 1, files(k), split_ratio, prevResults);
end

% Collect results as they finish
results = repmat({[]}, nFiles, 1);
nDone = 0;
for k = 1:nFiles
    [idx, out] = fetchNext(futures);
    results{idx} = out;
    nDone = nDone + 1;
    if mod(nDone,50)==0 || nDone==nFiles
        fprintf('Completed %d/%d files\n', nDone, nFiles);
    end
end

% Filter out empty/skipped results
newResults = [results{:}];
mask = arrayfun(@(r) ~isempty(r) && ~isnan(r.N), newResults);
newResults = newResults(mask);

% Convert struct array to table as before
if ~isempty(newResults)
    newTable = struct2table(newResults);
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
    disp('No new files found. Nothing to do.');
end

%% Define the processFile_parfeval helper as a subfunction:
function result = processFile_parfeval(file, split_ratio, prevResults)
    filePath = fullfile(file.folder, file.name);
    parts = strsplit(filePath, filesep);

    % Find simID: parent folder of 'recallsResponses'
    recallsIdx = find(strcmp(parts, 'recallsResponses'), 1, 'last');
    if isempty(recallsIdx) || recallsIdx < 2
        simID = "unknown";
    else
        simID = string(parts{recallsIdx - 1});
    end

    % Find N and M robustly
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

    if already_done || M > 1024
        result = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
            'memory_prec', NaN, 'memory_rec', NaN, 'memory_f1', NaN, ...
            'random_prec', NaN, 'random_rec', NaN, 'random_f1', NaN);
        return;
    end

    % Load data and classify
    S = load(filePath);
    [confMat, x_roc, y_roc, auc] = classify(S.X_responseActivity, S.Y_memoryClass, split_ratio);
    [precision, recall, f1Score] = compute_confusion_metrics(confMat);

    result = struct('simID', simID, ...
        'N', N, ...
        'M', M, ...
        'alpha', alpha, ...
        'memory_prec', mean(precision(1:M)), ...
        'memory_rec', mean(recall(1:M)), ...
        'memory_f1', mean(f1Score(1:M)), ...
        'random_prec', f1Score(end), ...
        'random_rec', f1Score(end), ...
        'random_f1', f1Score(end));
end

%%

% clc; clear;
% rootDir = 'Data'; % your data folder
% split_ratio = 0.6; % for train/test split
% resultsFile = 'classification_metrics_table.csv';
% 
% % Read previous results if exists
% if isfile(resultsFile)
%     prevResults = readtable(resultsFile);
% else
%     prevResults = table();
% end
% 
% files = dir(fullfile(rootDir, '**', 'alpha_*.mat'));
% nFiles = numel(files);
% parfor_progress(nFiles); % <-- add this
% 
% % Preallocate struct array for parfor (size nFiles)
% emptyResult = struct('simID', "", 'N', NaN, 'M', NaN, 'alpha', NaN, ...
%     'memory_prec', NaN, 'memory_rec', NaN, 'memory_f1', NaN, 'random_prec', NaN, 'random_rec', NaN, 'random_f1', NaN);
% newResults(1:nFiles) = emptyResult;  % 1:nFiles, not {}
% 
% % parpool();
% parfor k = 1:nFiles
%     filePath = fullfile(files(k).folder, files(k).name);
%     parts = strsplit(filePath, filesep);
% 
%     % Find simID: parent folder of 'recallsResponses'
%     recallsIdx = find(strcmp(parts, 'recallsResponses'), 1, 'last');
%     if isempty(recallsIdx) || recallsIdx < 2
%         simID = "unknown";
%     else
%         simID = string(parts{recallsIdx - 1});
%     end
% 
%     % Find N and M robustly
%     N = NaN; M = NaN;
%     for i = 1:numel(parts)
%         if ~isempty(regexp(parts{i}, '^N\d+$', 'once'))
%             N = str2double(regexprep(parts{i}, '\D', ''));
%         end
%         if ~isempty(regexp(parts{i}, '^\d+memories$', 'once'))
%             M = str2double(regexprep(parts{i}, '\D', ''));
%         end
%     end
% 
%     % Extract alpha
%     alpha = sscanf(files(k).name, 'alpha_%d.mat') / 100;
% 
%     % Skip if this (simID, N, M, alpha) already in results
%     already_done = ~isempty(prevResults) && ...
%         any(prevResults.simID == simID & prevResults.N == N & ...
%             prevResults.M == M & abs(prevResults.alpha - alpha) < 1e-10);
% 
%     if already_done || M > 100
%         % do nothing, leave entry as emptyResult
%         continue;
%     end
% 
%     % Load data and classify
%     S = load(filePath);
%     [confMat, x_roc, y_roc, auc] = classify(S.X_responseActivity, S.Y_memoryClass, split_ratio);
%     [precision, recall, f1Score] = compute_confusion_metrics(confMat);
% 
%     % Store result in preallocated slot
%     newResults(k) = struct('simID', simID, ...
%         'N', N, ...
%         'M', M, ...
%         'alpha', alpha, ...
%         'memory_prec', mean(precision(1:M)), ...
%         'memory_rec', mean(recall(1:M)), ...
%         'memory_f1', mean(f1Score(1:M)), ...
%         'random_prec', f1Score(end), ...
%         'random_rec', f1Score(end), ...
%         'random_f1', f1Score(end));
% 
%     % For debug you can print, but parfor may jumble output
%     % fprintf('Processed %d/%d files :  N = %d, M = %d, alpha = %d\n', k, nFiles, N, M, round(100*alpha));
%     parfor_progress; 
% end
% parfor_progress(0);
% 
% % Remove entries where N is NaN (unprocessed/skipped)
% mask = ~isnan([newResults.N]);
% newResults = newResults(mask);
% 
% % Convert struct array to table
% if ~isempty(newResults)
%     newTable = struct2table(newResults);
% 
%     % If simID is string, fix table column type to string
%     if iscell(newTable.simID)
%         newTable.simID = string(newTable.simID);
%     end
% 
%     if ~isempty(prevResults)
%         % Remove any duplicate rows just in case
%         finalTable = [prevResults; newTable];
%         finalTable = unique(finalTable, 'rows'); % keep only unique rows
%     else
%         finalTable = newTable;
%     end
% 
%     % Move simID to first column if needed
%     finalTable = movevars(finalTable, 'simID', 'Before', 1);
% 
%     % Save table
%     writetable(finalTable, resultsFile);
%     disp('New results appended and saved.');
% else
%     disp('No new files found. Nothing to do.');
% end

%% --- Classification Functions (include at end of script) ---

function [confMat, x_roc, y_roc, auc] = classify(X, Y, split_ratio)
    X(isnan(X)) = 0;
    N_retrievals = 100; N_rands = 100; N_mems = round(size(X, 1)/N_retrievals)-1;
    idxTrain = []; idxTest = [];
    for i = 1:N_mems
        idx = i:N_mems:round(N_mems*N_retrievals);
        idxTrain = [idxTrain, idx(1:round(split_ratio*N_retrievals))];
        idxTest = [idxTest, idx(round(split_ratio*N_retrievals)+1:end)];
    end
    idxTrain = [idxTrain, (1:round(split_ratio*N_rands)) + N_mems * N_retrievals];
    idxTest = [idxTest, (round(split_ratio*N_rands)+1:N_rands) + N_mems * N_retrievals];

    Xtrain = X(idxTrain, :);
    Ytrain = Y(idxTrain);
    Xtest  = X(idxTest, :);
    Ytest  = Y(idxTest);

    template = templateSVM('KernelFunction','linear', 'KernelScale','auto','Standardize',true);
    Mdl = fitcecoc(Xtrain, Ytrain, 'Learners', template, 'Coding', 'onevsall');

    [Ypred, scores] = predict(Mdl, Xtest);

    labellist = arrayfun(@(x) [num2str(x)], 1:N_mems, 'UniformOutput', false); labellist = [labellist, "random recalls"];
    confMat = confusionmat(labellist(Ytest), labellist(Ypred));

    x_roc = cell(N_mems+1, 1);
    y_roc = cell(N_mems+1, 1);
    auc   = zeros(N_mems+1, 1);
    for i = 1:N_mems  +1
        binaryYtest = (Ytest == i);
        [Xroc, Yroc, ~, AUC] = perfcurve(binaryYtest, scores(:, i), true);
        x_roc{i} = Xroc; y_roc{i} = Yroc; auc(i)= AUC;
    end
end

function [precision, recall, f1Score] = compute_confusion_metrics(confMat)
    TP = diag(confMat);
    FP = sum(confMat, 1)' - TP;
    FN = sum(confMat, 2) - TP;
    precision = TP ./ (TP + FP);
    recall = TP ./ (TP + FN);
    f1Score = 2 * (precision .* recall) ./ (precision + recall);
    f1Score(isnan(f1Score)) = 0;
end
