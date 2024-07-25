function order = TimeToFirstSpikeSort(spike_times, neuron_indices)
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
    %
    % Output Arguments:
    %   order - ordered indices of neurons by who spiked earlier.
    
    N = 400; Ne = 320;
    order = zeros(1, N);
    counter_ex = 1;
    counter_inh = Ne + 1;
  
    neuron_sorted_indices = zeros(size(spike_times, 1), 1);
   
    for i = 1:length(spike_times)
        if true
            if neuron_indices(i) <= Ne
                if order(neuron_indices(i)) == 0 % First excitatory spikes
                    neuron_sorted_indices(i) = counter_ex;
                    order(neuron_indices(i)) = counter_ex;
                    counter_ex = counter_ex + 1;
                else % Repeated excitatory spikes
                    neuron_sorted_indices(i) = order(neuron_indices(i));
                end
            else
                if order(neuron_indices(i)) == 0 % First Inhibitory spikes
                    neuron_sorted_indices(i) = counter_inh;
                    order(neuron_indices(i)) = counter_inh;
                    counter_inh = counter_inh + 1;
                else % Repeated Inhibitory spikes
                    neuron_sorted_indices(i) = order(neuron_indices(i));
                end
            end
        end
    end
end