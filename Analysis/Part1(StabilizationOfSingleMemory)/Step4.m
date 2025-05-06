%% Reading Responses in different representations and computing the distances
clc; clear;

N = 600; % NetworkSize
nTrials = 1000;
scaleFolder = 'Scaled50';

folderPath = fullfile(pwd,"Data", scaleFolder, "N" + num2str(N));
sim_folders = dir(folderPath);
sim_folders = sim_folders(~ismember({sim_folders.name}, {'.', '..'}));

delays_data = zeros(length(sim_folders), nTrials, N);
spike_counts_data = zeros(length(sim_folders), nTrials, N);

for i = 1:length(sim_folders)
    load(fullfile(folderPath,  sim_folders(i).name, "MemoryRepresentations.mat"), 'delays', 'spike_counts');
    delays_data(i, :, :) = delays; 
    spike_counts_data(i, :, :) = spike_counts;
end

delays_data(delays_data == 0) = nan;
%% === Figure 1: Delays Statistics ===

fig1 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w');
hold on;

ci_fill = [1.0 0.85 0.75];  % Light orange for CI
gray_color = [0.5 0.5 0.5 0.1];  % Simulated low-opacity gray

x = 1:nTrials;
y = nanmean(delays_data, 3);
ci_low = prctile(y, 5);
ci_high = prctile(y, 95);

fill([x, fliplr(x)], [ci_high, fliplr(ci_low)], ...
     ci_fill, 'EdgeColor', 'none', 'DisplayName', '90\% CI');

% Plot gray individual traces
for i = 1:size(y, 1)
    plot(x, y(i,:), 'Color', gray_color, 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

plot(x, mean(y), 'Color', [0.85 0.33 0.1], 'LineWidth', 2.5, 'DisplayName', 'Mean');

xlabel('Trial', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Time Delay (ms)', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf("Mean First Spike Timing per Trial over %d simulations", length(sim_folders)))
legend('Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');

set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');

posi = get(gcf, 'Position');
set(gcf, 'PaperSize', posi(3:4));

print(fig1, 'time_delay_plot', '-dpdf', '-r600');
print(fig1, 'time_delay_plot', '-dpng', '-r600');
%% === Figure 2: Spike Count vs Trial ===

fig2 = figure('Units', 'inches', 'Position', [1 1 6 4], 'Color', 'w');
hold on;

x = 1:nTrials;
y = mean(spike_counts_data, 3);
ci_low = prctile(y, 5);
ci_high = prctile(y, 95);
mean_curve = mean(spike_counts_data, [1, 3]);

fill([x, fliplr(x)], [ci_high, fliplr(ci_low)], [0.8 1 0.8], ...
     'EdgeColor', 'none', 'DisplayName', '90\% CI');

gray_color = [0.8 0.8 0.8];
for i = 1:size(y, 1)
    plot(x, y(i,:), 'Color', gray_color, 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

plot(x, mean_curve, 'LineWidth', 2, 'Color', 'g', 'DisplayName', 'Mean');

xlabel('Trial', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Spike Count', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf("Mean Firing Rate per Trial over %d simulations", length(sim_folders)))

legend('Location', 'northwest', 'Interpreter', 'latex', 'Box', 'off');
set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');

posi = get(gcf, 'Position');
set(gcf, 'PaperSize', posi(3:4));

print(fig2, 'spike_count_plot', '-dpdf', '-r600');
print(fig2, 'spike_count_plot', '-dpng', '-r600');
