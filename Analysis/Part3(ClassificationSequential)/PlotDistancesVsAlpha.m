clc; clear;

load('C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part3(ClassificationSequential)\Data\N400\nMems25\distancesDataSet.mat')

% Assuming 'dictionary' is already loaded in the workspace
% Step 1: Extract and sort keys
alphas = cell2mat(dictionary.keys);         % Convert cell to array
[alphas_sorted, idx] = sort(alphas);        % Sort keys
% Step 2: Initialize matrix to hold mean distances
% Rows: groups (5), Columns: α values
n_groups = 5;
mean_distances = zeros(n_groups, length(alphas_sorted));
% Step 3: Extract mean values from each 5x3 matrix
for i = 1:length(alphas_sorted)
    alpha_val = alphas_sorted(i);
    summary_matrix = dictionary(alpha_val);   % 5×3 matrix
    mean_distances(:, i) = summary_matrix(:, 1);  % Take mean column
end
% Step 4: Plot
group_labels = ["Intra: m", "Intra: rnd", ...
"Inter: m vs m", "Inter: m vs rnd", "Inter: rnd vs rnd"];
figure;
hold on;
for i = 1:n_groups
plot(alphas_sorted, mean_distances(i, :), '-o', 'LineWidth', 2);
end
xlabel('\alpha (Cue Strength)', 'FontSize', 12);
ylabel('Mean Euclidean Distance', 'FontSize', 12);
title('Mean Distance vs. Cue Strength (\alpha)', 'FontSize', 14);
legend(group_labels, 'Location', 'northwest');
grid on;

%%

m_m = mean_distances(4, :)./mean_distances(2, :);

m_rnd = mean_distances(5, :)./mean_distances(2, :);

figure; hold on;
plot(alphas_sorted, m_m, '-o', 'LineWidth', 2, 'DisplayName', 'm vs rnd');
plot(alphas_sorted, m_rnd, '-o', 'LineWidth', 2, 'DisplayName', 'rnd vs rnd');
yline(1, '--k', 'LineWidth', 1, HandleVisibility='off');  % Critical overlap threshold
xlabel('\alpha (Cue Strength)');
ylabel('Inter / Intra Ratio');
title('Normalized Separability of Memory Representations');
legend('Location', 'northeast');
grid on;%%

%%

% Ratios
m_vs_m_norm      = mean_distances(3, :) ./ mean_distances(1, :);
m_vs_rnd_norm    = mean_distances(4, :) ./ mean_distances(1, :);
rnd_vs_rnd_norm  = mean_distances(5, :) ./ mean_distances(1, :);
intra_rnd_norm   = mean_distances(2, :) ./ mean_distances(1, :);  % optional

% Plot
figure; hold on;
plot(alphas_sorted, m_vs_m_norm, '-o', 'LineWidth', 2, 'DisplayName', 'm vs m');
plot(alphas_sorted, m_vs_rnd_norm, '-o', 'LineWidth', 2, 'DisplayName', 'm vs rnd');
plot(alphas_sorted, rnd_vs_rnd_norm, '-o', 'LineWidth', 2, 'DisplayName', 'rnd vs rnd');
plot(alphas_sorted, intra_rnd_norm, '-o', 'LineWidth', 2, 'DisplayName', 'Intra: rnd / m');

% Axis and labels
yline(1, '--k', 'LineWidth', 1, 'DisplayName', 'Boundary = 1');
xlabel('\alpha (Cue Strength)', 'FontSize', 12);
ylabel('Normalized Distance (relative to Intra: m)', 'FontSize', 12);
title('Normalized Distance Ratios vs Cue Strength \alpha', 'FontSize', 14);
legend('Location', 'northeastoutside');
grid on;

