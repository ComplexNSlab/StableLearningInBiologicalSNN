%% ========== Base Raster Setup ==========
clc; clear;
bin_size = 1;  % ms
n_surrogates = 20;

load('C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part7(StructuredSpontaneousActivity)\Data\N400\noise100%\Jul_25_2025_18_32_49\InitialWorkSpace.mat')
raster_pre = utils.getRasterPlot(firings_pre, bin_size);
raster_post = utils.getRasterPlot(firings_post, bin_size);

raster_pre = raster_pre - mean(raster_pre, 2);
raster_post = raster_post - mean(raster_post, 2);

%% ========== Signal FFT ==========
pre_fft = mean(abs(fft(raster_pre, [], 2)).^2, 1);
post_fft = mean(abs(fft(raster_post, [], 2)).^2, 1);
pre_fft(1) = 0; post_fft(1) = 0;

%% ========== Generate Surrogate Spectra ==========
N = size(raster_post, 2);
sur_pre = zeros(n_surrogates, N);
sur_post = zeros(n_surrogates, N);

fprintf('🔁 Generating %d surrogate spectra...\n', n_surrogates);
for s = 1:n_surrogates
    fprintf('   → Surrogate %d/%d\n', s, n_surrogates);
    rp_pre = fast_row_shuffle(raster_pre);
    rp_post = fast_row_shuffle(raster_post);
    sur_pre(s,:)  = mean(abs(fft(rp_pre, [], 2)).^2, 1);
    sur_post(s,:) = mean(abs(fft(rp_post, [], 2)).^2, 1);
end

sur_pre(:,1) = 0;  % remove DC
sur_post(:,1) = 0;

% Half-spectrum
f = (0:floor(N/2)) * (1000 / bin_size) / N;
pre_fft_half = pre_fft(1:length(f));
post_fft_half = post_fft(1:length(f));
sur_pre_half = sur_pre(:, 1:length(f));
sur_post_half = sur_post(:, 1:length(f));

%% ========== Compute CI bounds ==========
ci_pre = prctile(sur_pre_half, [2.5 97.5], 1);  % 2xF
mean_pre_null = mean(sur_pre_half, 1);

ci_post = prctile(sur_post_half, [2.5 97.5], 1);
mean_post_null = mean(sur_post_half, 1);

%% ========== Plot Spectra with CI ==========
fig = figure; hold on;
smoothing_window = 300;

% Plot CIs as shaded area
fill([f(2:end), fliplr(f(2:end))], ...
     10*log10([ci_post(1,2:end), fliplr(ci_post(2,2:end))]), ...
     [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.6, HandleVisibility='off');
fill([f(2:end), fliplr(f(2:end))], ...
     10*log10([ci_pre(1,2:end), fliplr(ci_pre(2,2:end))]), ...
     [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.6, HandleVisibility='off');

% Plot means
plot(f, 10*log10(smoothdata(post_fft_half, "gaussian", smoothing_window)), 'r-', 'DisplayName', 'Post');
plot(f, 10*log10(smoothdata(mean_post_null, "gaussian", smoothing_window)), 'r--', 'DisplayName', 'Post Null (mean)');
plot(f, 10*log10(smoothdata(pre_fft_half, "gaussian", smoothing_window)), 'b-', 'DisplayName', 'Pre');
plot(f, 10*log10(smoothdata(mean_pre_null, "gaussian", smoothing_window)), 'b--', 'DisplayName', 'Pre Null (mean)');

xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Signal vs Surrogate Spectra with 95% CI');
legend('show'); grid on;
xlim([1 100]);
% set(gca, 'XScale', 'log');
% exportgraphics(fig, fullfile("Results", "fft_spectra.pdf"), ContentType="vector");
% exportgraphics(fig, fullfile("Results", "fft_spectra.png"), ContentType="image");
%% ========== Plot Relative Gain with Shaded Band ==========
rel_gain_post = post_fft_half ./ mean_post_null;
rel_gain_pre  = pre_fft_half ./ mean_pre_null;

fig = figure; hold on;
plot(f, smoothdata(rel_gain_post, "gaussian", smoothing_window), 'r-', 'DisplayName', 'Post / Null');
plot(f, smoothdata(rel_gain_pre, "gaussian", smoothing_window), 'b-', 'DisplayName', 'Pre / Null');

% Optional: CI band for post
rel_ci_low  = post_fft_half ./ ci_post(2,:);  % conservative
rel_ci_high = post_fft_half ./ ci_post(1,:);  % optimistic

fill([f(2:end), fliplr(f(2:end))], ...
     [smoothdata(rel_ci_low(2:end), "gaussian", smoothing_window), ...
      fliplr(smoothdata(rel_ci_high(2:end), "gaussian", smoothing_window))], ...
     [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.6, HandleVisibility='off');

% CI band for pre
rel_ci_low_pre  = pre_fft_half ./ ci_pre(2,:);  % conservative
rel_ci_high_pre = pre_fft_half ./ ci_pre(1,:);  % optimistic

fill([f(2:end), fliplr(f(2:end))], ...
     [smoothdata(rel_ci_low_pre(2:end), "gaussian", smoothing_window), ...
      fliplr(smoothdata(rel_ci_high_pre(2:end), "gaussian", smoothing_window))], ...
     [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.6, HandleVisibility='off');

yline(1, '--k', 'DisplayName', 'No Gain');
xlabel('Frequency (Hz)');
ylabel('Relative Power (Signal / Null)');
title('Relative Spectral Gain with Surrogate CI');
legend('show'); grid on;
set(gca, 'XScale', 'log');
xlim([1 500]);
exportgraphics(fig, fullfile("Results", "relativeGain.pdf"), ContentType="vector");
exportgraphics(fig, fullfile("Results", "relativeGain.png"), ContentType="image");

%% functions
function B = fast_row_shuffle(A)
    [M, N] = size(A);
    [~, idx] = sort(rand(M, N), 2);                    % random column indices for each row
    row_idx = repmat((1:M)', 1, N);                    % corresponding row indices
    B = A(sub2ind([M, N], row_idx(:), idx(:)));        % linear indexing
    B = reshape(B, M, N);                              % restore original shape
end