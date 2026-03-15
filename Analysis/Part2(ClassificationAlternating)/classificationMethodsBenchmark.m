% Load your data
load('C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part2(ClassificationAlternating)\Data\N100\100memories\Jul_11_2025_02_40_03\recallsResponses\alpha_50.mat')

X = X_responseActivity;
Y = Y_memoryClass;
X(isnan(X)) = 0;

% Prepare indices for train/test split
N_retrievals = 100; N_rands = 100; N_mems = round(size(X, 1)/N_retrievals)-1; split_ratio = 0.8;
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

%% Random Forest (Ensemble)
fprintf('Training Random Forest...\n');
tic
t = templateTree('MaxNumSplits', 100);
Mdl_rf = fitcensemble(Xtrain, Ytrain, 'Method', 'Bag', ...
    'NumLearningCycles', 50, 'Learners', t, 'ClassNames', unique(Y));
rf_train_time = toc;

% Predict on train/test sets
Ypred_rf_train = predict(Mdl_rf, Xtrain);
Ypred_rf_test = predict(Mdl_rf, Xtest);
acc_rf_train = mean(Ypred_rf_train == Ytrain);
acc_rf_test = mean(Ypred_rf_test == Ytest);

fprintf('Random Forest train accuracy: %.2f%%\n', acc_rf_train*100);
fprintf('Random Forest test  accuracy: %.2f%%\n', acc_rf_test*100);
fprintf('Random Forest training took %.1f seconds.\n', rf_train_time);

% Per-group accuracy calculation
% Assumption: memory classes = 1 to M, non-memory class = M+1
M = max(Y) - 1; % If non-memory is the last label
mem_idx = Ytest <= M;
nonmem_idx = Ytest == (M+1);

acc_memory = mean(Ypred_rf_test(mem_idx) == Ytest(mem_idx));
acc_nonmemory = mean(Ypred_rf_test(nonmem_idx) == Ytest(nonmem_idx));

fprintf('Random Forest test accuracy (memory classes): %.2f%%\n', acc_memory*100);
fprintf('Random Forest test accuracy (non-memory class): %.2f%%\n', acc_nonmemory*100);

% Confusion matrix (optional)
% figure; confusionchart(Ytest, Ypred_rf_test); title('Random Forest Confusion Matrix (Test Set)');

%% Shallow Neural Net (GPU possible)
% parallel.gpu.enableCUDAForwardCompatibility(true);

% Build a simple feedforward net (fullyConnectedLayer)
inputSize = size(Xtrain,2);

numClasses = numel(unique(Ytrain));
layers = [
    featureInputLayer(inputSize, 'Normalization', 'zscore')
    fullyConnectedLayer(16)              % hidden layer size
    reluLayer
    % fullyConnectedLayer(32)              % hidden layer size
    % reluLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

% Training options (with plots, verbose, and more epochs if you want)
options = trainingOptions('adam', ...
    'MaxEpochs', 60, ...                % Set higher for more curve
    'MiniBatchSize', 64, ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...   % <-- This opens live learning curve!
    'Verbose', true, ...
    'VerboseFrequency', 1, ...
    'ValidationData', {Xtest, categorical(Ytest)}, ...
    'ValidationFrequency', 50, ...
    'ExecutionEnvironment', 'cpu', ...
    'InitialLearnRate', 0.001);

% Train the network
fprintf('Training neural net (with progress plot)...\n'); 
net = trainNetwork(Xtrain, categorical(Ytrain), layers, options);

% Predict and evaluate
Ypred_train = classify(net, Xtrain);
Ypred_test = classify(net, Xtest);
acc_train = mean(Ypred_train == Ytrain);
acc_test = mean(Ypred_test == Ytest);

fprintf('Neural Net (trainNetwork) train accuracy: %.2f%%\n', acc_train*100);
fprintf('Neural Net (trainNetwork) test  accuracy: %.2f%%\n', acc_test*100);