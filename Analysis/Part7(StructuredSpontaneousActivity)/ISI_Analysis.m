clc; clear;

% === Settings ===
base_path = 'C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part7(StructuredSpontaneousActivity)\Data\N400\noise100%';
folders = dir(base_path);
folders = folders([folders.isdir] & ~startsWith({folders.name}, '.'));

% === Choose binning mode: 'log' or 'linear' ===
bin_mode = 'linear';  % Change to 'linear' if desired

% === Bin settings ===
switch bin_mode
    case 'log'
        isi_edges = logspace(log10(1), log10(1e4), 100);  % ms
        freq_edges = logspace(log10(0.1), log10(1000), 100);  % Hz
    case 'linear'
        isi_edges = 0:0.1:5000;  % ms
        freq_edges = 0:0.1:500;  % Hz
    otherwise
        error('Invalid bin_mode. Choose either "log" or "linear".')
end

isi_centers = isi_edges(1:end-1) + diff(isi_edges)/2;
freq_centers = freq_edges(1:end-1) + diff(freq_edges)/2;

% === Preallocate histogram matrices ===
n_sim = length(folders);
hist_isi_pre = zeros(n_sim, length(isi_centers));
hist_isi_post = zeros(n_sim, length(isi_centers));
hist_freq_pre = zeros(n_sim, length(freq_centers));
hist_freq_post = zeros(n_sim, length(freq_centers));

valid_idx = 0;

% === Loop through simulations ===
for i = 1:n_sim
    sim_path = fullfile(base_path, folders(i).name, 'InitialWorkSpace.mat');
    if isfile(sim_path)
        load(sim_path, 'firings_pre', 'firings_post');
        valid_idx = valid_idx + 1;

        % Compute ISIs and 1/ISI frequencies
        isis_pre = compute_all_isis(firings_pre);
        isis_post = compute_all_isis(firings_post);
        freq_pre_i = 1000 ./ isis_pre;
        freq_post_i = 1000 ./ isis_post;

        % Compute histograms
        hist_isi_pre(valid_idx, :) = histcounts(isis_pre, isi_edges, 'Normalization', 'pdf');
        hist_isi_post(valid_idx, :) = histcounts(isis_post, isi_edges, 'Normalization', 'pdf');
        hist_freq_pre(valid_idx, :) = histcounts(freq_pre_i, freq_edges, 'Normalization', 'pdf');
        hist_freq_post(valid_idx, :) = histcounts(freq_post_i, freq_edges, 'Normalization', 'pdf');
    else
        warning('Skipping: %s (file not found)', sim_path);
    end
end

outlier_mask = ~(max(hist_freq_post, [], 2) > 0.1);
hist_isi_pre = hist_isi_pre(outlier_mask, :);
hist_isi_post = hist_isi_post(outlier_mask, :);
hist_freq_pre = hist_freq_pre(outlier_mask, :);
hist_freq_post = hist_freq_post(outlier_mask, :);
%% Plot the ISI dist

% === Compute mean and prctile ===
mean_isi_pre = mean(hist_isi_pre, 1);
mean_isi_post = mean(hist_isi_post, 1);

ci_level = 98;  % Confidence interval percentage
lower_bound = (100 - ci_level) / 2;
upper_bound = 100 - lower_bound;

% Compute percentiles for ISI
isi_ci_low_pre  = prctile(hist_isi_pre, lower_bound, 1);
isi_ci_high_pre = prctile(hist_isi_pre, upper_bound, 1);
isi_ci_low_post  = prctile(hist_isi_post, lower_bound, 1);
isi_ci_high_post = prctile(hist_isi_post, upper_bound, 1);

% === ISI Distribution ===
fig = figure('Name', 'ISI Distributions', 'Position', [100 100 900 500]); hold on;
fill_between(isi_centers, isi_ci_low_pre, isi_ci_high_pre, [0.7 0.7 1]);
plot(isi_centers, mean_isi_pre, 'b', 'LineWidth', 0.5, 'DisplayName', 'Pre');
fill_between(isi_centers, isi_ci_low_post, isi_ci_high_post, [1 0.7 0.7]);
plot(isi_centers, mean_isi_post , 'r', 'LineWidth', 0.5, 'DisplayName', 'Post');
xlabel('ISI (ms)');
ylabel('Probability');
title('ISI Distributions');
legend('EdgeColor', 'none'); grid on;
set(gca, 'XScale', 'log');
set(gca, 'YScale', 'log'); ylim([1e-4, 1]);

