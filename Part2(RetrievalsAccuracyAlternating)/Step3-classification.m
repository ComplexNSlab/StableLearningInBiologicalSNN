clear; clc;

alpha_range = 5:5:95;
N = 100; % Network Size

% Get list of all items in the current directory
for N_mems = [3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]

    items = dir(fullfile("Data", "N" + num2str(N) ,num2str(N_mems) + "memories/"));
    folders = items([items.isdir]); % Keep only directories
    folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'
    
    % Define a regex pattern for "alpha_" followed by a number
    pattern = '^alpha_\d+';
    
    matrices = zeros(length(folders), length(alpha_range), N_mems+1, N_mems+1);
    shuffle_mats = zeros(length(folders), N_mems+1, N_mems+1);
    
    % Loop over each folder
    for i = 1:length(folders)
        folderName = string(folders(i).name) + filesep + "recallsResponses";
        filePattern = fullfile(folderName, 'alpha_*'); % Look for files starting with "alpha_"
        % filePattern2 = fullfile(folderName, 'shuffle*');
    
        % Get list of matching files
        matchingFiles = dir(fullfile("Data", "N" + num2str(N) , num2str(N_mems) + "memories", filePattern));

        results = containers.Map;
        roc_curves = cell(length(alpha_range), N_mems+1, 2);
        % Process each matching file
        for j = 1:length(matchingFiles)
            fileName = matchingFiles(j).name;
            
            % Check if filename matches the pattern "alpha_123"
            if ~isempty(regexp(fileName, pattern, 'once'))
                filePath = fullfile(matchingFiles(j).folder, fileName);
                disp(['Found matching file: ', filePath]);
    
                % Load or open the file as needed
                if endsWith(fileName, '.mat')
                    data = load(filePath);
                    X = data.X_responseActivity;
                    Y = data.Y_memoryClass;
                    
                    [confMat, x_roc, y_roc, auc] = classify(X, Y, 0.6);
                    [p, r, f1] = compute_confusion_metrics(confMat);
    
                    alpha = round(str2num(fileName(7:8)));
                    
                    results(string(alpha)) = struct( ...
                    'p', p, ...
                    'r', r, ...
                    'f1', f1, ...
                    'confMat', confMat, ...
                    'auc', auc);

                    roc_curves(alpha == alpha_range, :, 1) = x_roc;
                    roc_curves(alpha == alpha_range, :, 2) = y_roc;
                end
            end
        end
        save(fullfile(folders(i).folder, folders(i).name, "ClassificationResults.mat"), 'results', 'roc_curves');
        fprintf('✅ Results saved successfully to %s\n', folderName + filesep + "ClassificationResults.mat");
    end

end

%% Related Functions 

function [confMat, x_roc, y_roc, auc] = classify(X, Y, split_ratio)
    X(isnan(X)) = 0;

    % Get training and test indices
    N_retrievals = 100; N_rands = 100; N_mems = round(size(X, 1)/N_retrievals)-1;
    idxTrain = []; idxTest = [];
    for i = 1:N_mems
        idx = i:N_mems:round(N_mems*N_retrievals);
        idxTrain = [idxTrain, idx(1:round(split_ratio*N_retrievals))];
        idxTest = [idxTest, idx(round(split_ratio*N_retrievals)+1:end)];
    end
    idxTrain = [idxTrain, (1:round(split_ratio*N_rands)) + N_mems * N_retrievals];
    idxTest = [idxTest, (round(split_ratio*N_rands)+1:N_rands) + N_mems * N_retrievals];
    
    % Split the data
    Xtrain = X(idxTrain, :);
    Ytrain = Y(idxTrain);
    Xtest  = X(idxTest, :);
    Ytest  = Y(idxTest);
    
    % Train    
    template = templateSVM('KernelFunction','rbf','KernelScale','auto','Standardize',true);
    Mdl = fitcecoc(Xtrain, Ytrain, 'Learners', template, 'Coding', 'onevsone');

    % Predict
    [Ypred, scores] = predict(Mdl, Xtest);
    
    labellist = arrayfun(@(x) [num2str(x)], 1:N_mems, 'UniformOutput', false); labellist = [labellist, "random recalls"];
    confMat = confusionmat(labellist(Ytest), labellist(Ypred));

   % computing roc curve and auc for one vs all comparisons
    x_roc = cell(N_mems+1, 1);
    y_roc = cell(N_mems+1, 1);
    auc   = zeros(N_mems+1, 1);
    for i = 1:N_mems  +1
        % Create binary labels: class i vs rest
        binaryYtest = (Ytest == i);
        
        % Use scores(:, i) for class i
        [Xroc, Yroc, ~, AUC] = perfcurve(binaryYtest, scores(:, i), true);
        x_roc{i} = Xroc; y_roc{i} = Yroc; auc(i)= AUC;
    end
end

function [precision, recall, f1Score] = compute_confusion_metrics(confMat)
    % COMPUTE_CONFUSION_METRICS Computes various classification metrics from a confusion matrix.
    % confMat: Confusion matrix (NxN)
    % specialClassIdx: (Optional) Index of a class to ignore in accuracy calculation

    % Overall Accuracy
    overallAccuracy = sum(diag(confMat)) / sum(confMat(:));

    % Per-Class Accuracy
    classAccuracy = diag(confMat) ./ sum(confMat, 2); % Element-wise division
    
    % Precision, Recall, and F1-score
    TP = diag(confMat);           % True Positives
    FP = sum(confMat, 1)' - TP;   % False Positives
    FN = sum(confMat, 2) - TP;    % False Negatives

    precision = TP ./ (TP + FP);
    recall = TP ./ (TP + FN);
    f1Score = 2 * (precision .* recall) ./ (precision + recall);
    f1Score(isnan(f1Score)) = 0;
end
