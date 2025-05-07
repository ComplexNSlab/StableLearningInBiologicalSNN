function [burst_features, feature_names] = ExtractBurstFeatures(firings, bursts)
    % ExtractBurstFeatures extracts the first spike time for each neuron in each burst,
    % normalized by subtracting the mean first spike time within that burst. NaNs are
    % replaced by the mean of each feature across bursts, and columns with all NaNs are removed.
    %
    % Inputs:
    %   - firings: An Nx2 matrix where each row represents a spike event with [time, cell index]
    %   - bursts: An Mx2 matrix of detected bursts, where each row is [start_time, end_time]
    %
    % Outputs:
    %   - burst_features: An MxP matrix where each row contains the first spike time feature
    %                     for each neuron in the burst, mean-subtracted and NaN-imputed.
    %   - feature_names: A cell array of feature names corresponding to each column in burst_features
    %
    % Extracted Feature:
    %   For each neuron within each burst, the first spike time minus the mean first spike time.

    % Get the unique neurons (cell indices) across all bursts
    unique_neurons = unique(firings(2, :));
    num_neurons = length(unique_neurons);
    
    % Initialize the feature matrix (each row represents a burst's features)
    burst_features = NaN(size(bursts, 1), num_neurons); % NaN for neurons not firing in a burst

    for i = 1:size(bursts, 1)
        % Extract the start and end time of the current burst
        start_time = bursts(i, 1);
        end_time = bursts(i, 2);

        % Get spikes within the current burst
        burst_data = firings(:, firings(1, :) >= start_time & firings(1, :) <= end_time);

        % Find the first spike time for each neuron in this burst
        first_spike_times = NaN(1, num_neurons);
        for j = 1:num_neurons
            neuron_id = unique_neurons(j);
            neuron_spike_times = burst_data(1, burst_data(2, :) == neuron_id);
            if ~isempty(neuron_spike_times)
                first_spike_times(j) = min(neuron_spike_times); % Earliest spike time for this neuron
            end
        end

        % Calculate the mean of all first spike times (ignoring NaNs)
        mean_first_spike_time = mean(first_spike_times(~isnan(first_spike_times)));

        % Subtract the mean first spike time from each neuron's first spike time
        % normalized_first_spike_times = first_spike_times - mean_first_spike_time;
        % normalized_first_spike_times = first_spike_times;

        % Store the normalized first spike times in the feature matrix for this burstz
        % normalized_first_spike_times = first_spike_times - start_time;
        % normalized_first_spike_times = zscore()
        burst_features(i, :) = first_spike_times - start_time;
    end

    % Identify columns that have all NaNs and remove them
    % all_nan_columns = all(isnan(burst_features), 1);
    % burst_features(:, all_nan_columns) = [];
    % unique_neurons(all_nan_columns) = []; % Remove corresponding neuron IDs for feature names
    % 
    % % Impute remaining NaNs in the feature matrix by replacing them with column means
    % col_means = nanmean(burst_features); % Calculate mean of each column, ignoring NaNs
    % for j = 1:size(burst_features, 2)
    %     burst_features(isnan(burst_features(:, j)), j) = col_means(j);
    % end

    % Define feature names for each neuron
    feature_names = arrayfun(@(id) sprintf('Neuron %d First Spike Time', id), unique_neurons, 'UniformOutput', false);

    % Display the feature matrix with labels
    disp('Burst Features (First Spike Times, Mean-Subtracted and NaN-Imputed):');
    disp(array2table(burst_features, 'VariableNames', feature_names));
end
