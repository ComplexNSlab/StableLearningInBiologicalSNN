%% Parameters
N_retrievals = 100;
N_rands = 100;

%% Partial Memory Recall 

net.sampling = false;
net.STDP = false;
net.saveSimulation = false;

bar = waitbar(0, "Please wait...");
for alpha = 0.05:0.05:0.95
    
    ff_partial = nan(N_mems, N_retrievals, N);
    ff_partial_null = nan(N_rands, N);
    
    bar.Position(1:2) = [500, 500];
    
    % Memory Recalls
    for iter = 1:N_retrievals
        if mod(iter, 10) == 0
            waitbar(iter/(N_retrievals+N_rands), bar, sprintf("Alpha: %.2f\n Partial Recalling: %d/%d", alpha, iter, N_retrievals));
        end
        
        net.PatchNumber = 11;
        for m = 1:N_mems
            stim = stims(m).copy();
            stim.Ncells = ceil(alpha * stims(m).Ncells);
            sub_set = randperm(stims(m).Ncells, stim.Ncells);
            stim.pattern_indices = stim.pattern_indices(sub_set);
            stim.pattern_timings = mod(stim.pattern_timings(sub_set), 100);
            stim.interval = 100;
            stim.start_time = 10;
            stim.ConstructStimCurrent();
            
            net.stims = stim;
            net.run(100);
            
            f = net.firings';
            f(1, :) = mod(f(1, :), 100);
            ff_partial(m, iter, f(2, :)) = f(1, :);
        end
    end
    
    % Random Recalls
    for iter = 1:N_rands
        if mod(iter, 10) == 0
            waitbar((iter+N_retrievals)/(N_retrievals+N_rands), bar, sprintf("Alpha: %.2f\n Random Recall: %d/%d", alpha, iter, N_rands));
        end
        
        stim_rand = Stimulation(net, 100, 2, 30, ceil(alpha * stims(1).Ncells), 5);
        net.stims = stim_rand;
        net.run(100);
        
        f = net.firings';
        f(1, :) = mod(f(1, :), 100);
        ff_partial_null(iter, f(2, :)) = f(1, :);
    end

    f = reshape(ff_partial, [], N);

    trueLabels = repmat(1:N_mems, 1, N_retrievals)';
    trueLabels = [trueLabels; repmat(N_mems+1, size(ff_partial_null, 1), 1)];

    X_responseActivity = [f ; ff_partial_null]; 
    Y_memoryClass = trueLabels;

    % Define the path
    recallsPath = fullfile(net.RecordingDirectory, 'recallsResponses');
    
    % Create the directory if it doesn't exist
    if ~exist(recallsPath, 'dir')
        mkdir(recallsPath);
    end
    
    % Save the data
    save(fullfile(recallsPath, sprintf('alpha_%d.mat', round(100*alpha))), 'X_responseActivity', 'Y_memoryClass', '-mat');
end
close(bar); 

