% Step2_Recalls.m  --  Partial-cue recall testing.
%
% For the final trained network state, performs recall trials with partial
% cues (controlled by alpha = fraction of original pattern) for both
% learned memories and random control patterns.  For each memory the
% script:
%   1. Presents a random alpha-fraction subset of the learned stimulus.
%   2. Records the evoked spike train and extracts four neural
%      representations: spike-order (together & separate), spike counts,
%      and time-delays.
%   3. Repeats the same procedure with random (untrained) stimuli.
%   4. Saves all representations + group labels to a Recalls subfolder.
%
% Expected workspace variables (set by Step0.m or caller):
%   net, stims, N_mems, nTrials, stim_len, alpha
%
% Contains helper functions: computeRepresentations, TimeToFirstSpikeSort.

%% Parameters
N_retrievals = 100;
N_rands = 100; n_repeats = N_mems;

%%

bar = waitbar(0, "Please wait...");
for patch_num = N_mems
    load(fullfile(net.RecordingDirectory, sprintf("patch%d.mat", patch_num)), 'obj');
    netRecall = obj;
    netRecall.saveSimulation = false;
    netRecall.STDP = false;

    firings = [];
    % Memory Recalls
     for m = 1:N_mems
         for iter = 1:N_retrievals
            if mod(iter, 10) == 0
                waitbar(((m-1)*N_retrievals + iter)/(n_repeats*N_rands+N_retrievals*N_mems), bar, sprintf("After Learning Memory %d/%d, Alpha: %.2f\n  Memory %d, Partial Recalling: %d/%d", patch_num, N_mems ,alpha, m, iter, N_retrievals));
            end

            stim = stims(m).copy();
            stim.Ncells = ceil(alpha * stims(m).Ncells);
            sub_set = randperm(stims(m).Ncells, stim.Ncells);
            stim.pattern_indices = stim.pattern_indices(sub_set);
            stim.pattern_timings = mod(stim.pattern_timings(sub_set), 100);
            stim.interval = 100;
            stim.start_time = 5;
            stim.ConstructStimCurrent();
            
            netRecall.stims = stim;
            netRecall.run(100);
            firings = [firings; netRecall.firings];
        end
    end
    
    for repeat = 1:n_repeats
        stim_rand = Stimulation(netRecall, 100, 2, 30, ceil(stims(1).Ncells), 10);
        % Random Recalls
        for iter = 1:N_rands
            if mod(iter, 10) == 0
                waitbar(((repeat-1)*N_rands + iter + N_retrievals*N_mems)/(N_retrievals*N_mems+N_rands*n_repeats), bar, sprintf("Alpha: %.2f\n Random Recall: %d/%d", alpha, iter, N_rands));
            end
            
            stim = stim_rand.copy();
            stim.Ncells = ceil(alpha * stim_rand.Ncells);
            sub_set = randperm(stim_rand.Ncells, stim.Ncells);
            stim.pattern_indices = stim.pattern_indices(sub_set);
            stim.pattern_timings = mod(stim.pattern_timings(sub_set), 100);
            stim.interval = 100;
            stim.start_time = 5;
            stim.ConstructStimCurrent();
            
            netRecall.stims = stim;
            
            netRecall.stims = stim;
            netRecall.run(100);
            firings = [firings; netRecall.firings];
        end
    end
    
    
    [orders_together, orders_separate, spikeCounts, delays] = computeRepresentations(netRecall, firings , patch_num*nTrials*stim_len, N_retrievals*N_mems + N_rands);
    groups = [];
    for m = 1:N_mems
        groups = [groups, repmat(sprintf("m%d", m), 1, N_retrievals)];
    end
    groups = [groups, repmat("random", 1, n_repeats*N_rands)];
    
    savePath = fullfile(net.RecordingDirectory, "Recalls", sprintf("alpha%d", round(100*alpha)));
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    save(fullfile(savePath, sprintf("recalls%d", patch_num)), 'groups', "orders_together", "orders_separate", "spikeCounts", "delays", "firings");
end
close(bar); 

%% Functions 

function [check_flag_save2, check_flag_save, total_spike_count, time_delays] = computeRepresentations(net, firings, t_i, nTrials, interval)
    % Computing the order vectors from patch.mat files for computation speed reasons:)

    if nargin < 5
        interval = 100;
    end
    off_set_time = 0;
    T = nTrials * interval;
    check_flag_save2 = zeros(round(T/interval), net.N);
    check_flag_save = zeros(round(T/interval), net.N);
    total_spike_count = zeros(round(T/interval), net.N);
    time_delays = zeros(round(T/interval), net.N);
    % ex_neurons_engagement_count = zeros(1, round(net.t/interval));
    % inh_neurons_engagement_count = zeros(1, round(net.t/interval));
    
    f = waitbar(0, "Computing First to Spike Orders ...");
    trial_counter = 0;
    
    firings(:, 1) = firings(:, 1) - t_i;
    
    for trial_number = 1:round((net.t-t_i)/interval)
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

        waitbar(0, f, sprintf("Computing Representations ... \n trial %d", trial_counter))
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