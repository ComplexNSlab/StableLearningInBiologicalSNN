clear; clc;
load("Data\Scaled50\FitResults.mat")
savePath = fullfile("Results/Scaled50/");

Nlist = [100, 200, 400, 800, 1600];

% Initialize containers
jumps1_all = {};
jumps2_all = {}; 

b1 = zeros(size(Nlist));
b2 = zeros(size(Nlist));
b3 = zeros(size(Nlist));

ci1 = zeros(numel(Nlist), 2);  % [lower, upper]
ci2 = zeros(numel(Nlist), 2);
ci3 = zeros(numel(Nlist), 2);

for i = 1:numel(Nlist)
    N = Nlist(i);
    fname = sprintf('N%d', N);

    % Extract jumps
    jumps1_all{i} = results.(fname).jumps1(:);  % ensure column
    jumps2_all{i} = results.(fname).jumps2(:);  % ensure column


    % Extract fitted slope 'b' and its confidence interval
    f1 = results.(fname).f1;
    f2 = results.(fname).f2;
    f3 = results.(fname).f3;

    b1(i) = f1.b;
    b2(i) = f2.b;
    b3(i) = f3.b;

    ci = confint(f1);
    ci1(i, :) = ci(:, strcmp(coeffnames(f1), 'b'))';

    ci = confint(f2);
    ci2(i, :) = ci(:, strcmp(coeffnames(f2), 'b'))';

    ci = confint(f3);
    ci3(i, :) = ci(:, strcmp(coeffnames(f3), 'b'))';
end

%% Font and line settings
fs = 20;         % Font size
lw = 2;          % Line width
ms = 6;          % Marker size

