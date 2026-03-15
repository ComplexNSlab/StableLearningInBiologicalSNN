function filtered = LowPassFilter(firings, T, tau)
%LOWPASSFILTER Applies an exponential low-pass filter to spike trains.
%
%   filtered = LowPassFilter(firings, T) applies a default low-pass filter
%   with tau = 2 s.
%
%   filtered = LowPassFilter(firings, T, tau) allows specifying the time
%   constant tau manually.
%
%   INPUTS:
%       firings - 2 x N matrix of spikes.
%                 firings(1, :) are spike times (in seconds),
%                 firings(2, :) are neuron indices (1-based).
%       T       - total duration of the simulation (in seconds).
%       tau     - (optional) van Rossum time constant (in seconds), default is 2.
%
%   OUTPUT:
%       filtered - matrix of size [n_neurons x n_timepoints],
%                  each row is the filtered spike train for one neuron.

    if nargin < 3
        tau = 2;  % default value
    end

    % Set simulation resolution
    dt = 0.1;            % time resolution in seconds
    time = dt:dt:T;      % time vector
    n_T = length(time);

    % Define number of neurons (fixed at 400 — adjust if needed)
    n_neurons = 400;

    % Initialize output
    filtered = zeros(n_neurons, n_T);

    % Iterate through all spike events
    for i = 1:size(firings, 2)
        spike_time = firings(1, i);    % time of spike (in seconds)
        neuron = firings(2, i);        % neuron index (1-based)

        % Convert spike time to time index
        idx = round(spike_time / dt) + 1;

        if idx <= n_T
            decay_len = n_T - idx + 1;

            % Add exponential decay to that neuron's trace
            filtered(neuron, idx:end) = filtered(neuron, idx:end) + ...
                exp(-(0:decay_len - 1) * dt / tau)/tau;
        end
    end
end
