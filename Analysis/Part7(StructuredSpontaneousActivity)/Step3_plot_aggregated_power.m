clear; clc;

% --------- Load Data ---------
N = 400; noise_strength = 1;
filepath = fullfile("Data", "N" + N, "noise" + num2str(round(100 * noise_strength)) + "%", "AllResults.mat");
load(filepath, 'fft_pre_avg_all', 'fft_post_avg_all', ...
              'mean_fft_pre_all', 'mean_fft_post_all', ...
              'bin_size');

%% --------- Parameters ---------
Fs = 1000 / bin_size;
smoothing_window = 100;
trim_tail = 0;
f_lim = 500;
Xscale = 'linear';
db = true;

n_sim = size(fft_pre_avg_all, 1);
Nf = size(fft_pre_avg_all, 2);
N_half = ceil(Nf/2);
f = Fs * (0:N_half-1) / Nf;
max_idx = find(f>f_lim, 1);

signal_population_pre = fft_pre_avg_all(:, 1:N_half); clear fft_pre_avg_all;
signal_population_post = fft_post_avg_all(:, 1:N_half); clear fft_post_avg_all;
signal_perNeuron_pre = mean_fft_pre_all(:, 1:N_half); clear mean_fft_pre_all;
signal_perNeuron_post = mean_fft_post_all(:, 1:N_half); clear mean_fft_post_all;

if ~isempty(max_idx)
    signal_perNeuron_pre = signal_perNeuron_pre(:, 1:max_idx);
    signal_perNeuron_post = signal_perNeuron_post(:, 1:max_idx);
    signal_population_pre = signal_population_pre(:, 1:max_idx);
    signal_population_post = signal_population_post(:, 1:max_idx);
    f = f(1:max_idx);
end
%% --------- Helper Function ---------
fill_between = @(x, y, err, color) ...
    fill([x, fliplr(x)], [y+err, fliplr(y-err)], color, ...
         'FaceAlpha', 0.25, 'EdgeColor', 'none', HandleVisibility='off');

%%
signal = mean(signal_perNeuron_pre, 1);
smoothing_window = 1/(f(2)-f(1));

% Compute moving mean and std
mean_signal = movmean(signal, smoothing_window);
std_signal = movstd(signal, smoothing_window);

% Upper and lower bounds
upper = mean_signal + std_signal;
lower = mean_signal - std_signal;

% Null signal
null_signal = signal(randperm(length(signal)));

% Plot
% figure; hold on;
% fill([f fliplr(f)], [upper fliplr(lower)], [0.8 0.8 1], 'FaceAlpha', 1, 'EdgeColor', 'none');
plot(f, signal, 'k.', MarkerSize=1, MarkerFaceColor=0.2*[1 1 1]); % Raw signal
plot(f, mean_signal, 'b', 'LineWidth', 2); % Moving mean
xlabel('frequency'); ylabel('Signal');
% legend('Mean ± STD','Moving Mean');
title('Signal with Moving Mean and STD');

%%

