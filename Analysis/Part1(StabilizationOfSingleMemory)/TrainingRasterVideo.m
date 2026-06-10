% TrainingRasterVideo.m
% =========================================================================
% Animated version of the single-memory training rasters.
%
% This is the video counterpart of TrainingRastersPlots.mlx. That live
% script rendered four static snapshots (trials 1, 200, 400, 1000) of the
% sorted raster; here we keep the identical sorting/colour scheme but sweep
% over EVERY trial and write the frames to an MP4 — the evolving-raster clip
% intended to replace the four images on the defense slide.
%
% Sorting / colour scheme (same as the .mlx):
%   - Neurons are re-indexed by first-spike order within each trial
%     (excitatory 1..Ne, inhibitory Ne+1..N).
%   - orange  x  = a stimulated cell's spike      (stim.pattern_indices)
%   - dark red.  = a neuron's first spike in trial
%   - gray    .  = a repeated (consequent) spike in the trial
%   - black line = excitatory / inhibitory split (Ne + 0.5)
%
% DATA: loads the same run the .mlx used,
%   Data/TrainingProcedure/Jun_16_2025_16_40_49/Patch1.mat   (N = 400)
% which saves the network object as `obj`.
%
% OUTPUT: Results/TrainingRasters/TrainingRaster.mp4
%
% Run from anywhere — paths are resolved relative to this file.
% =========================================================================

clc;clear;

% ----------------------------- knobs ------------------------------------
% (guarded so you can override before running, e.g. `MAX_TRIALS=8; TrainingRasterVideo`)
if ~exist('FRAME_RATE', 'var'); FRAME_RATE = 30;  end   % fps of the output video
if ~exist('TRIAL_STEP', 'var'); TRIAL_STEP = 4;   end   % 1 = every trial; 2 = every other
if ~exist('MAX_TRIALS', 'var'); MAX_TRIALS = 1000; end   % cap number of trials (inf = all)
if ~exist('OUT_NAME',   'var'); OUT_NAME   = 'TrainingRaster3'; end  % output file stem
fsize = 13;     % font size
msize = 22;     % spike marker size (bigger than the .mlx's 15 for video)
% ------------------------------------------------------------------------

% ---- resolve paths relative to this script ----
scriptDir = fileparts(mfilename('fullpath'));
repoRoot  = fileparts(fileparts(scriptDir));          % .../StableLearningInBiologicalSNN
addpath(genpath(fullfile(repoRoot, 'Src')));          % IzhikevichNetwork, Stimulation classes

dataFile = fullfile(scriptDir, 'Data', 'TrainingProcedure', ...
                    'Jun_16_2025_16_40_49', 'Patch1.mat');
assert(isfile(dataFile), 'Patch1.mat not found at:\n  %s', dataFile);

outDir = fullfile(scriptDir, 'Results', 'TrainingRasters');
if ~exist(outDir, 'dir'); mkdir(outDir); end

% ---- load the network object (saved as `obj`) ----
S = load(dataFile);
if     isfield(S, 'obj');   net = S.obj;
elseif isfield(S, 'net');   net = S.net;
elseif isfield(S, 'mynet'); net = S.mynet;
else,  fn = fieldnames(S);  net = S.(fn{1});
end
data     = net.getData();
firings  = transpose(data.firings);     % [Nspikes x 2] : col1 = time (ms), col2 = neuron idx
stim     = net.stims(1);
interval = stim.interval;               % ms per trial (= 100)

total_trials = floor(max(firings(:, 1)) / interval);
total_trials = min(total_trials, MAX_TRIALS);
trial_list   = 1:TRIAL_STEP:total_trials;

% ---- colours (identical to TrainingRastersPlots.mlx) ----
stim_color     = [0.8500 0.3250 0.0980];   % orange  - stimulated cell
first_color    = [0.6350 0.0780 0.1840];   % dark red - first spike
repeated_color = [0.4000 0.4000 0.4000];   % gray    - repeated spike

% ---- video writer ----
writerObj = VideoWriter(fullfile(outDir, OUT_NAME), 'MPEG-4');
writerObj.FrameRate = FRAME_RATE;
writerObj.Quality   = 100;
open(writerObj);

% ---- single reusable figure for uniform frame size ----
fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100 100 720 680]);

fprintf('Rendering %d frames -> %s\n', numel(trial_list), ...
        fullfile(outDir, [OUT_NAME '.mp4']));

refSize = [];   % locked to the first captured frame so every frame matches exactly

