function raster = getRasterPlot(firings, bin_size)
%GETRASTERPLOT Returns binned spike counts as a raster matrix.
%
%   raster = getRasterPlot(firings, bin_size) bins the spike train data
%   from `firings` (2 x N) into time bins of size `bin_size` (ms), and 
%   returns a matrix of size [n_neurons x n_bins].
%
%   INPUT:
%       firings   - 2 x N matrix [spike_time(ms); neuron_index]
%       bin_size  - size of each time bin in milliseconds
%
%   OUTPUT:
%       raster    - matrix of spike counts (neurons x time bins)

    % Ensure firings are oriented correctly
    if size(firings, 1) ~= 2
        error('Input firings must be a 2xN matrix [time; neuron_index].');
    end

    spike_times = firings(1, :);         % in ms
    neuron_ids  = firings(2, :);         % integer neuron indices

    % Get number of neurons and duration
    n_neurons = max(neuron_ids);
    T = ceil(max(spike_times));          % total duration in ms
    n_bins = ceil(T / bin_size);

    % Initialize raster matrix
    raster = zeros(n_neurons, n_bins);

    % Loop over all spikes
    for i = 1:length(spike_times)
        t_bin = floor(spike_times(i) / bin_size) + 1;
        neuron = neuron_ids(i);

        if t_bin <= n_bins
            raster(neuron, t_bin) = raster(neuron, t_bin) + 1;
        end
    end
end