% %% ========== FIGURE 1: Population Power Spectrum ==========
% all_pre = fft_pre_avg_all(:, 1:Nf);
% all_post = fft_post_avg_all(:, 1:Nf);
% 
% if db 
%     all_pre_db = 10 * log10(movmean(all_pre, smoothing_window, 2) + eps);
%     all_post_db = 10 * log10(movmean(all_post, smoothing_window, 2) + eps);
%     Yscale = 'linear';
% else
%     all_pre_db = all_pre;
%     all_post_db = all_post;
%     Yscale = 'log';
% end
% 
% mean_pre = mean(all_pre_db, 1);
% sem_pre = std(all_pre_db, 0, 1);
% mean_post = mean(all_post_db, 1);
% sem_post = std(all_post_db, 0, 1);
% 
% figure('Name', 'Population Power Spectrum with SEM', 'Position', [100 100 1200 600]); hold on;
% fill_between(f(valid_idx), mean_pre(valid_idx), sem_pre(valid_idx), [0.6 0.6 1]);
% fill_between(f(valid_idx), mean_post(valid_idx), sem_post(valid_idx), [1 0.6 0.6]);
% plot(f(valid_idx), mean_pre(valid_idx), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Pre-Learning');
% plot(f(valid_idx), mean_post(valid_idx), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Post-Learning');
% xlabel('Frequency (Hz)'); 
% if db 
%     ylabel('Power (dB)');
% else
%     ylabel('Power');
% end
% legend('Location', 'northeast'); grid on; xlim([0 f_lim]);
% title('Population Power Spectrum (Avg → FFT)');
% set(gca, 'XScale', Xscale, 'YScale', Yscale);
% 
% %% ========== FIGURE 2: Population Relative Gain ==========
% ratio_raw = fft_post_avg_all(:, 1:Nf) ./ (fft_pre_avg_all(:, 1:Nf) + eps);
% ratio_smooth = movmean(ratio_raw, smoothing_window, 2);
% gain_rel = ratio_smooth - 1;
% mean_rel = mean(gain_rel, 1);
% sem_rel = std(gain_rel, 0, 1) / sqrt(n_sim);
% 
% figure('Name', 'Population Relative Power', 'Position', [100 100 1200 600]); hold on;
% fill_between(f(valid_idx), mean_rel(valid_idx), sem_rel(valid_idx), [0.7 0.7 0.7]);
% plot(f(valid_idx), mean_rel(valid_idx), 'k-', 'LineWidth', 2);
% xlabel('Frequency (Hz)'); ylabel('$P^{\mathrm{post}}/P^{\mathrm{pre}} - 1$', 'Interpreter', 'latex');
% yline(0, '--', 'Baseline'); title('Learning-Induced Gain (Population)');
% grid on; xlim([0 f_lim]);
% set(gca, 'XScale', Xscale, 'YScale', Yscale);
% 
% %% ========== FIGURE 3: Per-Neuron Power Spectrum ==========
% all_pre = mean_fft_pre_all(:, 1:Nf);
% all_post = mean_fft_post_all(:, 1:Nf);
% 
% all_pre_db = 10 * log10(movmean(all_pre, smoothing_window, 2) + eps);
% all_post_db = 10 * log10(movmean(all_post, smoothing_window, 2) + eps);
% 
% mean_pre = mean(all_pre_db, 1);
% sem_pre = std(all_pre_db, 0, 1) / sqrt(n_sim);
% mean_post = mean(all_post_db, 1);
% sem_post = std(all_post_db, 0, 1) / sqrt(n_sim);
% 
% figure('Name', 'Per-Neuron Power Spectrum with SEM', 'Position', [100 100 1200 600]); hold on;
% fill_between(f(valid_idx), mean_pre(valid_idx), sem_pre(valid_idx), [0.6 0.6 1]);
% fill_between(f(valid_idx), mean_post(valid_idx), sem_post(valid_idx), [1 0.6 0.6]);
% plot(f(valid_idx), mean_pre(valid_idx), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Pre-Learning');
% plot(f(valid_idx), mean_post(valid_idx), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Post-Learning');
% xlabel('Frequency (Hz)'); ylabel('Power (dB)');
% legend('Location', 'northeast'); grid on; xlim([0 f_lim]);
% title('Per-Neuron Power Spectrum (FFT → Avg)');
% set(gca, 'XScale', Xscale, 'YScale', 'linear');
% 
% %% ========== FIGURE 4: Per-Neuron Relative Gain ==========
% ratio_raw = mean_fft_post_all(:, 1:Nf) ./ mean_fft_pre_all(:, 1:Nf);
% ratio_smooth = movmean(ratio_raw, smoothing_window, 2);
% gain_rel = ratio_smooth - 1;
% mean_rel = mean(gain_rel, 1);
% sem_rel = std(gain_rel, 0, 1) / sqrt(n_sim);
% 
% figure('Name', 'Per-Neuron Relative Power', 'Position', [100 100 1200 600]); hold on;
% fill_between(f(valid_idx), mean_rel(valid_idx), sem_rel(valid_idx), [0.7 0.7 0.7]);
% plot(f(valid_idx), mean_rel(valid_idx), 'k-', 'LineWidth', 2);
% xlabel('Frequency (Hz)'); ylabel('$P^{\mathrm{post}}/P^{\mathrm{pre}} - 1$', 'Interpreter', 'latex');
% yline(0, '--', 'Baseline'); title('Learning-Induced Gain (Per-Neuron)');
% grid on; xlim([0 f_lim]);
% set(gca, 'XScale', Xscale, 'YScale', Yscale);
% %%
% 
% 
% figure; hold on;
% plot(f, mean(fft_post_avg_all(:, 1:N_half), 1)./mean(fft_pre_avg_all(:, 1:N_half), 1));
% plot(f, movmean(mean(fft_post_avg_all(:, 1:N_half), 1)./mean(fft_pre_avg_all(:, 1:N_half), 1), 200), LineWidth = 4);
% xlim([0 100])
% 
% 
% %%
% figure; hold on;
% plot(f, 20 * mean(mean_fft_post_all(:, 1:N_half), 1)./mean(mean_fft_pre_all(:, 1:N_half), 1));
% plot(f, 20*movmean(mean(mean_fft_post_all(:, 1:N_half), 1)./mean(mean_fft_pre_all(:, 1:N_half), 1), 200), LineWidth = 4);
% xlim([0 100])