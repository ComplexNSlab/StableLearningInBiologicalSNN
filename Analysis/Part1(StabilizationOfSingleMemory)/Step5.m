clear; clc;

file = fullfile("Data", "Scaled50", "SpikeCountsThreshold.mat");
load(file, "thresholds");

Ns = [];
medians = [];
means = [];
p25 = [];
p75 = [];
all_x = [];
all_y = [];

fields = fieldnames(thresholds);

for i = 1:numel(fields)
    Nstr = fields{i};                    % e.g., 'N100'
    N = sscanf(Nstr, 'N%d');             % Extract number
    stab = thresholds.(Nstr);            % Get vector
    stab = stab(~isnan(stab));           % Remove NaNs
    if isempty(stab), continue; end

    Ns(end+1) = N;
    medians(end+1) = median(stab);
    p25(end+1) = prctile(stab, 25);
    p75(end+1) = prctile(stab, 75);
    means(end+1) = mean(stab);

    % For scatter
    all_x = [all_x; repmat(N, numel(stab), 1)];
    all_y = [all_y; stab(:)];
end

% Sort by N
[~, sortIdx] = sort(Ns);
Ns = Ns(sortIdx);
medians = medians(sortIdx);
means = means(sortIdx);
p25 = p25(sortIdx);
p75 = p75(sortIdx);

% Compute counts per N (after NaN removal)
counts = zeros(1, numel(Ns));
for i = 1:numel(Ns)
    fieldName = sprintf('N%d', Ns(i));
    counts(i) = sum(~isnan(thresholds.(fieldName)));
end

% Paper-quality stabilization plot

figure('Units', 'inches', 'Position', [1, 1, 6, 4]); hold on;

% Shaded area: 25th to 75th percentile
fill([Ns, fliplr(Ns)], [p25, fliplr(p75)], ...
     [0.6 0.7 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Median line (blue)
plot(Ns, medians, '-o', ...
    'Color', [0.2 0.4 1], ...
    'LineWidth', 2, ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', [0.2 0.4 1]);

% Mean line (red)
plot(Ns, means, '-s', ...
    'Color', [0.8 0.2 0.2], ...
    'LineWidth', 2, ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', [0.8 0.2 0.2]);

% Scatter individual points
scatter(all_x, all_y, 15, 'k', 'filled', 'MarkerFaceAlpha', 0.3);

% Annotate counts per N
for i = 1:numel(Ns)
    text(Ns(i)+15, p25(i) - 30, sprintf('n = %d', counts(i)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontName', 'Times New Roman', ...
        'Color', [0.2 0.2 0.2], ...
        'Rotation', 90);
end

% Labels
xlabel('Network Size $N$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Stabilization Trial', 'Interpreter', 'latex', 'FontSize', 14);
title('Stabilization Threshold vs Network Size', 'FontSize', 14);

% Axes formatting
ax = gca;
ax.FontSize = 12;
ax.FontName = 'Times New Roman';  % or Helvetica, Computer Modern
ax.Box = 'off';
ax.TickDir = 'out';
ax.LineWidth = 1;
grid off;

% Optional legend
legend({'25–75% CI', 'Median', 'Mean'}, ...
    'Location', 'northwest', ...
    'FontSize', 10, ...
    'Box', 'off');

% Optional: set y-limits
ylim([min(all_y)-50, max(all_y)+50]);
xlim([50 650]);

% Export
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, fullfile('Results', 'StabilizationVsN'), '-dpdf', '-r300');  % Saves as PDF


