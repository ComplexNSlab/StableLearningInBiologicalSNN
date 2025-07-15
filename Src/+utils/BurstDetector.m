% function [bursts, fig] = BurstDetector(firings, threshold, visualize, subset, windsize, timebinsize)
%     % Set default values for each argument
%     if nargin < 2 || isempty(threshold)
%         threshold = []; % Will be calculated if empty
%     end
%     if nargin < 3 || isempty(visualize)
%         visualize = true; % Default to visualize
%     end
%     if nargin < 4 || isempty(subset)
%         subset = 'All'; % Default to include all data
%     end
%     if nargin < 5 || isempty(windsize)
%         windsize = 3; % Default window size for smoothing
%     end
%     if nargin < 6 || isempty(timebinsize)
%         timebinsize = 3; % Default window size for smoothing
%     end
% 
% 
%     % Process data based on the subset type
%     data = firings; 
%     if strcmp(subset, 'Ex')
%         data = data(:, data(2, :) <= 320);
%     elseif strcmp(subset, 'Inh')
%         data = data(:, data(2, :) > 320);
%     end
% 
%     % Define time range and bin size (adjust these parameters as needed)
%     time_bins = min(data(1,:)):timebinsize:max(data(1,:));  % From 0 to 500 ms with 3 ms bins
%     spike_counts = histcounts(data(1,:), time_bins);
% 
%     % Smooth the spike density using a moving average (window size of 3 bins)
%     smoothed_spike_density = movmean(spike_counts, windsize);
% 
%     % Set threshold for burst detection if not provided
%     if isempty(threshold)
%         threshold = mean(smoothed_spike_density)+0.5*std(smoothed_spike_density);
%     end
% 
%     % Find bins where spike density exceeds the threshold
%     burst_indices = find(smoothed_spike_density > threshold);
% 
%     % Initialize bursts array
%     bursts = [];
%     current_burst = burst_indices(1);
% 
%     for i = 2:length(burst_indices)
%         if burst_indices(i) == burst_indices(i-1) + 1
%             % Continue the current burst
%             current_burst = [current_burst, burst_indices(i)];
%         else
%             % End of current burst, record it
%             start_time = time_bins(current_burst(1));
%             end_time = time_bins(current_burst(end) + 1);
%             bursts = [bursts; start_time, end_time];
% 
%             % Start a new burst
%             current_burst = burst_indices(i);
%         end
%     end
% 
%     % Record the last burst
%     if ~isempty(current_burst)
%         start_time = time_bins(current_burst(1));
%         end_time = time_bins(current_burst(end) + 1);
%         bursts = [bursts; start_time, end_time];
%     end
% 
%     fig = [];
%     % Visualization, if enabled
%     if visualize
%         fig = figure();
%         hold on;
% 
%         yyaxis("left")
%         plot(data(1, :), data(2, :), 'k.', 'MarkerSize', 1, 'HandleVisibility', 'off');
% 
%         xlabel("t (ms)");
%         ylabel("cell index");
%         title("Detected Bursts");
%         hv = 'on';
%         for i = 1:size(bursts, 1)
%             if i > 1
%                 hv = 'off';
%             end
%             area(bursts(i, :), 400*[1, 1], 'FaceColor', 'g', 'FaceAlpha', 0.4, 'DisplayName', 'burst', 'HandleVisibility', hv);
%         end
% 
%         yyaxis("right")
%         time_centers = time_bins(1:end-1) + diff(time_bins) / 2; % Calculate time centers for binning
%         plot(time_centers, spike_counts, 'k-', 'DisplayName', 'spike density');
%         plot(time_centers, smoothed_spike_density, 'r-', 'DisplayName', sprintf('smoothed (%d ms)', timebinsize));
%         ylabel("spike density");
% 
%         legend();
%     end
% 
%     % Display detected bursts
%     disp('Detected bursts (start, end) in ms:');
%     disp(bursts);
% end


 function [bursts, fig] = BurstDetector(firings, threshold, visualize, subset, windsize, timebinsize)
    % Set default values for each argument
    if nargin < 2 || isempty(threshold)
        threshold = []; % Will be calculated if empty
    end
    if nargin < 3 || isempty(visualize)
        visualize = true; % Default to visualize
    end
    if nargin < 4 || isempty(subset)
        subset = 'All'; % Default to include all data
    end
    if nargin < 5 || isempty(windsize)
        windsize = 3; % Default window size for smoothing
    end
    if nargin < 6 || isempty(timebinsize)
        timebinsize = 3; % Default window size for smoothing
    end


    % Process data based on the subset type
    data = firings; 
    if strcmp(subset, 'Ex')
        data = data(:, data(2, :) <= 320);
    elseif strcmp(subset, 'Inh')
        data = data(:, data(2, :) > 320);
    end

    % Define time range and bin size (adjust these parameters as needed)
    time_bins = min(data(1,:)):timebinsize:max(data(1,:));  % From 0 to 500 ms with 3 ms bins
    spike_counts = histcounts(data(1,:), time_bins);

    % Smooth the spike density using a moving average (window size of 3 bins)
    smoothed_spike_density = movmean(spike_counts, windsize);

    % Set threshold for burst detection if not provided
    if isempty(threshold)
        threshold = mean(smoothed_spike_density)+0.5*std(smoothed_spike_density);
    end

    % Find bins where spike density exceeds the threshold
    burst_indices = find(smoothed_spike_density > threshold);

    % Initialize bursts array
    bursts = [];
    current_burst = burst_indices(1);

    for i = 2:length(burst_indices)
        if burst_indices(i) == burst_indices(i-1) + 1
            % Continue the current burst
            current_burst = [current_burst, burst_indices(i)];
        else
            % End of current burst, record it
            start_time = time_bins(current_burst(1));
            end_time = time_bins(current_burst(end) + 1);
            bursts = [bursts; start_time, end_time];

            % Start a new burst
            current_burst = burst_indices(i);
        end
    end

    % Record the last burst
    if ~isempty(current_burst)
        start_time = time_bins(current_burst(1));
        end_time = time_bins(current_burst(end) + 1);
        bursts = [bursts; start_time, end_time];
    end

    fig = [];
    % Visualization, if enabled
    if visualize
        fig = figure();
        hold on;

        yyaxis("left")
        plot(data(1, :)/1000, data(2, :), 'k.', 'MarkerSize', 1, 'HandleVisibility', 'off');

        xlabel("t (s)");
        ylabel("cell index");
        title("Detected Bursts");
        hv = 'on';
        for i = 1:size(bursts, 1)
            if i > 1
                hv = 'off';
            end
            area(bursts(i, :)/1000, 400*[1, 1], 'FaceColor', 'g', 'FaceAlpha', 0.4, 'DisplayName', 'burst', 'HandleVisibility', hv);
        end

        yyaxis("right")
        time_centers = time_bins(1:end-1) + diff(time_bins) / 2; % Calculate time centers for binning
        plot(time_centers/1000, spike_counts, 'k-', 'DisplayName', 'spike density');
        plot(time_centers/1000, smoothed_spike_density, 'r-', 'DisplayName', sprintf('smoothed (%d ms)', timebinsize));
        ylabel("spike density");

        legend();
    end

    % Display detected bursts
    disp('Detected bursts (start, end) in ms:');
    disp(bursts);
end
