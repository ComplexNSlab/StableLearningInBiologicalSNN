function raster = getRasterPlot(firings, bin_size, T)
%GETRASTERPLOT Returns binned spike counts as a raster matrix.
%
%   raster = getRasterPlot(firings, bin_size)
%   raster = getRasterPlot(firings, bin_size, T)
%
%   INPUT:
%       firings   - 2 x N matrix [spike_time(ms); neuron_index]
%       bin_size  - size of each time bin in milliseconds
%       T (opt)   - total duration in ms (optional)
%
%   OUTPUT:
%       raster    - matrix of spike counts (neurons x time bins)

    % Validate input
    if size(firings, 1) ~= 2
        error('Input firings must be a 2xN matrix [time; neuron_index].');
    end

    spike_times = firings(1, :);         % in ms
    neuron_ids  = firings(2, :);         % integer neuron indices

    % Number of neurons
    n_neurons = max(neuron_ids);

    % Determine duration
    if nargin < 3 || isempty(T)
        T = ceil(max(spike_times));  % fallback: estimate T from data
    end
    n_bins = ceil(T / bin_size);

    % Initialize raster
    raster = zeros(n_neurons, n_bins);

    % Loop over spikes
    for i = 1:length(spike_times)
        t_bin = floor(spike_times(i) / bin_size) + 1;
        neuron = neuron_ids(i);

        if t_bin <= n_bins && neuron <= n_neurons
            raster(neuron, t_bin) = raster(neuron, t_bin) + 1;
        end
    end
end
