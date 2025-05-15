clear; clc;

folderPath = "Data\N400\nMems3\May_15_2025_14_12_59\Recalls";
load(fullfile(folderPath, "recalls1.mat"))
whos

%%
% Convert labels to categorical
labels = categorical(groups(:));  % column vector, 400x1

% Choose one feature matrix (e.g., spikeCounts)
X = delays;   % size: 400 x 400

% Optional: standardize features
X = zscore(X, 0, 2);  % normalize each sample (row)


[coeff, score] = pca(X);  % score: 400x400
figure;
gscatter(score(:,1), score(:,2), labels);
xlabel('PC1'); ylabel('PC2'); title('PCA on spikeCounts');

 %%
features = [mean(delays,1)', std(delays,0,1)', ...
            mean(spikeCounts,1)', std(spikeCounts,0,1)'];  % size: 400 x 4

size(features)

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
