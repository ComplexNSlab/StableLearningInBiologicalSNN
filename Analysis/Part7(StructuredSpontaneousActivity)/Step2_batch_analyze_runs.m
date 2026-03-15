%% ========== Updated Data Preprocessing with Surrogates ==========

clear; clc;
% Parameters
bin_size = 1;  % ms
N = 400; Time_duration = 500*1000;
noise_strength = 1;

% Path setup
sim_path = fullfile("Data", "N" + N, "noise" + num2str(round(noise_strength*100)) + "%");
folders = dir(sim_path);
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

fprintf('📊 Starting batch analysis of %d simulations for N=%d, noise=%.2f...\n', length(folders), N, noise_strength);

% Initialize storage
fft_population_pre = [];
fft_population_post = [];
fft_neuron_pre = [];
fft_neuron_post = [];

for k = 1:length(folders)
    matfile = fullfile(folders(k).folder, folders(k).name, "InitialWorkSpace.mat");
    if ~isfile(matfile)
        fprintf("⏭ Skipping %s\n", folders(k).name); continue;
    end

    fprintf('→ [%d/%d] %s\n', k, length(folders), folders(k).name);
    S = load(matfile);
    raster_pre = utils.getRasterPlot(S.firings_pre, bin_size, Time_duration);
    raster_post = utils.getRasterPlot(S.firings_post, bin_size, Time_duration);

    % Population signals
    pop_pre = mean(raster_pre, 1) - mean(raster_pre, 'all');
    pop_post = mean(raster_post, 1) - mean(raster_post, 'all');
    fft_pop_pre = abs(fft(pop_pre)).^2;
    fft_pop_post = abs(fft(pop_post)).^2;

    % Per-neuron spectra
    fft_neur_pre = mean(abs(fft(raster_pre - mean(raster_pre,2), [], 2)).^2, 1);
    fft_neur_post = mean(abs(fft(raster_post - mean(raster_post,2), [], 2)).^2, 1);

    fft_population_pre(end+1,:) = fft_pop_pre;
    fft_population_post(end+1,:) = fft_pop_post;
    fft_neuron_pre(end+1,:) = fft_neur_pre;
    fft_neuron_post(end+1,:) = fft_neur_post;
end

% Save everything
fprintf('💾 Saving aggregated results...\n');
save(fullfile(sim_path, "fft_results.mat"), ...
    'fft_population_pre', 'fft_population_post', ...
    'fft_neuron_pre', 'fft_neuron_post', ...
    'bin_size', 'N', 'noise_strength');

fprintf('✅ Done! Results saved to AllResults.mat\n');
