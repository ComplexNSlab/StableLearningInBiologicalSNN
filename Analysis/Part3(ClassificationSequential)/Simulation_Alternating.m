% Simulation_Alternating.m
%
% End-to-end exploratory script for alternating-stimulus sequential
% learning in a heterogeneous Izhikevich spiking network.  The script:
%   1. Initialises an IzhikevichNetwork with STDP enabled.
%   2. Trains multiple memories sequentially (alternating stimuli).
%   3. Extracts spike-order, spike-count, time-delay, and assembly
%      representations for every trial.
%   4. Plots similarity matrices (Spearman / Pearson / Hamming) across
%      representations.
%   5. Tracks participation rate of excitatory/inhibitory populations.
%   6. Computes the pairwise inter-memory similarity over training time
%      for five representation types and plots their evolution.
%   7. Applies PCA to the delay representation and visualises learning
%      trajectories in a 3-D principal-component space.
%
% Parameters: N_mems (number of memories), network hyper-parameters
%             (set in the initialisation block).

clear;clc;

%% Initializing the Network properties
clc; clear;

clear; clc;
baseFolder = "." + filesep + "Data_Alternate" + filesep;
net = IzhikevichNetwork(400, 'heterogeneity', true, 'g_ee', 0.5, 'g_ei', 2, 'g_ie', 2, 'ExtoExDegree', 20, 'InhtoExDegree', 5, 'ExtoInhDegree', 5, 'baseFolder', baseFolder);
net.STDP = true;
net.noise = false;

net.sampling_rate = 5000;
net.stimulation = true;
%% Simulating to learn N memories sequentially

N_mems = 3;
stims = [];
for i = 1:N_mems
    stim = Stimulation(net, 100 * N_mems, 2, 30, 50, 5 + (i-1) * 100);
    stims = [stims, stim];
end
for i = 1:N_mems
    net.run(100000);
end

%% 
[orders_together, orders_separate, spike_counts, delays] = computeOrders(net);
save(net.RecordingDirectory +  filesep +  "MemoryRepresentations", "orders_together", "orders_separate", "spike_counts", "delays");
%%
% this new order help you to separate trials by their memory for matrix
new_order = [];
for i = 1:N_mems
    new_order = [new_order, i:N_mems:N_mems*1000];
end
%% Simmilarity matrix of order vector 

figure;
imagesc(1-squareform(pdist(orders_separate(new_order, 1:net.Ne), "spearman")));
title("First-Spike Order Separate Simmilarity Matrix");
cb = colorbar(); cb.Label.String = "Spearman"; 
set(gca, 'ydir', 'normal');

figure;
imagesc(1-squareform(pdist(orders_together(new_order, 1:net.Ne), "spearman")));
title("First-Spike Order Together Simmilarity Matrix");
cb = colorbar(); cb.Label.String = "Spearman";
set(gca, 'ydir', 'normal');
%% Simmilarity matrix of spike counts and time delays representations 

figure;
imagesc(1-squareform(pdist(delays(new_order, 1:net.Ne), "correlation")));
title("Latency Simmilarity Matrix");
cb = colorbar(); cb.Label.String = "Pearson";
set(gca, 'ydir', 'normal');

figure;
imagesc(1-squareform(pdist(spike_counts(new_order, 1:net.Ne), "spearman")));
title("Spike Counts Simmilarity Matrix");
cb = colorbar(); cb.Label.String = "Pearson";
set(gca, 'ydir', 'normal');

%% Assembly Activities Representation


assemblies = spike_counts ~= 0;