% Prepare data
jumps1_values = cell2mat(jumps1_all');  % All data points
jumps1_groups = categorical(repelem(Nlist, cellfun(@numel, jumps1_all))');  % Corresponding N values
jumps2_values = cell2mat(jumps2_all');  % All data points
jumps2_groups = categorical(repelem(Nlist, cellfun(@numel, jumps2_all))');  % Corresponding N values

%% -----------------------------
% Plot: Boxplot with Swarmchart
% -----------------------------
figure('Color','w', 'Position', [100, 100, 600, 500]);

% Boxplot
% boxchart(jumps1_groups, jumps1_values);
violinplot(jumps1_groups, jumps1_values);

% Hold and overlay swarmchart
hold on;
swarmchart(jumps1_groups, jumps1_values, ms, 'k', 'filled', ...
    'XJitter', 'density', 'XJitterWidth', 0.8, 'MarkerFaceAlpha', 0.3);

% Get unique group labels and counts
[group_names, ~, group_idx] = unique(jumps1_groups, 'stable');
num_groups = numel(group_names);

% Loop through each group and annotate count
for i = 1:num_groups
    this_group = (group_idx == i);
    x_pos = i;
    y_max = max(jumps1_values(this_group));

    % Add text slightly above y_max
    text(x_pos, y_max + 0.04 * range(jumps1_values), ...
        sprintf('n = %d', sum(this_group)/21), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'Rotation', 0, ...
        'FontSize', fs * 0.7);
end

% Axis labels
xlabel('$N$', 'Interpreter', 'latex', 'FontSize', fs);
ylabel('$\Delta\, \mathrm{delay}$ (ms)', 'Interpreter', 'latex', 'FontSize', fs);
title('$\Delta\, \mathrm{delay}$ vs $N$', 'Interpreter', 'latex', 'FontSize', fs);

% Aesthetics
set(gca, ...
    'FontSize', fs, ...
    'LineWidth', lw, ...
    'TickDir', 'out', ...
    'Box', 'off', ...
    'XTickLabelRotation', 0);


% set(gcf, 'PaperPositionMode', 'auto');
% %Save high-resolution PNG
% print(gcf, fullfile(savePath, "delays_drop"), '-dpng', '-r600');
% 
% %Save high-quality PDF
% print(gcf, fullfile(savePath, "delays_drop"), '-dpdf', '-bestfit');

exportgraphics(gcf, fullfile(savePath, "delays_drop.pdf"), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');
exportgraphics(gcf, fullfile(savePath, "delays_drop.png"), ...
    'Resolution', 600, 'BackgroundColor', 'white');

%% -----------------------------
% Plot 2: Boxplot of jumps2
% -----------------------------
figure('Color','w', 'Position', [100, 100, 600, 500]);

% Boxplot
% boxchart(jumps2_groups, jumps2_values);
violinplot(jumps2_groups, 100*jumps2_values);

% Hold and overlay swarmchart
hold on;
swarmchart(jumps2_groups, 100*jumps2_values, ms, 'k', 'filled', ...
    'XJitter', 'density', 'XJitterWidth', 0.8, 'MarkerFaceAlpha', 0.3);

% Get unique group labels and counts
[group_names, ~, group_idx] = unique(jumps2_groups, 'stable');
num_groups = numel(group_names);

% Loop through each group and annotate count
for i = 1:num_groups
    this_group = (group_idx == i);
    x_pos = i;
    y_max = max(100*jumps2_values(this_group));

    % Add text slightly above y_max
    text(x_pos, y_max + 0.04 * range(100*jumps2_values), ...
        sprintf('n = %d', sum(this_group)/21), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'Rotation', 0, ...
        'FontSize', fs * 0.7);
end

% Axis labels
xlabel('$N$', 'Interpreter', 'latex', 'FontSize', fs);
ylabel('Ex Assembly Size Change (\%)', 'Interpreter', 'latex', 'FontSize', fs);
title('Ex Assembly Size Change vs $N$', 'Interpreter', 'latex', 'FontSize', fs);

% Aesthetics
set(gca, ...
    'FontSize', fs, ...
    'LineWidth', lw, ...
    'TickDir', 'out', ...
    'Box', 'off', ...
    'XTickLabelRotation', 0);

% set(gcf, 'PaperPositionMode', 'auto');
% %Save high-resolution PNG
% print(gcf, fullfile(savePath, "assembly_jump"), '-dpng', '-r600');
% 
% %Save high-quality PDF
% print(gcf, fullfile(savePath, "assembly_jump"), '-dpdf', '-bestfit');

exportgraphics(gcf, fullfile(savePath, "assembly_jump.pdf"), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');
exportgraphics(gcf, fullfile(savePath, "assembly_jump.png"), ...
    'Resolution', 600, 'BackgroundColor', 'white');

%% -----------------------------
% Plot 3: b (slope) vs N with CI using fill
% -----------------------------
figure('Color','w', 'Position', [100, 100, 600, 500]); hold on;

% Compute absolute slopes and CI bounds
tau1 = abs(b1);  % f1 slopes
tau2 = abs(b2);  % f2 slopes
tau3 = abs(b3);  % f2 slopes

ci1_lower = abs(ci1(:, 1)');
ci1_upper = abs(ci1(:, 2)');
ci2_lower = abs(ci2(:, 1)');
ci2_upper = abs(ci2(:, 2)');
ci3_lower = abs(ci3(:, 1)');
ci3_upper = abs(ci3(:, 2)');

% Shaded CI for f1
x_fill = [Nlist, fliplr(Nlist)];
y_fill1 = [ci1_lower, fliplr(ci1_upper)];
fill(x_fill, y_fill1, [0.5 0.5 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');

% Shaded CI for f2
y_fill2 = [ci2_lower, fliplr(ci2_upper)];
fill(x_fill, y_fill2, [1 0.5 0.5], 'FaceAlpha', 0.3, 'EdgeColor', 'none', HandleVisibility='off');

% Shaded CI for f3
y_fill3 = [ci3_lower, fliplr(ci3_upper)];
fill(x_fill, y_fill3, [0.5 1 0.5], 'FaceAlpha', 0.3, 'EdgeColor', 'none', HandleVisibility='off');

% Actual slope lines
plot(Nlist, tau1, 'o--', 'Color', [0 0 1], 'LineWidth', 2, 'DisplayName', 'Delays');
plot(Nlist, tau2, 's--', 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', 'Assembly');
plot(Nlist, tau3, 'h--', 'Color', [0 1 0], 'LineWidth', 2, 'DisplayName', 'Weights');

% Labels and title
xlabel('$N$', 'Interpreter', 'latex', 'FontSize', fs);
ylabel('$m_0$ (\# of new memories)', 'Interpreter', 'latex', 'FontSize', fs);
title('Decay Scale Vs. Network Size', 'Interpreter', 'latex', 'FontSize', fs);
legend('Location', 'best', 'FontSize', fs*0.5, 'Box','off');

% Axes settings
set(gca, ...
    'FontSize', fs, ...
    'LineWidth', 1.5, ...
    'TickDir', 'out', ...
    'XScale', 'log');

xticks(Nlist)
xlim([90, 2000]);
grid on;

% set(gcf, 'PaperPositionMode', 'auto');
% %Save high-resolution PNG
% print(gcf, fullfile(savePath, "decay_time_scale"), '-dpng', '-r600');
% 
% %Save high-quality PDF
% print(gcf, fullfile(savePath, "decay_time_scale"), '-dpdf', '-bestfit');

exportgraphics(gcf, fullfile(savePath, "decay_time_scale.pdf"), ...
    'ContentType', 'vector', 'BackgroundColor', 'none');
exportgraphics(gcf, fullfile(savePath, "decay_time_scale.png"), ...
    'Resolution', 600, 'BackgroundColor', 'white');
