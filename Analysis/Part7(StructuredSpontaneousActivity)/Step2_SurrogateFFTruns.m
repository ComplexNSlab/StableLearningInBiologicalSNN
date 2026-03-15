%% ========== Surrogate FFT Computation Only ==========

clear; clc;
% Parameters
bin_size = 1;  % ms
N = 400;
Time_duration = 500 * 1000;  % ms
noise_strength = 1;
n_surrogates = 5;

% Path setup
sim_path = fullfile("Data", "N" + N, "noise" + num2str(round(noise_strength * 100)) + "%");
folders = dir(sim_path);
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

fprintf('🎲 Computing surrogate FFTs for %d simulations...\n', length(folders));

% Initialize storage as cell arrays (each sim can vary in length)
fft_population_pre_null = {};
fft_population_post_null = {};
fft_neuron_pre_null = {};
fft_neuron_post_null = {};

for k = 1:length(folders)
    matfile = fullfile(folders(k).folder, folders(k).name, "InitialWorkSpace.mat");
    if ~isfile(matfile)
        fprintf("⏭ Skipping %s\n", folders(k).name); continue;
    end

    fprintf('→ [%d/%d] %s\n', k, length(folders), folders(k).name);
    S = load(matfile);
    raster_pre = utils.getRasterPlot(S.firings_pre, bin_size, Time_duration);
    raster_post = utils.getRasterPlot(S.firings_post, bin_size, Time_duration);

    [n_neurons, T] = size(raster_pre);
    fft_len = T;

    % Preallocate per-sim results
    f_pop_pre_nulls = zeros(n_surrogates, fft_len);
    f_pop_post_nulls = zeros(n_surrogates, fft_len);
    f_neur_pre_nulls = zeros(n_surrogates, fft_len);
    f_neur_post_nulls = zeros(n_surrogates, fft_len);

    for s = 1:n_surrogates
        % --- Population null: same shuffle across all neurons ---
        perm = randperm(T);
        rp_pop_pre = raster_pre(:, perm);
        rp_pop_post = raster_post(:, perm);

        pop_pre_null = mean(rp_pop_pre, 1) - mean(rp_pop_pre, 'all');
        pop_post_null = mean(rp_pop_post, 1) - mean(rp_pop_post, 'all');

        f_pop_pre_nulls(s,:) = abs(fft(pop_pre_null)).^2;
        f_pop_post_nulls(s,:) = abs(fft(pop_post_null)).^2;

        % --- Neuron-wise null: independent shuffle per row ---
        rp_neur_pre = fast_row_shuffle(raster_pre);
        rp_neur_post = fast_row_shuffle(raster_post);

        f_neur_pre_nulls(s,:) = mean(abs(fft(rp_neur_pre - mean(rp_neur_pre, 2), [], 2)).^2, 1);
        f_neur_post_nulls(s,:) = mean(abs(fft(rp_neur_post - mean(rp_neur_post, 2), [], 2)).^2, 1);
    end

    % Store each simulation's results in cell arrays
    fft_population_pre_null{end+1} = f_pop_pre_nulls;
    fft_population_post_null{end+1} = f_pop_post_nulls;
    fft_neuron_pre_null{end+1} = f_neur_pre_nulls;
    fft_neuron_post_null{end+1} = f_neur_post_nulls;
end

% Save
fprintf('💾 Saving surrogate FFTs...\n');
save(fullfile(sim_path, "fft_surrogates.mat"), ...
    'fft_population_pre_null', 'fft_population_post_null', ...
    'fft_neuron_pre_null', 'fft_neuron_post_null', ...
    'bin_size', 'N', 'noise_strength', 'n_surrogates');

fprintf('✅ Surrogate FFTs saved to fft_surrogates.mat\n');

%% ========= Fast row-wise shuffle ==========

function B = fast_row_shuffle(A)
    [M, N] = size(A);
    [~, idx] = sort(rand(M, N), 2);                    % random column indices per row
    row_idx = repmat((1:M)', 1, N);                    % corresponding row indices
    B = A(sub2ind([M, N], row_idx(:), idx(:)));        % linear indexing
    B = reshape(B, M, N);                              % reshape to original size
end
