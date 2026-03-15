% This script runs and simulate a network given your customize condition 

% clear; clc;
% N = 400; nTrials = 1000; trialLen = 100; scale50Flag = true;
%% Initializing the Network properties

if scale50Flag
    scaleFolder = "Scaled50";
else
    scaleFolder = "constant50";
end
baseFolder = fullfile(pwd, 'Data', scaleFolder, "N" + num2str(N));
net = IzhikevichNetwork(N, 'heterogeneity', true, 'g_ee', 0.5, 'g_ei', 2, 'g_ie', 2, 'ExtoExDegree', 20, 'InhtoExDegree', 5, 'ExtoInhDegree', 5, 'baseFolder', baseFolder);

net.STDP = true;
net.noise = false;

net.sampling_rate = 5000;
%% Simulating 

if scale50Flag
    N_stim = round(50*N/400);
else
    N_stim = 50;
end

stim = Stimulation(net, trialLen, 2, 30, N_stim, 5);
net.stimulation = true;

net.run(trialLen * nTrials);
data = net.getData();
%% Computing memory representations (First Spike Order, Time Delay, Spike count)

[orders_together, orders_separate, spike_counts, delays] = computeOrders(net);
save(net.RecordingDirectory +  filesep +  "MemoryRepresentations", "orders_together", "orders_separate", "spike_counts", "delays");

%% Functions 

function [check_flag_save2, check_flag_save, total_spike_count, time_delays] = computeOrders(net, interval)
    % Computing the order vectors from patch.mat files for computation speed reasons:)

    if nargin < 2
        interval = 100;
    end
    off_set_time = 0;
    
    check_flag_save2 = zeros(round(net.t/interval), net.N);
    check_flag_save = zeros(round(net.t/interval), net.N);
    total_spike_count = zeros(round(net.t/interval), net.N);
    time_delays = zeros(round(net.t/interval), net.N);
    % ex_neurons_engagement_count = zeros(1, round(net.t/interval));
    % inh_neurons_engagement_count = zeros(1, round(net.t/interval));
    
    f = waitbar(0, "Computing First to Spike Orders ...");
    trial_counter = 0;
    time_keeper = 0;
    for patch_num = 1:net.PatchNumber-1
        patch_address = net.RecordingDirectory + filesep + "Patch" + num2str(patch_num) + ".mat";
        pathParts = strsplit(patch_address, {'\', '/'});
        patch_address = fullfile(pathParts{:});
    
        variable_name = "data" + num2str(patch_num);
        s = load(patch_address);
        data = getfield(s, variable_name);
        net = getfield(s, 'obj');
        firings = transpose(data.firings);
        firings(:, 1) = firings(:, 1) - time_keeper;
        
        for trial_number = 1:round((net.t-time_keeper)/interval)
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
    
        time_keeper = net.t;
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