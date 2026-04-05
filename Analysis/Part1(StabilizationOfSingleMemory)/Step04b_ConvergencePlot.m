% Step04b_ConvergencePlot.m
% =========================================================================
% Plots multi-simulation convergence trajectories (median + 80% CI) for
% the three representations: latency, spike count, spike-order correlation.
%
% Loads the convergence curves saved by Step04_PlateauThreshold and
% produces a 3-panel figure suitable for the thesis.
%
% INPUTS:
%   Results/StabilizationResults/{paramTag}/ConvergenceCurves.mat
%
% OUTPUTS:
%   Results/StabilizationResults/{paramTag}/ConvergenceTrajectories.pdf/.png
% =========================================================================

clc; clearvars('-except', 'show_figs', 'runAllPlots__*'); close all;
if ~exist('show_figs', 'var'), show_figs = 'on'; end

%% Load config and locate data
cfg = jsondecode(fileread('config.json'));
paramTag = sprintf('frac%03d_smooth%d_hold%d', ...
    round(cfg.stabilityFrac * 100), cfg.smoothTrials, cfg.holdTrials);
resultsDir = fullfile(pwd, 'Results', 'StabilizationResults', paramTag);

S = load(fullfile(resultsDir, 'ConvergenceCurves.mat'), 'convCurves');
C = S.convCurves;

%% Settings
CI = 80;
ci_lo = (100 - CI) / 2;
ci_hi = (100 + CI) / 2;

colors_median = {[0.2 0.3 0.8], [0.8 0.2 0.2], [0.1 0.6 0.1]};
colors_ci     = {[0.6 0.7 1],   [1 0.6 0.6],   [0.6 0.9 0.6]};
gray_alpha    = [0.5 0.5 0.5 0.08];

panels  = {C.Y_delay, C.Y_spike, C.Y_order};
ylabels = {'Mean Latency (ms)', 'Mean Spike Count', 'Spearman $\rho$'};
titles  = {'First-Spike Latency', 'Spike Count', 'First-Spike Order'};

%% Plot
fig = figure('Units', 'inches', 'Position', [1 1 8 7], 'Visible', show_figs);
tl = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for p = 1:3
    nexttile; hold on;
    Y = panels{p};
    nRuns = size(Y, 1);
    nT    = size(Y, 2);
    x     = 1:nT;

    % CI band
    lo = prctile(Y, ci_lo);
    hi = prctile(Y, ci_hi);
    fill([x, fliplr(x)], [hi, fliplr(lo)], ...
        colors_ci{p}, 'EdgeColor', 'none', 'FaceAlpha', 0.5, ...
        'DisplayName', [num2str(CI) '\% CI']);

    % Individual runs (faint)
    for r = 1:nRuns
        plot(x, Y(r,:), 'Color', gray_alpha, 'LineWidth', 0.4, 'HandleVisibility', 'off');
    end

    % Median
    plot(x, median(Y, 1, 'omitnan'), 'Color', colors_median{p}, ...
        'LineWidth', 2, 'DisplayName', 'Median');

    ylabel(ylabels{p});
    title(titles{p});
    legend('Location', 'best', 'Box', 'off');
    xlim([1 nT]);
end
xlabel(tl, 'Trial');

%% Save
exportgraphics(fig, fullfile(resultsDir, 'ConvergenceTrajectories.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'none');
print(fig, fullfile(resultsDir, 'ConvergenceTrajectories'), '-dpng', '-r300');
fprintf('Saved to:\n%s\n', fullfile(resultsDir, 'ConvergenceTrajectories.pdf'));