% === Annotate Post (red) ===
[pks, locs] = findpeaks(mean_isi_post, isi_centers, 'NPeaks', 3, 'MinPeakProminence', 0.001);
plot(locs, pks * 1.5, 'kv', 'MarkerFaceColor', 'r', 'HandleVisibility', 'off', 'MarkerEdgeColor','none');
text(locs, pks * 2.25, compose('%.1f ms', locs), 'Color', 'r', ...
     'FontSize', 14, 'HorizontalAlignment', 'center', 'Rotation', 45);

% === Annotate Pre (blue) ===
[pks, locs] = findpeaks(mean_isi_pre, isi_centers, 'NPeaks', 1, 'MinPeakProminence', 0.001);
plot(locs, pks * 1.5, 'kv', 'MarkerFaceColor', 'b', 'HandleVisibility', 'off', 'MarkerEdgeColor','none');
text(locs, pks * 2.25, compose('%.1f ms', locs), 'Color', 'b', ...
     'FontSize', 14, 'HorizontalAlignment', 'center', 'Rotation', 45);

% exportgraphics(fig, fullfile("Results", "ISI_dist.pdf"), ContentType="vector")
% exportgraphics(fig, fullfile("Results", "ISI_dist.png"), ContentType="image")
%% Plot the 1/ISI dist
kernel_win = 15;

% === Compute mean and prctile ===
mean_freq_pre = mean(hist_freq_pre, 1);
mean_freq_post = mean(hist_freq_post, 1);

ci_level = 98;  % Confidence interval percentage
lower_bound = (100 - ci_level) / 2;
upper_bound = 100 - lower_bound;

% Compute percentiles for Frequency
freq_ci_low_pre  = prctile(hist_freq_pre, lower_bound, 1);
freq_ci_high_pre = prctile(hist_freq_pre, upper_bound, 1);
freq_ci_low_post  = prctile(hist_freq_post, lower_bound, 1);
freq_ci_high_post = prctile(hist_freq_post, upper_bound, 1);

% === 1/ISI Frequency Distribution ===
fig = figure('Name', '1/ISI Frequency Distributions', 'Position', [100 100 900 500]); hold on;
fill_between(freq_centers, freq_ci_low_pre, freq_ci_high_pre, [0.8 0.8 1]);
plot(freq_centers, smoothdata(mean_freq_pre, 'lowess', kernel_win), 'b', 'LineWidth', 0.5, 'DisplayName', 'Pre');
fill_between(freq_centers, freq_ci_low_post, freq_ci_high_post, [1 0.8 0.8]);
plot(freq_centers, smoothdata(mean_freq_post, 'lowess', kernel_win), 'r', 'LineWidth', 0.5, 'DisplayName', 'Post');
xlabel('Frequency (Hz)');
ylabel('Probability');
title('Instantaneous Frequency Distribution')
legend('EdgeColor', 'none'); grid on;
% set(gca, 'XScale', 'log', 'fontname', 'times New Roman', 'Fontsize', 16); 
% set(gca, 'YScale', 'log'); ylim([1e-4, 1]);
set(gca, 'XScale', 'linear');
xlim([0.05 30]); 
ylim([0 0.25]);

% === Annotate Post (red) ===
[pks, locs] = findpeaks(smoothdata(mean_freq_post, 'lowess', kernel_win), freq_centers, 'NPeaks', 4, 'MinPeakProminence', 0.001);
plot(locs, pks + 0.01, 'kv', 'MarkerFaceColor', 'r', 'HandleVisibility', 'off', 'MarkerEdgeColor','none');
text(locs, pks + 0.03, compose('%.1f Hz', locs), 'Color', 'r', ...
     'FontSize', 14, 'HorizontalAlignment', 'center', 'Rotation', 45);

% === Annotate Pre (blue) ===
[pks, locs] = findpeaks(smoothdata(mean_freq_pre, 'lowess', kernel_win), freq_centers, 'NPeaks', 1, 'MinPeakProminence', 0.001);
plot(locs, pks + 0.01, 'kv', 'MarkerFaceColor', 'b', 'HandleVisibility', 'off', 'MarkerEdgeColor','none');
text(locs, pks + 0.03, compose('%.1f Hz', locs), 'Color', 'b', ...
     'FontSize', 14, 'HorizontalAlignment', 'center', 'Rotation', 45);

