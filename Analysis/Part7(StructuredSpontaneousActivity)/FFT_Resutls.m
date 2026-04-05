clear; clc;

% === Load Data ===
load('C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part7(StructuredSpontaneousActivity)\Data\N400\noise100%\fft_surrogates.mat');
load('C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part7(StructuredSpontaneousActivity)\Data\N400\noise100%\fft_results.mat');

% === Zero DC Component ===
fft_neuron_post(:, 1) = eps;
fft_neuron_pre(:, 1) = eps;
fft_population_post(:, 1) = eps;
fft_population_pre(:, 1) = eps;

% === Reshape null signals [5 × 500000 × 30] → [30 × 5 × 500000] ===
reshape_null = @(C) permute(reshape(cell2mat(C), [5, 500000, 30]), [3, 1, 2]);
fft_neuron_post_null = reshape_null(fft_neuron_post_null);
fft_neuron_pre_null = reshape_null(fft_neuron_pre_null);
fft_population_post_null = reshape_null(fft_population_post_null);
fft_population_pre_null = reshape_null(fft_population_pre_null);

% === Zero DC component for nulls ===
fft_neuron_post_null(:, :, 1) = eps;
fft_neuron_pre_null(:, :, 1) = eps;
fft_population_post_null(:, :, 1) = eps;
fft_population_pre_null(:, :, 1) = eps;

% === Trim to positive frequencies ===
N = size(fft_neuron_post, 2);
f = (0:floor(N/2)) * (1000 / bin_size) / N;

trim = @(X) X(:, 1:length(f));
fft_neuron_post = trim(fft_neuron_post);
fft_neuron_pre = trim(fft_neuron_pre);
fft_population_post = trim(fft_population_post);
fft_population_pre = trim(fft_population_pre);

trim_null = @(X) X(:, :, 1:length(f));
fft_neuron_post_null = trim_null(fft_neuron_post_null);
fft_neuron_pre_null = trim_null(fft_neuron_pre_null);
fft_population_post_null = trim_null(fft_population_post_null);
fft_population_pre_null = trim_null(fft_population_pre_null);

% === Exclude DC (0 Hz) frequency ===
f = f(2:end);
fft_neuron_post = fft_neuron_post(:, 2:end);
fft_neuron_pre  = fft_neuron_pre(:, 2:end);
fft_population_post = fft_population_post(:, 2:end);
fft_population_pre  = fft_population_pre(:, 2:end);

fft_neuron_post_null = fft_neuron_post_null(:, :, 2:end);
fft_neuron_pre_null  = fft_neuron_pre_null(:, :, 2:end);
fft_population_post_null = fft_population_post_null(:, :, 2:end);
fft_population_pre_null  = fft_population_pre_null(:, :, 2:end);

gain_neuron_post = computeGain(fft_neuron_post, fft_neuron_post_null);
gain_neuron_pre  = computeGain(fft_neuron_pre,  fft_neuron_pre_null);
gain_population_post = computeGain(fft_population_post, fft_population_post_null);
gain_population_pre  = computeGain(fft_population_pre,  fft_population_pre_null);
%% fft plots

CI_level = 98;
% === Plot Neuron FFTs with Percentile CI ===
fig1 = figure('Name', 'Neuron FFTs with Percentile CI'); hold on;
fill_between_sem(f, fft_neuron_post, [0 0.6 1], 'Post', CI_level, '-');
fill_between_sem(f, reshape(fft_neuron_post_null, [], size(fft_neuron_post_null,3)), [0.6 0.8 1], 'Post Surrogate', CI_level, '--');

fill_between_sem(f, fft_neuron_pre, [1 0.4 0.4], 'Pre', CI_level, '-');
fill_between_sem(f, reshape(fft_neuron_pre_null, [], size(fft_neuron_pre_null,3)), [1 0.7 0.7], 'Pre Surrogate', CI_level, '--');

set(gca, 'XScale', 'log', 'YScale', 'log'); grid on;
xlabel('Frequency (Hz)'); ylabel('Power');
legend(Location="best"); title('Neuron FFT');
xlim([1, 100]);

% === Plot Population FFTs with Percentile CI ===
fig2 = figure('Name', 'Population FFTs with Percentile CI'); hold on;
fill_between_sem(f, fft_population_post, [0 0.6 1], 'Post', CI_level, '-');
fill_between_sem(f, reshape(fft_population_post_null, [], size(fft_population_post_null,3)), [0.6 0.8 1], 'Post Surrogate', CI_level, '--');

fill_between_sem(f, fft_population_pre, [1 0.4 0.4], 'Pre', CI_level, '-');
fill_between_sem(f, reshape(fft_population_pre_null, [], size(fft_population_pre_null,3)), [1 0.7 0.7], 'Pre Surrogate', CI_level, '--');

set(gca, 'XScale', 'log', 'YScale', 'log'); grid on;
xlabel('Frequency (Hz)'); ylabel('Power');
legend(Location="best"); title('Population FFT');
xlim([1, 100]);

%% gain plots

CI_level = 98;
% === Plot Neuron FFTs with Percentile CI ===
fig3 = figure('Name', 'Neuron FFTs with Percentile CI'); hold on;
fill_between_sem(f, gain_neuron_post, [0 0.6 1], 'Post', CI_level, '-');
fill_between_sem(f, gain_neuron_pre, [1 0.7 0.7], 'Pre', CI_level, '-');
yline(1, 'k--', HandleVisibility='off');

set(gca, 'XScale', 'log', 'YScale', 'log'); grid on;
xlabel('Frequency (Hz)'); ylabel('Gain');
legend(Location="best"); title('Neuron FFT Gain');
xlim([1, 100]);

