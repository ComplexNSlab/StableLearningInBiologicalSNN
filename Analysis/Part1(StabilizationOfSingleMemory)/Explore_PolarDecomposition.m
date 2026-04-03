% Test_PolarDecomposition.m
% =========================================================================
% Polar decomposition of the synaptic weight trajectory.
%
% The full weight vector g(t) in R^{nSyn} changes each trial. This script
% decomposes that change into two independent components:
%   - Radial   Delta_r(t)     = ||g(t+1)|| - ||g(t)||
%     How much the total synaptic strength grows or shrinks.
%   - Angular  Delta_theta(t) = arccos( g(t) . g(t+1) / (||g(t)|| ||g(t+1)||) )
%     How much the weight vector rotates (structural reorganisation).
%
% These are compared side-by-side with the existing L1 measure from Step6:
%   Delta_W(t) = mean_i |w_i(t+1) - w_i(t)|
%
% Run on a single simulation for quick visual inspection.
%
% INPUTS:
%   Data/{scaleFolder}/{trialsSubfolder}/N{N}/{simID}/Patch1.mat
% =========================================================================

clear; clc;

%% Load settings from config
cfg = jsondecode(fileread('config.json'));
N = cfg.N;
scaleFolder = cfg.scaleFolder;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

simIdx     = 1;       % which simulation folder to load
saveStride = 5;       % weight snapshots saved every N trials
smoothWin  = 20;      % moving-average window for smoothed curves

%% Load weight data
baseFolder = fullfile(pwd, 'Data', scaleFolder, trialsSubfolder, ['N' num2str(N)]);
items = dir(baseFolder);
items = items([items.isdir]);
items = items(~ismember({items.name}, {'.','..'}));

if isempty(items)
    error('No simulation folders found in %s', baseFolder);
end
if simIdx > numel(items)
    error('simIdx=%d but only %d folders found for N=%d', simIdx, numel(items), N);
end

matFile = fullfile(baseFolder, items(simIdx).name, "Patch1.mat");
fprintf('Loading: %s\n', matFile);
S = load(matFile, 'obj');
obj = S.obj;

W = single(obj.w_save);             % N x N x Tsave
A = logical(obj.Adjacency_matrix);  % N x N
Ne = obj.Ne;

% Restrict to excitatory-to-excitatory (EE) synapses only —
% STDP only modifies EE weights, so EI/IE/II are static noise.
A_ee = false(size(A));
A_ee(1:Ne, 1:Ne) = A(1:Ne, 1:Ne);

[N1, N2, Tsave] = size(W);

% Flatten to [nEdges x Tsave], keep only existing EE synapses
W2 = reshape(W, N1*N2, Tsave);
W2 = W2(A_ee(:), :);
nSyn = size(W2, 1);

if nSyn == 0 || Tsave < 2
    error('No valid EE synapses or fewer than 2 weight snapshots.');
end

fprintf('nSyn (EE only) = %d, Tsave = %d\n', nSyn, Tsave);

%% Compute the three measures

% 1) L1: mean absolute change per synapse (same as Step6_WeightStabilization)
dW_L1 = mean(abs(diff(W2, 1, 2)), 1);   % [1 x (Tsave-1)]

% 2) Radial: change in L2 norm of the weight vector
norms = vecnorm(W2, 2, 1);              % [1 x Tsave]
delta_r = diff(norms);                   % [1 x (Tsave-1)]

% 3) Angular: rotation angle between consecutive weight vectors
dotprods = sum(W2(:, 1:end-1) .* W2(:, 2:end), 1);
norm_prod = norms(1:end-1) .* norms(2:end);
norm_prod(norm_prod == 0) = eps;         % avoid division by zero
cos_theta = dotprods ./ norm_prod;
cos_theta = min(max(cos_theta, -1), 1);  % clamp for numerical safety
delta_theta = acos(cos_theta);           % [1 x (Tsave-1)], radians

%% Smooth all three
dW_L1_s     = movmean(dW_L1, smoothWin);
delta_r_s   = movmean(delta_r, smoothWin);
delta_theta_s = movmean(delta_theta, smoothWin);

%% Trial axis (saved snapshots -> actual trials)
trials = (1:numel(dW_L1)) * saveStride;

%% Plot
figure('Position', [100 100 800 750], 'Color', 'w');

rawAlpha = 0.25;
rawColor = [0.65 0.65 0.65];

% --- Panel 1: L1 (existing measure) ---
ax1 = subplot(3,1,1);
plot(trials, dW_L1, 'Color', [rawColor rawAlpha], 'LineWidth', 0.5); hold on;
plot(trials, dW_L1_s, 'b', 'LineWidth', 2);
ylabel('$\overline{|\Delta w_i|}$', 'Interpreter', 'latex');
title(sprintf('N = %d,  sim = %s', N, items(simIdx).name), 'Interpreter', 'none');
legend('Raw', 'Smoothed', 'Location', 'northeast', 'Box', 'off');
set(gca, 'XTickLabel', []);

% --- Panel 2: Radial (magnitude change) ---
ax2 = subplot(3,1,2);
plot(trials, delta_r, 'Color', [rawColor rawAlpha], 'LineWidth', 0.5); hold on;
plot(trials, delta_r_s, 'r', 'LineWidth', 2);
yline(0, 'k:', 'LineWidth', 0.5, 'HandleVisibility', 'off');
ylabel('$\Delta r(t)$', 'Interpreter', 'latex');
legend('Raw', 'Smoothed', 'Location', 'northeast', 'Box', 'off');
set(gca, 'XTickLabel', []);

% --- Panel 3: Angular (rotation) ---
ax3 = subplot(3,1,3);
plot(trials, rad2deg(delta_theta), 'Color', [rawColor rawAlpha], 'LineWidth', 0.5); hold on;
plot(trials, rad2deg(delta_theta_s), 'Color', [0.1 0.6 0.1], 'LineWidth', 2);
ylabel('$\Delta\theta(t)$ [deg]', 'Interpreter', 'latex');
xlabel('Trial');
legend('Raw', 'Smoothed', 'Location', 'northeast', 'Box', 'off');

% --- Shared formatting ---
linkaxes([ax1 ax2 ax3], 'x');
set([ax1 ax2 ax3], 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'Box', 'off', 'TickDir', 'out');

sgtitle('Polar Decomposition of Synaptic Weight Trajectory', ...
    'FontName', 'Times New Roman', 'FontSize', 14, 'FontWeight', 'bold');