% exportgraphics(fig, fullfile("Results", "instantaneousFreq_dist.pdf"), ContentType="vector")
% exportgraphics(fig, fullfile("Results", "instantaneousFreq_dist.png"), ContentType="image")
%% fitting 1/f pink noise to the pre distribution of frequency
% === INPUTS ===
% freq_centers : Frequency bin centers
% mean_freq_pre : Mean distribution of power/frequency before learning

% === Define fitting regions ===
l1 = 2;  r1 = 6;
l2 = 10; r2 = 30;
region1 = (freq_centers >= l1) & (freq_centers <= r1);
region2 = (freq_centers >  l2) & (freq_centers <= r2);

% === Prepare main figure ===
figure; hold on;
loglog(freq_centers, mean_freq_pre, 'b', 'DisplayName', 'Data');

% === Fit Region 1 ===
x1 = log10(freq_centers(region1));
y1 = log10(mean_freq_pre(region1));
p1 = polyfit(x1, y1, 1);
slope1 = p1(1); intercept1 = p1(2);
f_fit1 = logspace(log10(l1), log10(r1), 100);
P_fit1 = 10^intercept1 * f_fit1.^slope1;
loglog(f_fit1, P_fit1, 'k--', 'LineWidth', 2, ...
    'DisplayName', sprintf('Fit 1: 1/f^{%.2f}', -slope1));

% === Fit Region 2 ===
x2 = log10(freq_centers(region2));
y2 = log10(mean_freq_pre(region2));
p2 = polyfit(x2, y2, 1);
slope2 = p2(1); intercept2 = p2(2);
f_fit2 = logspace(log10(l2), log10(r2), 100);
P_fit2 = 10^intercept2 * f_fit2.^slope2;
loglog(f_fit2, P_fit2, 'r--', 'LineWidth', 2, ...
    'DisplayName', sprintf('Fit 2: 1/f^{%.2f}', -slope2));

% === Slope estimation (instantaneous derivative in log-log) ===
valid_idx = mean_freq_pre > 1e-5;  % Avoid zeros
log_f = log10(freq_centers(valid_idx));
log_P = log10(mean_freq_pre(valid_idx));

% Smooth the log-log signal before diff
frame_len = 11;  % Must be odd; increase for more smoothing
log_P_smooth = sgolayfilt(log_P, 2, frame_len);
log_f_smooth = sgolayfilt(log_f, 2, frame_len);

% Compute numerical derivative
slope_inst = gradient(log_P_smooth) ./ gradient(log_f_smooth);
abs_slope = abs(slope_inst);
abs_slope_clipped = min(abs_slope, 4);  % Cap for better scale

% === Plot slope ===
yyaxis right
plot(freq_centers(valid_idx), abs_slope_clipped, 'm', 'DisplayName', '|d log(P) / d log(f)|');
ylabel('|d log(P) / d log(f)|');
set(gca, 'YColor', 'm');

% === Optional: highlight pink-noise regions ===
pink_idx = (abs_slope > 1) & (abs_slope < 2);
loglog(freq_centers(valid_idx(pink_idx)), ...
       mean_freq_pre(valid_idx(pink_idx)), 'mo', 'DisplayName', 'Pink noise zone');

% === Plot settings ===
xlabel('Frequency (Hz)');
yyaxis left
ylabel('Probability');
title('Piecewise Power-law Fit and Instantaneous Slope');
set(gca, 'XScale', 'log', 'YScale', 'log');
xlim([1e-1, 1e2]);
ylim([1e-4, 1]);
legend('Location', 'southwest');
grid on;


%% === Helper Functions ===
function fill_between(x, y1, y2, color)
    % Clip to avoid log-scale issues (replace zeros or negatives with eps)
    y1 = max(y1, eps);
    y2 = max(y2, eps);

    % Ensure x is also strictly positive for log-log plots
    x = max(x, eps);

    % Plot the filled area
    fill([x, fliplr(x)], [y1, fliplr(y2)], color, ...
        'EdgeColor', 'none', 'FaceAlpha', 0.4, 'HandleVisibility', 'off');
end

function isis = compute_all_isis(firings)
    neuron_ids = unique(firings(2, :));
    isis = [];
    for n = neuron_ids
        spike_times = firings(1, firings(2, :) == n);
        spike_times = sort(spike_times);
        if length(spike_times) >= 2
            isis = [isis, diff(spike_times)];
        end
    end
end
