clear; clc;

load("Data\N400\nMems50\May_20_2025_12_09_39\Recalls\recalls50.mat")
whos

for iter = 51:100
    groups((iter-1)*100 + 1: iter*100) = "rnd" + num2str(iter);
end
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

dMat = squareform(pdist(delays, "euclidean"));
figure; 
imagesc(dMat);
colorbar();
%%
% Prepare data
X = delays;                          % 900 x 400 matrix
labels = categorical(groups(:));     % convert 1x900 string to 900x1 categorical
uniqueGroups = categories(labels);
nGroups = numel(uniqueGroups);

% Initialize
intra_dists = zeros(nGroups, 1);
inter_dists = zeros(nGroups, nGroups);
counts = zeros(nGroups, nGroups);

% Compute distances
for i = 1:nGroups
    idx_i = find(labels == uniqueGroups{i});
    Xi = X(idx_i, :);

    % Intra-cluster distance
    D_intra = pdist2(Xi, Xi, 'euclidean');
    mask = ~eye(length(idx_i));  % remove self-distances
    intra_dists(i) = mean(D_intra(mask));

    % Inter-cluster distances
    for j = i+1:nGroups
        idx_j = find(labels == uniqueGroups{j});
        Xj = X(idx_j, :);
        D_inter = pdist2(Xi, Xj, 'euclidean');
        inter_dists(i,j) = mean(D_inter(:));
        inter_dists(j,i) = inter_dists(i,j);  % symmetry
    end
end


% 1. Get unique group labels
groupNames = unique(groups(:));  % cell/array of strings like "m4", "rnd13", etc.

% 2. Extract numeric values from the end of each string
numVals = zeros(numel(groupNames), 1);
for i = 1:numel(groupNames)
    str = groupNames(i);
    digits = regexp(str, '\d+$', 'match');  % extract trailing digits
    numVals(i) = str2double(digits{1});
end

% 3. Sort group names based on extracted numbers
[~, sortIdx] = sort(numVals);
sortedGroups = groupNames(sortIdx);

labels = categorical(groups(:), sortedGroups);  % enforce custom order

figure;
heatmap(sortedGroups, sortedGroups, inter_dists(sortIdx, sortIdx));
title('Inter-cluster L2 Distances');



clearvars bar
figure; 
bar(sortedGroups, intra_dists(sortIdx));
ylabel('Average Intra-cluster L2 Distance');
title('Intra-cluster Distances');

%% ***************************************************************************************** %%
% --- Collect all intra-cluster distances per sample ---
allIntraVals = [];      % distances
allIntraGroups = [];    % matching group labels

for i = 1:nGroups
    idx_i = find(labels == sortedGroups(i));
    Xi = X(idx_i, :);
    D_intra = pdist2(Xi, Xi, 'euclidean');
    
    % Mask upper triangle only (exclude diag and duplicates)
    mask = triu(true(size(D_intra)), 1);
    dists = D_intra(mask);
    
    % Append
    allIntraVals = [allIntraVals; dists(:)];
    allIntraGroups = [allIntraGroups; repmat(sortedGroups(i), numel(dists), 1)];
end

% Convert to categorical with proper order
allIntraGroups = categorical(allIntraGroups, sortedGroups);

% --- Plot with violinplot and sample points ---
figure('Color', 'w', 'Position', [100, 100, 800, 500]);
violinplot(allIntraGroups, allIntraVals, EdgeColor='none');

hold on;
swarmchart(allIntraGroups, allIntraVals, 1.4, 'k', 'filled', ...
    'XJitter', 'density', 'XJitterWidth', 0.8, 'MarkerFaceAlpha', 0.4);

ylabel('Pairwise Intra-cluster L2 Distance');
title('Intra-cluster Distances per Group');
set(gca, 'TickLabelInterpreter', 'none');  % show string labels as-is

%%

% Prepare group names for x/y labels
groupLabels = string(sortedGroups);

% Sort inter-cluster distances
sortedInterDists = inter_dists(sortIdx, sortIdx);

% Create figure
figure('Color','w', 'Position', [100, 100, 800, 700]);
h = heatmap(groupLabels, groupLabels, sortedInterDists);

% Display values
h.CellLabelFormat = '%.2f';

% Color scheme
colormap("parula")  % or 'hot', 'turbo', 'viridis', etc.
colorbar;

% Axis and title
h.Title = 'Inter-cluster L2 Distances';
h.XLabel = 'Group';
h.YLabel = 'Group';

% Style tweaks
h.FontSize = 12;
h.GridVisible = 'off';
% h.TickLabelInterpreter = 'none';  % ensures literal group name display
%%
% Normalize by row-wise intra distances
normInter = sortedInterDists ./ intra_dists(sortIdx);  % element-wise row divide
normInter(eye(nGroups) == 1) = NaN;  % ignore diagonal

figure;
% Then plot normInter instead of sortedInterDists
heatmap(groupLabels, groupLabels, normInter, 'CellLabelFormat', '%.2f');
%%

% Assume:
% sortedGroups: the ordered group names (already sorted as in your heatmap)
% inter_dists: nGroups x nGroups symmetric matrix

nGroups = numel(sortedGroups);

% Split into two index groups
before_idx = find(startsWith(sortedGroups, "m"));     % e.g., 1–25
after_idx  = find(startsWith(sortedGroups, "rnd"));   % e.g., 26–50

% Extract submatrices
inter_before = inter_dists(before_idx, before_idx);
inter_after  = inter_dists(after_idx, after_idx);
inter_cross  = inter_dists(before_idx, after_idx);  % between before and after

% Get upper triangle only to avoid repeats (and NaN diagonal)
mask_upper = @(M) M(triu(true(size(M)), 1));

vals_before = mask_upper(inter_before);
vals_after  = mask_upper(inter_after);
vals_cross  = inter_cross(:);  % all pairs between before/after

fprintf('Mean (Before): %.2f\n', mean(vals_before));
fprintf('Mean (After):  %.2f\n', mean(vals_after));
fprintf('Mean (Cross):  %.2f\n', mean(vals_cross));

[p1, ~] = ranksum(vals_before, vals_after);
[p2, ~] = ranksum(vals_before, vals_cross);
[p3, ~] = ranksum(vals_after, vals_cross);
fprintf('p(Before vs After): %.3g\n', p1);
fprintf('p(Before vs Cross): %.3g\n', p2);
fprintf('p(After vs Cross):  %.3g\n', p3);

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