figure; imagesc(~assemblies(new_order, :)'); colormap('hot');
xlabel("Tirals", 'FontWeight','bold'); ylabel("Cell index", 'FontWeight','bold'); title("Assembly Representation of Activity");
set(gca, 'ydir', 'normal', 'FontSize', 15);
%% Similarity matrix of assembly representation excluding inhibitory cells (because of the bias they cause)


mat = 1- squareform(pdist(1*assemblies(new_order, 1:net.Ne), "Hamming"));
figure; imagesc(mat); cb = colorbar(); cb.Label.String = "Hamming";
xlabel("Trials", FontWeight="bold"); ylabel("Trials", FontWeight="bold");
title("Assembly Similarity Distance")
set(gca, 'ydir', 'normal', 'FontSize', 15);


%% Participation Rate of the Population for different memories
figure; hold on;
flag = 'on';
for selected_mem = 1:N_mems
    if selected_mem > 1
        flag = 'off';
    end
    plot(100*sum(assemblies(selected_mem:N_mems:end, 1:net.Ne), 2)/net.Ne, DisplayName="Ex", color='b', HandleVisibility=flag);
    plot(100*sum(assemblies(selected_mem:N_mems:end, net.Ne+1:end), 2)/net.Ni, DisplayName="Inh", Color='r', HandleVisibility=flag);
    plot(100*sum(assemblies(selected_mem:N_mems:end, :), 2)/net.N, DisplayName="Both", color='k', HandleVisibility=flag);
end
legend(); xlabel("Trials", 'FontWeight', 'bold'); ylabel("Participation Rate", 'FontWeight', 'bold');
title("Participation of the Population ")
set(gca, 'FontName', 'arial', 'fontsize', 15)
%% Computing Separation of Memories Evolution in Time
inter_dist = zeros(5, N_mems*(N_mems-1)/2, 1000);

counter = 1;
for representation = ["spike counts",  "latency", "spike orders together", "spike orders separate", "assembly"]
     if representation.lower == "spike counts"
        data = spike_counts;
        dist_measure = 'correlation';
    elseif representation.lower == "latency"
        data = delays;
        dist_measure = 'correlation';
    elseif representation.lower == "spike orders together"
        data = orders_together;
        dist_measure = 'spearman';
    elseif representation.lower == "spike orders separate"
        data = orders_separate;
        dist_measure = 'spearman';
     elseif representation.lower == "assembly"
        data = assemblies;
        dist_measure = "hamming";
     end

    mat = 1-squareform(pdist(1*data, dist_measure));
    
    for i = 1:1000
        mask = (i-1)*N_mems+1:i*N_mems;
        submat = mat(mask, mask);
    
        values = submat(triu(true(size(submat)), 1));
    
        inter_dist(counter, :, i) = values;
    end
    counter = counter + 1;
end
%% Plotting the result of previous block
figure; hold on;
lw = 2;
plot(mean(squeeze(inter_dist(1, :, :)), 1), DisplayName= "spike counts", LineWidth= lw);
plot(mean(squeeze(inter_dist(2, :, :)), 1), DisplayName= "latency", LineWidth= lw);
plot(mean(squeeze(inter_dist(3, :, :)), 1), DisplayName= "orders (together)", LineWidth= lw);
plot(mean(squeeze(inter_dist(4, :, :)), 1), DisplayName= "orders (separate)", LineWidth= lw);
plot(mean(squeeze(inter_dist(5, :, :)), 1), DisplayName= "assembly", LineWidth= lw);

xlabel("Trials"); ylabel("Similarity Index");
title("Pairwise Similarity of Memories Representations during Learning")
legend(Location='best');
set(gca, 'FontName', 'arial', 'FontSize', 15, 'FontWeight', 'bold')
%% Computnig the evolution trajectories pca space
data = delays;
[coeff,score,latent,tsquared,explained,mu] = pca(delays(new_order, :));
%% Visualizing the PCA trajectory of the representation
cmap = jet(1000); 
cvals = repmat(1:1000, 1, N_mems);

figure;
scatter3(score(:, 4), score(:, 2), score(:, 3), [], cvals, 'filled');
colormap(cmap); 
cb = colorbar(); cb.Label.String = "Trial";
xlabel("PC1"); ylabel("PC2"); zlabel("PC3");
title("Trajectory of memories representation during alternating learning")
set(gca, 'FontName', 'Arial', 'FontSize', 15, 'FontWeight', 'bold'); 
%% Retrieving stimulations from patches
stims = [];
for i = 1:N_mems
    tempnet = net.getNetwork(i);
    stims = [stims, tempnet.stims(1)];
end

%% Recalling the memories partially

alpha = 0.5; % The percentage of those 50 to call for memory retrieval 
N_retrievals = 20;
N_rands = 100;

load(net.RecordingDirectory + filesep + "Patch" + num2str(N_mems) + ".mat", 'obj');

net = obj;
net.sampling = false;
net.STDP = false;
ff_partial = nan(N_mems, N_retrievals, 400);
ff_partial_null = nan(N_rands, 400);

net.saveSimulation = false;

bar = waitbar(0, "please wait ...");
bar.Position(1:2) = [500 500];
for iter = 1:N_retrievals
    waitbar((iter-1)/(N_retrievals+N_rands), bar, sprintf("Sampling\n Partial Recall  %d/%d\n Random Recall %d/%d", iter, N_retrievals, 0, N_rands));
    net.PatchNumber = 10 + 1;
    for m = 1:N_mems
        stim = stims(m).copy();
        stim.Ncells = ceil(alpha*stims(m).Ncells);
        sub_set = randperm(stims(m).Ncells); sub_set = sub_set(1:stim.Ncells);
        stim.pattern_indices = stim.pattern_indices(sub_set);
        stim.pattern_timings = stim.pattern_timings(sub_set);
        stim.interval = 100;
        stim.start_time = 10;
        stim.pattern_timings = mod(stim.pattern_timings, 100);
        stim.ConstructStimCurrent();
    
        net.stims = [stim];
        net.run(100);
        
        % load(net.RecordingFile, ['data' num2str(net.PatchNumber-1)]);
        % eval(['f = data' num2str(net.PatchNumber-1) '.firings; f(1,:) = mod(f(1, :), 100);'])
        f = net.firings'; f(1, :) = mod(f(1,:), 100);
        
        ff_partial(m, iter, f(2, :)) = f(1, :);
    end
end

for iter = 1:N_rands
    waitbar((iter+N_retrievals)/(N_retrievals+N_rands), bar, sprintf("Sampling\n Partial Recall  %d/%d\n Random Recall %d/%d", N_retrievals, N_retrievals, iter, N_rands));

    stim_rand = Stimulation(net, 100, 2, 30, ceil(alpha*stims(1).Ncells), 10);
    net.stims = [stim_rand];
    net.run(100); f = net.firings'; f(1, :) = mod(f(1,:), 100);
    ff_partial_null(iter, f(2, :)) = f(1, :);
end

% for m = 1:N_mems
%     delete(net.RecordingDirectory + filesep + "Patch" + num2str(10+m) + ".mat");
% end
close(bar)
% save(net.RecordingDirectory + filesep + num2str(alpha*100) + "PercentPartialRecall.mat", 'ff_partial', "net", "N_retrievals", "alpha", '-mat')
%%  Let's Retrieve them by shuffling spike times!
N_retrievals = 100;
N_rands = 100;

load(net.RecordingDirectory + filesep + "Patch" + num2str(N_mems) + ".mat", 'obj');
net = obj;
net.sampling = false;
net.STDP = false;
net.saveSimulation = false;

ff_shuffle = nan(N_mems, N_retrievals, 400); 
ff_shuffle_null = nan(N_rands, 400);

bar = waitbar(0, "please wait ...");
bar.Position(1:2) = [500 500];
for iter = 1:N_retrievals
    waitbar((iter-1)/(N_retrievals+N_rands), bar, sprintf("Sampling\n Shuffled Recall  %d/%d\n Random Recall %d/%d", iter, N_retrievals, 0, N_rands));
    net.PatchNumber = 10 + 1;
    for m = 1:N_mems
        stim = stims(m).copy();
        sub_set = randperm(stims(m).Ncells); 
        stim.pattern_timings = stim.pattern_timings(sub_set);
        stim.interval = 100;
        stim.start_time = 10;
        stim.pattern_timings = mod(stim.pattern_timings, 100);
        stim.ConstructStimCurrent();
    
        net.stims = [stim];
        net.run(100);
        
        % load(net.RecordingFile, ['data' num2str(net.PatchNumber-1)]);
        % eval(['f = data' num2str(net.PatchNumber-1) '.firings; f(1,:) = mod(f(1, :), 100);'])
        f = net.firings'; f(1, :) = mod(f(1,:), 100);

        ff_shuffle(m, iter, f(2, :)) = f(1, :);
    end
end

for iter = 1:N_rands
    waitbar((iter+N_retrievals)/(N_retrievals+N_rands), bar, sprintf("Sampling\n Shuffle Recall  %d/%d\n Random Recall %d/%d", N_retrievals, N_retrievals, iter, N_rands));

    stim_rand = Stimulation(net, 100, 2, 30, stims(1).Ncells, 10);
    net.stims = [stim_rand];
    net.run(100); f = net.firings'; f(1, :) = mod(f(1,:), 100);
    ff_shuffle_null(iter, f(2, :)) = f(1, :);
end

% for m = 1:N_mems
%     delete(net.RecordingDirectory + filesep + "Patch" + num2str(10+m) + ".mat");
% end
close(bar)
% save(net.RecordingDirectory + filesep + "ShuffleRecall", 'ff_shuffle', "net", "N_retrievals", '-mat')

%% Classification of Responses by Kmeans

% f = ff_shuffle;
% ff_null = ff_shuffle_null;
f = ff_partial;
ff_null = ff_partial_null;

new_f = [];
for m = 1:N_mems
    new_f = [new_f; squeeze(f(m, :, :))];
end
f = new_f;
f(isnan(f)) = 100 + 0* randn(sum(isnan(f), 'all'), 1);
ff_null(isnan(ff_null)) = 100;

trueLabels = [];
for iter = 1:N_mems
    trueLabels = [trueLabels, repmat(iter, 1, N_retrievals)];
end
trueLabels = [trueLabels, repmat(N_mems+1, 1, size(ff_null, 1))];
trueLabels = trueLabels';

% classification by kmeans
 % [~, f] = sort(f, 2);

% Perform kmeans with more precision
[predictedLabels, C] = kmeans([f; ff_null] , N_mems+1, ...
    'Replicates', 200, ...          % Run the algorithm 10 times with different initializations
    'MaxIter', 100000, ...            % Increase the maximum number of iterations for convergence
    'Distance', 'sqeuclidean', ...  % Use squared Euclidean distance (default, but customizable)
    'Display', 'final', ...
     'Start', 'plus');            % Display final output with information on convergence


[coeff, score, latent, tsquared, explained, mu] = pca([f; ff_null]);
C = (C-mu)*coeff; % rotating cluster coordiantes to the pca basis

[permpredictedLabels, perm] = matchLabels(trueLabels, predictedLabels);
% perm = perm(perm);

cmap = jet(N_mems); cmap = cmap(randperm(N_mems), :);

figure; view(3); grid on; hold on; 
cmap = [cmap; [0 0 0]];
%%%%%%%%%%%%%%%%%%% Plotting Memories Recall %%%%%%%%%%%%
scatter3(score(:, 1), score(:, 2), score(:, 3), 20, cmap(trueLabels, :), 'filled', 'HandleVisibility', "off")

scatter3(C(:, 1), C(:, 2), C(:, 3), 2000, cmap(perm, :), HandleVisibility="off")
for m = 1:N_mems
    scatter3([], [], [], 1, cmap(m, :), 'filled', DisplayName=['m ' num2str(m)])
end

%%%%%%%%%%%%%%%%%%% Plotting Random Recalls %%%%%%%%%%%%
rnd_recalls = (ff_null-mu)*coeff;
scatter3(rnd_recalls(:, 1), rnd_recalls(:, 2), rnd_recalls(:, 3), 20, 'kh', 'filled', 'HandleVisibility', 'off')

scatter3([], [], [], 1, 'kh', 'filled', DisplayName='random recall')


legend(Location='best')
xlabel("PC1"); ylabel("PC2"); zlabel("PC3"); title("Partial Recall of Memories (" + num2str(alpha*100) + "% of Stimulation Set)")
labellist = arrayfun(@(x) [num2str(x)], 1:N_mems, 'UniformOutput', false); labellist = [labellist, "random recalls"];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
figure; hold on;plot(permpredictedLabels'+0.1, 'k.', DisplayName="Predicted Label"); plot(trueLabels-0.1, 'r.', DisplayName="True Label")
legend(Location='best'); xlabel("data points"); ylabel("Cluster Label"); ylim([0.5 N_mems+1+0.5]); yticks(1:N_mems+1);  yticklabels(labellist);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
fig = figure; fig.Position(3:4) = [1500 1500];
cm = confusionchart(labellist(trueLabels), labellist(permpredictedLabels));

cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';
title('Confusion Matrix: True vs Predicted Labels');
% saveas(fig, [num2str(randi(10)) '.png'])
%%
% Sample Data: Confusion Matrix Counts (modify this data with your own)
% confMatrix = [96 0 0 0 0 0 0 0 0 4;
%               0 99 0 0 0 0 0 0 0 1;
%               0 0 100 0 0 0 0 0 0 0;
%               0 0 0 100 0 0 0 0 0 0;
%               0 0 0 0 97 3 0 0 0 0;
%               0 0 0 0 0 99 1 0 0 0;
%               0 0 0 0 0 0 100 0 0 0;
%               0 0 0 0 0 0 0 95 5 0;
%               0 0 0 0 0 0 0 0 100 0;
%               4 1 0 0 0 0 0 0 2 93];
confMatrix = confusionmat(labellist(trueLabels), labellist(permpredictedLabels));

% Labels for the classes
classLabels = {};
for i = 1:N_mems
    classLabels{end+1} = ['m', num2str(i)];
end
classLabels{end + 1} = 'random recall';

% Create the confusion matrix plot
figure;
cm = confusionchart(confMatrix, classLabels, ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Adjust font sizes for labels, title, and numbers
cm.Title = 'Confusion Matrix: True vs Predicted Labels';
cm.FontSize = 14;  % Adjusts the overall font size
cm.XLabel = 'Predicted Class';
cm.YLabel = 'True Class';

cm.RowSummary

% Adjust title, axis labels, and percentage font sizes
cm.FontSize = 18;  % Adjusts the overall font size

% Adjust number display in cells
cm.DiagonalColor = [0.2 0.6 0.8]; % Set color for diagonal (optional)

% Set colormap (optional)
colormap(flipud(gray)); % Adjust colormap if needed for better clarity
%%
save(net.baseFolder + filesep + 'confMatrices.mat', 'confMatrix', '-mat')

%% Functions 


function [check_flag_save2, check_flag_save, total_spike_count, time_delays] = computeOrders(net, start_patch, end_patch,interval)
    % Computing the order vectors from patch.mat files for computation speed reasons:)

    if nargin < 4
        interval = 100;
    end
    if nargin < 3
        end_patch = net.PatchNumber - 1;
    end
    if nargin < 2
        start_patch = 1;
    end

    if start_patch > 1
       start_net = net.getNetwork(start_patch-1);
       start_time = start_net.t;
    else
        start_time = 0;
    end

    if end_patch ~= net.PatchNumber - 1
       end_net = net.getNetwork(end_patch);
       start_time = end_net.t;
    else
       end_time = net.t;
    end

    
    n_t = round((end_time - start_time)/interval);
    off_set_time = 0;
    
    check_flag_save2 = zeros(n_t, net.N);
    check_flag_save = zeros(n_t, net.N);
    total_spike_count = zeros(n_t, net.N);
    time_delays = zeros(n_t, net.N);

    f = waitbar(0, "Computing First to Spike Orders ...");
    trial_counter = 0;
    time_keeper = start_time;
    for patch_num = start_patch:end_patch
        patch_address = net.RecordingDirectory + filesep + "Patch" + num2str(patch_num) + ".mat";
        pathParts = strsplit(patch_address, {'\', '/'});
        patch_address = fullfile(pathParts{:});
    
        variable_name = "data" + num2str(patch_num);
        s = load(patch_address);
        data = getfield(s, variable_name);
        tempnet = getfield(s, 'obj');
        firings = transpose(data.firings);
        firings(:, 1) = firings(:, 1) - time_keeper;
        for trial_number = 1:round((tempnet.t-time_keeper)/interval)
            % Computing the orders
            
            start_time = (firings(:, 1) > (trial_number-1) * interval + off_set_time);
            end_time = (firings(:, 1) <= trial_number * interval + off_set_time);
            indices = start_time & end_time;
            spike_times = firings(indices, 1) - (trial_number-1) * interval;
            neuron_indices = firings(indices, 2);    
        
            [order, delay] = TimeToFirstSpikeSort(spike_times, neuron_indices, true, net.N, net.Ne);
            [order2, ~] = TimeToFirstSpikeSort(spike_times, neuron_indices, false, net.N, net.Ne);
            trial_counter = trial_counter + 1;
            check_flag_save(trial_counter, :) = order;
            check_flag_save2(trial_counter, :) = order2;
            [GC,GR] = groupcounts(neuron_indices); total_spike_count(trial_counter, GR) =  GC;
            time_delays(trial_counter, :) = delay;
            % ex_neurons_engagement_count(trial_counter) = sum(unique(neuron_indices)<=net.Ne);
            % inh_neurons_engagement_count(trial_counter) = sum(unique(neuron_indices)>net.Ne);
    
            waitbar(patch_num/(net.PatchNumber-1), f, sprintf("Computing First to Spike Orders ... \n trial %d, patch %d/%d", trial_counter, patch_num, net.PatchNumber-1))
        end
    
        time_keeper = tempnet.t;
    end
    
    close(f)
end

function [order, time_delay] = TimeToFirstSpikeSort(spike_times, neuron_indices, separated, N, Ne)
    % TimeToFirstSpikeSort Sorting neurons based on first time to spike.
    %
    % Syntax:
    %   order = TimeToFirstSpikeSort(spike_times, neuron_indices)
    %
    % Description:
    %   A detailed description of the function, explaining its purpose and
    %   how it works.
    %
    % Input Arguments:
    %   spike_times - an array of spike timings.
    %   neuron_indices - an array of neuron indices of spikes.
    %   separated - if order excitatory and inhibitory spikes separately or
    %   together
    %
    % Output Arguments:
    %   order - ordered indices of neurons by who spiked earlier.
    
   
    order = zeros(1, N); % a vector that labels cells by spike order
    time_delay = zeros(1, N); % time of first spike of each neuron
    % neuron_sorted_indices = zeros(size(spike_times, 1), 1); % sorted neuron indices signal
    
    if separated 
        counter_ex = 1;
        counter_inh = Ne + 1;
        
        for i = 1:length(spike_times)
            if neuron_indices(i) <= Ne
                if order(neuron_indices(i)) == 0 % First excitatory spikes
                    % neuron_sorted_indices(i) = counter_ex;
                    order(neuron_indices(i)) = counter_ex;
                    time_delay(neuron_indices(i)) = spike_times(i);
                    counter_ex = counter_ex + 1;
                else % Repeated excitatory spikes
                    % neuron_sorted_indices(i) = order(neuron_indices(i));
                end
            else
                if order(neuron_indices(i)) == 0 % First Inhibitory spikes
                    % neuron_sorted_indices(i) = counter_inh;
                    order(neuron_indices(i)) = counter_inh;
                    time_delay(neuron_indices(i)) = spike_times(i);
                    counter_inh = counter_inh + 1;
                else % Repeated Inhibitory spikes
                    % neuron_sorted_indices(i) = order(neuron_indices(i));
                end
            end  
        end
    end

    if ~separated
        counter = 1; 
        for i = 1:length(spike_times)
            cell = neuron_indices(i);
            if order(cell) == 0 % First spike
                % neuron_sorted_indices(i) = counter;
                order(cell) = counter;
                time_delay(cell) = spike_times(i);
                counter = counter + 1;
            else % Repeated spike
                % neuron_sorted_indices(i) = order(cell);
            end
        end
    end

end

function new_firings = FirstSpikeFirings(firings)
    fired_cells = unique(firings(2, :));
    new_firings = [];
    for cell = fired_cells
        index = find(firings(2, :) == cell);
        if ~isempty(index)
            new_firings = [new_firings; firings(1, index(1)), cell];
        end 
    end
    new_firings = new_firings';
end

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