% === Plot Population FFTs with Percentile CI ===
fig4 = figure('Name', 'Population FFTs with Percentile CI'); hold on;
fill_between_sem(f, fft_population_post./squeeze(mean(fft_population_post_null, [1, 2]))', [0 0.6 1], 'Post', CI_level, '-');
fill_between_sem(f, fft_population_pre./squeeze(mean(fft_population_pre_null, [1, 2]))', [1 0.7 0.7], 'Pre', CI_level, '-');
yline(1, 'k--', HandleVisibility='off');

set(gca, 'XScale', 'log', 'YScale', 'log'); grid on;
xlabel('Frequency (Hz)'); ylabel('Gain');
legend(Location="best"); title('Population FFT Gain');
xlim([1, 100]);

%% Save Results

output_folder = fullfile('Results');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% === Save Neuron FFT ===
save_fig(fig1, "NeuronFFT", output_folder);

% === Save Population FFT ===
save_fig(fig2, "PopulationFFT", output_folder);

% === Save Neuron Gain ===
save_fig(fig3, "NeuronFFT_Gain", output_folder);

% === Save Population Gain ===
save_fig(fig4, "PopulationFFT_Gain", output_folder);


%% === Utility Function ===

function fill_between_percentile(x, data_mat, color, label, ci_level, ls)
    % Smoothed percentile CI bands with downsampled fill for speed

    % === Parameters ===
    smoothing_window = 100;
    max_fill_points = 300;  % max number of points used for the fill
    alpha = 100 - ci_level;
    low_pct = alpha / 2;
    high_pct = 100 - low_pct;

    % === Compute percentiles ===
    lower = prctile(data_mat, low_pct, 1);
    upper = prctile(data_mat, high_pct, 1);
    mean_trace = mean(data_mat, 1);

    % === Smooth ===
    lower = smoothdata(lower, 'gaussian', smoothing_window);
    upper = smoothdata(upper, 'gaussian', smoothing_window);
    mean_trace = smoothdata(mean_trace, 'gaussian', smoothing_window);

    % === Downsample for fill ===
    n = numel(x);
    if n > max_fill_points
        step = ceil(n / max_fill_points);
        idx = 1:step:n;
    else
        idx = 1:n;
    end

    x_ds = x(idx);
    upper_ds = upper(idx);
    lower_ds = lower(idx);

    % === Shaded CI region (downsampled) ===
    fill([x_ds, fliplr(x_ds)], [upper_ds, fliplr(lower_ds)], color, ...
        'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
        'DisplayName', [label ' ' num2str(ci_level) '% CI'], HandleVisibility='off');

    % === Full-resolution median line ===
    plot(x, mean_trace, '-', 'Color', color, 'LineWidth', 1.5, 'DisplayName', label, 'LineStyle', ls);
end

function fill_between_sem(x, data_mat, color, label, ci_level, ls)
    % Draws fill using SEM-based confidence interval (mean ± z * SEM)
    % with optional smoothing and downsampled fill

    % === Parameters ===
    smoothing_window = 500;
    max_fill_points = 5000;  % number of points used in fill
    z = norminv(0.5 + ci_level / 200);  % e.g., 1.96 for 95% CI

    % === Compute mean and SEM ===
    mean_trace = mean(data_mat, 1);
    sem_trace = std(data_mat, 0, 1) / sqrt(size(data_mat, 1));

    % === Compute bounds ===
    upper = mean_trace + z * sem_trace;
    lower = mean_trace - z * sem_trace;

    % === Smooth ===
    mean_trace = smoothdata(mean_trace, 'gaussian', smoothing_window);
    upper = smoothdata(upper, 'gaussian', smoothing_window);
    lower = smoothdata(lower, 'gaussian', smoothing_window);

    % === Downsample for fill ===
    n = numel(x);
    if n > max_fill_points
        step = ceil(n / max_fill_points);
        idx = 1:step:n;
    else
        idx = 1:n;
    end
    x_ds = x(idx);
    upper_ds = upper(idx);
    lower_ds = lower(idx);

    % === Plot shaded CI band ===
    fill([x_ds, fliplr(x_ds)], [upper_ds, fliplr(lower_ds)], color, ...
        'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
        'DisplayName', [label ' ' num2str(ci_level) '% CI'], HandleVisibility='off');

    % === Plot central curve ===
    plot(x, mean_trace, '-', 'Color', color, 'LineWidth', 1.5, 'DisplayName', label, 'LineStyle', ls);
end

function C = computeGain(A, B)
    % A: [nA × d]
    % B: [nA × nB × d]
    % Output: [nA*nB × d] where each row is A(i,:) ./ B(i,j,:)

    [nA, d] = size(A);
    [nA_B, nB, d_B] = size(B);
    
    assert(nA == nA_B, 'A and B must have the same nA');
    assert(d == d_B, 'A and B must have the same feature dimension');

    % Expand A: [nA × 1 × d] → [nA × nB × d]
    A_exp = repmat(reshape(A, [nA 1 d]), [1 nB 1]);

    % Element-wise division
    C = A_exp ./ B;  % [nA × nB × d]

    % Reshape to 2D: [nA*nB × d]
    C = reshape(C, [], d);
end

function save_fig(fig_handle, name, output_folder)
    exportgraphics(fig_handle, fullfile(output_folder, name + ".pdf"), 'ContentType', 'vector');
    exportgraphics(fig_handle, fullfile(output_folder, name + ".png"), 'ContentType', 'image');
end