for trial_number = trial_list

    % --- spikes in this trial, re-indexed by first-spike order ---
    idx          = (firings(:,1) > (trial_number-1)*interval) & ...
                   (firings(:,1) <=  trial_number   *interval);
    spike_times  = firings(idx, 1) - (trial_number-1)*interval;
    neuron_idx   = firings(idx, 2);

    check_flag   = zeros(1, net.N);
    counter_ex   = 1;
    counter_inh  = net.Ne + 1;
    c_code       = zeros(numel(spike_times), 3);
    sorted_idx   = zeros(numel(spike_times), 1);

    for i = 1:numel(spike_times)
        ni = neuron_idx(i);
        if ni <= net.Ne                               % excitatory
            if check_flag(ni) == 0                    % first spike
                sorted_idx(i) = counter_ex;
                if ismember(ni, stim.pattern_indices)
                    c_code(i,:) = stim_color;
                else
                    c_code(i,:) = first_color;
                end
                check_flag(ni) = counter_ex;
                counter_ex = counter_ex + 1;
            else                                      % repeated spike
                sorted_idx(i) = check_flag(ni);
                c_code(i,:)   = repeated_color;
            end
        else                                          % inhibitory
            if check_flag(ni) == 0
                sorted_idx(i)  = counter_inh;
                c_code(i,:)    = first_color;
                check_flag(ni) = counter_inh;
                counter_inh    = counter_inh + 1;
            else
                sorted_idx(i)  = check_flag(ni);
                c_code(i,:)    = repeated_color;
            end
        end
    end

    % --- draw frame ---
    clf(fig);
    ax = axes('Parent', fig, 'Position', [0.12 0.12 0.78 0.80]);   % wide; small right margin for E/I labels
    hold(ax, 'on');

    % dummy handles so the legend markers are large & readable
    h1 = scatter(ax, nan, nan, 400, first_color,    '.', 'DisplayName', 'first spike');
    h2 = scatter(ax, nan, nan, 400, repeated_color, '.', 'DisplayName', 'consequent spike');
    h3 = scatter(ax, nan, nan, 120, stim_color,     'x', 'DisplayName', 'stimulated spike');

    colors  = [first_color; repeated_color; stim_color];
    markers = {'.', '.', 'x'};
    for i = 1:size(colors, 1)
        sel = ismember(c_code, colors(i,:), 'rows');
        if any(sel)
            scatter(ax, spike_times(sel), sorted_idx(sel), msize, colors(i,:), ...
                    'Marker', markers{i}, 'HandleVisibility', 'off');
        end
    end

    % excitatory / inhibitory split
    plot(ax, [0, 2*interval], (net.Ne + 0.5)*[1 1], 'k-', 'HandleVisibility', 'off');

    xlim(ax, [0, 30]);
    ylim(ax, [0, net.N + 0.5]);
    yticks(ax, [1, 50:50:300, 321, 360, 400]);          % N=400 layout (Ne=320, Ni=80)
    yticklabels(ax, [1, 50:50:300, 1, 40, 80]);
    xlabel(ax, 'time (ms)');
    ylabel(ax, 'sorted neuron index');
    title(ax, sprintf('Trial %d Raster Plot', trial_number), 'FontWeight', 'normal');

    % E / I side labels (text in data coords, robust inside the loop)
    text(ax, 30.7, net.Ne/2,          'Excitatory', 'Rotation', 90, ...
         'HorizontalAlignment', 'center', 'Clipping', 'off', 'FontName', 'Times New Roman', 'FontSize', fsize);
    text(ax, 30.7, net.Ne + net.Ni/2, 'Inhibitory', 'Rotation', 90, ...
         'HorizontalAlignment', 'center', 'Clipping', 'off', 'FontName', 'Times New Roman', 'FontSize', fsize);

    legend(ax, [h1 h2 h3], 'Location', 'northwest', 'Box', 'off', 'FontSize', 0.85*fsize);
    set(ax, 'FontName', 'Times New Roman', 'FontSize', fsize, 'FontWeight', 'normal', ...
            'TickDir', 'out', 'Box', 'off');

    drawnow;
    im = getframe(fig).cdata;
    if isempty(refSize); refSize = [size(im,1), size(im,2)]; end
    writeVideo(writerObj, forceSize(im, refSize));

    if mod(trial_number, 50) == 0 || trial_number == trial_list(end)
        fprintf('  trial %d / %d\n', trial_number, total_trials);
    end
end

close(writerObj);
close(fig);
fprintf('Done: %s\n', fullfile(outDir, [OUT_NAME '.mp4']));

% ------------------------------------------------------------------------
function im = forceSize(im, target)
% Crop or white-pad an RGB frame to exactly target = [rows cols].
    th = target(1); tw = target(2);
    im = im(1:min(size(im,1),th), 1:min(size(im,2),tw), :);   % crop if larger
    [h, w, c] = size(im);
    if h < th; im = cat(1, im, 255*ones(th-h, w, c, 'uint8')); end   % pad rows
    [h, w, c] = size(im);
    if w < tw; im = cat(2, im, 255*ones(h, tw-w, c, 'uint8')); end   % pad cols
end
