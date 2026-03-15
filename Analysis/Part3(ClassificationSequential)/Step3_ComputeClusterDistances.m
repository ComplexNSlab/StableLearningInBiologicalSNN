% Step3_ComputeClusterDistances.m
%
% Computes pairwise Euclidean distances between all recall-evoked neural
% representations (using the time-delay feature vector) and organises them
% into intra-cluster and inter-cluster distance distributions. For every
% simulation folder under Data/N<N>/nMems<nMems>/:
%   1. Loads the recall data produced by Step2.
%   2. Groups trials by memory label (m1..mK) and random label (rnd*).
%   3. Builds a full pairwise distance matrix and extracts intra/inter
%      cluster distance vectors.
%   4. Saves ClusterDistances.mat (intra_dists_all, inter_dists_all,
%      uniqueGroups) alongside the recall data.
%
% Also contains helper functions: classify (SVM-based ECOC classifier with
% ROC/AUC), compute_confusion_metrics.
%
% Parameters: N, nMems, alpha (set below)

clear; clc;

nMems = 25;
N = 400;
alpha = 0.1;

rootFolder = sprintf("Data\\N%d\\nMems%d\\", N, nMems);
entries = dir(rootFolder);
entries = entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}));

for i = 1:length(entries)
    retievalFolder = fullfile(entries(i).folder, entries(i).name, "Recalls", "alpha" + num2str(round(100*alpha)));

    if exist(retievalFolder + filesep + "ClusterDistances.mat", 'file')
        fprintf("Already Computed!\n");
        continue;
    end
    
    load(retievalFolder + filesep + "recalls" + num2str(nMems) + ".mat");
    
    %.......... Computing Cluster Distances ....................%
    X = delays;     
    
    % Build labels (if not already complete)
    for iter = nMems+1:2*nMems
        groups((iter-1)*100 + 1: iter*100) = "rnd" + num2str(iter);
    end
    % Enforce desired group order
    orderedLabels = [ ...
        "m" + string(1:nMems), ...
        "rnd" + string(nMems+1 : 2*nMems) ...
    ]';
    labels = categorical(groups(:), orderedLabels, 'Ordinal', true);    
    uniqueGroups = categories(labels);
    nGroups = numel(uniqueGroups);
    
    % Compute pairwise distances
    dMat = squareform(pdist(X, "euclidean"));
    
    % Preallocate cell arrays to store distance values
    intra_dists_all = cell(nGroups, 1);             % intra-cluster distances
    inter_dists_all = cell(nGroups, nGroups);       % inter-cluster distances
    
    % Loop through groups
    for i = 1:nGroups
        idx_i = find(labels == uniqueGroups{i});
    
        % Intra-cluster distances (excluding self-distances)
        D_intra = dMat(idx_i, idx_i);
        intra_dists_all{i} = D_intra(triu(true(length(idx_i)), 1));
    
        % Inter-cluster distances
        for j = i+1:nGroups
            idx_j = find(labels == uniqueGroups{j});
            D_inter = dMat(idx_i, idx_j);  % pairwise distances between groups
            inter_dists_all{i,j} = D_inter(:);
            inter_dists_all{j,i} = D_inter(:);  % symmetric
        end
    end
    
    % You now have:
    % - `intra_dists_all{i}`: all Euclidean distances within group `i`
    % - `inter_dists_all{i,j}`: all distances between group `i` and `j`
    save(retievalFolder + filesep + "ClusterDistances.mat", "uniqueGroups", "intra_dists_all", "inter_dists_all");
    fprintf("Cluster Distances Succesffuly saved!\n");
end

%% Related Functions 

function [confMat, x_roc, y_roc, auc] = classify(X, Y, split_ratio)
    X(isnan(X)) = 0;

    cv = cvpartition(Y, 'HoldOut', 1-split_ratio);  % 20% for testing
    Xtrain = X(training(cv), :);
    Ytrain = Y(training(cv));
    Xtest  = X(test(cv), :);
    Ytest  = Y(test(cv));
        
    % Train    
    template = templateSVM('KernelFunction','rbf','KernelScale','auto','Standardize',true);
    Mdl = fitcecoc(Xtrain, Ytrain, 'Learners', template, 'Coding', 'onevsone');

    % Predict
    [Ypred, scores] = predict(Mdl, Xtest);
    
    % labellist = arrayfun(@(x) [x], 1:length(uniqu0e(Y))-1, 'UniformOutput', false); labellist = [labellist, "random recalls"];
    confMat = confusionmat(Ytest, Ypred);

   % computing roc curve and auc for one vs all comparisons
    x_roc = cell(length(unique(Y)), 1);
    y_roc = cell(length(unique(Y)), 1);
    auc   = zeros(length(unique(Y)), 1);
    for i = 1:length(unique(Y))
        % Create binary labels: class i vs rest
        binaryYtest = (Ytest == "m" + num2str(i));
        
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