%% Time Shuffling Recalls
% N_retrievals = 100;
% N_rands = 100;
% 
% ff_shuffle = nan(N_mems, N_retrievals, 400); 
% ff_shuffle_null = nan(N_rands, 400);
% 
% bar = waitbar(0, "please wait ...");
% bar.Position(1:2) = [500 500];
% for iter = 1:N_retrievals
%     waitbar((iter-1)/(N_retrievals+N_rands), bar, sprintf("Sampling\n Shuffled Recall  %d/%d\n Random Recall %d/%d", iter, N_retrievals, 0, N_rands));
%     net.PatchNumber = 10 + 1;
%     for m = 1:N_mems
%         stim = stims(m).copy();
%         sub_set = randperm(stims(m).Ncells); 
%         stim.pattern_timings = stim.pattern_timings(sub_set);
%         stim.interval = 100;
%         stim.start_time = 10;
%         stim.pattern_timings = mod(stim.pattern_timings, 100);
%         stim.ConstructStimCurrent();
% 
%         net.stims = [stim];
%         net.run(100);
% 
% 
%         f = net.firings'; f(1, :) = mod(f(1,:), 100);
% 
%         ff_shuffle(m, iter, f(2, :)) = f(1, :);
%     end
% end
% 
% for iter = 1:N_rands
%     waitbar((iter+N_retrievals)/(N_retrievals+N_rands), bar, sprintf("Sampling\n Shuffle Recall  %d/%d\n Random Recall %d/%d", N_retrievals, N_retrievals, iter, N_rands));
% 
%     stim_rand = Stimulation(net, 100, 2, 30, stims(1).Ncells, 10);
%     net.stims = [stim_rand];
%     net.run(100); f = net.firings'; f(1, :) = mod(f(1,:), 100);
%     ff_shuffle_null(iter, f(2, :)) = f(1, :);
% end
% 
% close(bar)
% 
% % Classification Using K-Means
% f = reshape(ff_shuffle, [], 400);
% f(isnan(f)) = 100;
% ff_shuffle_null(isnan(ff_shuffle_null)) = 100;
% 
% trueLabels = repmat(1:N_mems, 1, N_retrievals)';
% trueLabels = [trueLabels; repmat(N_mems+1, size(ff_shuffle_null, 1), 1)];
% 
% [predictedLabels, C] = kmeans([f; ff_shuffle_null], N_mems+1, ...
%     'Replicates', 200, 'MaxIter', 100000, 'Distance', 'sqeuclidean', 'Display', 'final', 'Start', 'plus');
% 
% labellist = arrayfun(@(x) [num2str(x)], 1:N_mems, 'UniformOutput', false); labellist = [labellist, "random recalls"];
% 
% [permpredictedLabels, perm] = matchLabels(trueLabels, predictedLabels);
% confMatrix = confusionmat(labellist(trueLabels), labellist(permpredictedLabels));
% 
% % clearvars -except confMatrix N_mems alpha 
% save(net.RecordingDirectory + filesep + "shuffled.mat", 'confMatrix', '-mat')

%% Function
function [permutedPredLabels, perm] = matchLabels(trueLabels, predictedLabels)
    % This function permutes the predicted labels to best match the true labels.
    
    % Find the unique labels in true and predicted labels
    uniqueTrueLabels = unique(trueLabels);
    uniquePredLabels = unique(predictedLabels);
    
    % Number of unique labels
    numLabels = length(uniqueTrueLabels);
    
    % Create a confusion matrix to compute the cost of assigning each predicted
    % label to each true label.
    costMatrix = confusionmat(trueLabels, predictedLabels);
    
    % for i = 1:numLabels
    %     for j = 1:numLabels
    %         % Negative accuracy as cost (we want to maximize accuracy, so minimize cost)
    %         costMatrix(i, j) = sum((predictedLabels == uniquePredLabels(j)) & (trueLabels ~= uniqueTrueLabels(i)));
    %     end
    % end
    
    % Use the Hungarian algorithm to find the optimal assignment
    assignment = munkres(-costMatrix);  % Returns optimal assignment (permutation)
    [assignedrows,~]=find(assignment);

    % Permute predicted labels
    permutedPredLabels = predictedLabels;
    for i = 1:numLabels
        permutedPredLabels(predictedLabels == uniquePredLabels(i)) = uniqueTrueLabels(assignedrows(i));
    end

    perm = assignedrows;
end

% function [] = MultiClassSVM()
% 
%     rng(1); % for reproducibility
%     N = 100;
%     X = [randn(N,2)*0.75 + ones(N,2); 
%          randn(N,2)*0.5 - ones(N,2); 
%          randn(N,2)*0.6 + [ones(N,1)*-1, ones(N,1)]];
%     Y = [ones(N,1); 
%          ones(N,1)*2; 
%          ones(N,1)*3];
% 
%     % Train multi-class SVM
%     SVMModel = fitcecoc(X, Y);
% 
%     % Predict class labels
%     Ypred = predict(SVMModel, Xtest);
% 
% end