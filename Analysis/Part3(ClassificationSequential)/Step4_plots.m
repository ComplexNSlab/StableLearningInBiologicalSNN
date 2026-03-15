% Step4_plots.m  --  Aggregated visualisation of cluster distances.
%
% Loads ClusterDistances.mat files produced by Step3 across all simulation
% folders and generates publication-quality figures:
%   1. Violin plot of aggregated intra-cluster distances per group.
%   2. Heatmap of the mean inter-cluster distance matrix.
%   3. Violin plot comparing intra vs inter distances (Memory and Random).
%   4. Saves a cluster-level distance dictionary
%      (clusterDistanceMatrices.mat) keyed by alpha for downstream
%      separation analyses.
%
% Requires: ClusterDistances.mat per simulation (from Step3)
% Parameters: N, nMems, alpha (set below)

clear; clc;

visible = false;
nMems = 25;
N = 400;
alpha = 0.1;

rootFolder = sprintf("Data\\N%d\\nMems%d\\", N, nMems);
entries = dir(rootFolder);
entries = entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}));

% Initialize aggregation containers
all_intra_values = [];
all_intra_labels = [];

all_inter_values = zeros(2*nMems, 2*nMems, length(entries));

for i = 1:length(entries)
    clusterDistsFile = fullfile(entries(i).folder, entries(i).name, "Recalls", "alpha" + num2str(round(100*alpha)), "ClusterDistances.mat");
    load(clusterDistsFile)  % Loads: intra_dists_all, inter_dists_all, uniqueGroups

    % --- Aggregate Intra Distances ---
    for g = 1:numel(uniqueGroups)
        group_label = string(uniqueGroups{g});
        values = intra_dists_all{g};
        if isempty(values), continue; end
        all_intra_values = [all_intra_values; values(:)];
        all_intra_labels = [all_intra_labels; repmat(group_label, numel(values), 1)];
    end

    % --- Aggregate Inter Distances ---
    mean_inter_mat = cellfun(@(x) mean(x(:), 'omitnan'), inter_dists_all);
    
    % Fill diagonal with intra-cluster means
    for d = 1:numel(intra_dists_all)
        if ~isempty(intra_dists_all{d})
            mean_inter_mat(d,d) = mean(intra_dists_all{d}(:), 'omitnan');
        else
            mean_inter_mat(d,d) = NaN;
        end
    end
    
    all_inter_values(:, :, i) = mean_inter_mat;
end

%% Plot intra cluster distances statistics
% Define desired label order
nMems = 25;
ordered_labels = [ ...
    "m" + string(1:nMems), ...
    "rnd" + string(nMems+1 : 2*nMems)
]';

% Convert to ordered categorical
sorted_labels = categorical(all_intra_labels, ordered_labels, 'Ordinal', true);

% Create figure
figure('Color', 'w', 'Position', [100, 100, 1000, 600], 'Visible', visible);

% Plot violinplot
violinplot(sorted_labels, all_intra_values, 'EdgeColor', 'none'); hold on;

% Optional: add swarmchart overlay for raw data points
% swarmchart(sorted_labels, all_intra_values, 5, 'k', 'filled', ...
%     'XJitter', 'density', 'XJitterWidth', 0.5, 'MarkerFaceAlpha', 0.15);

% Axes labels
xlabel('Cluster', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Intra-cluster Distance', 'FontSize', 13, 'FontWeight', 'bold');

% Title with LaTeX formatting
title(sprintf(['\\textbf{Aggregated Intra-cluster Distances}\n', ...
    'Across %d Simulations, $\\alpha = %.1f\\%%$'], ...
    length(entries), 100*alpha), ...
    'Interpreter', 'latex', 'FontSize', 14);

% Aesthetic tuning
set(gca, ...
    'FontSize', 11, ...
    'TickLength', [0 0], ...
    'LineWidth', 1.2, ...
    'XColor', 'k', ...
    'YColor', 'k');

xtickangle(90);  % If labels are long
box on;
% ylim([0 350]);

savePath = fullfile("Results", "N"+num2str(N), "nMems" + num2str(nMems), "alpha" + num2str(round(100*alpha)));
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
% print(gcf, savePath + filesep + 'IntraCluster', '-dpng', '-r600');   % 600 DPI PNG
% print(gcf, savePath + filesep + 'IntraCluster', '-dpdf');           % Vector EPS

%% Plot inter cluster distances heatmap

% Compute mean across simulations
mean_inter = mean(all_inter_values, 3, 'omitnan');

% Create figure
figure('Color', 'w', 'Position', [100, 100, 800, 700], 'Visible', visible);

% Optional: remove self-distances (diagonal)
mean_inter(logical(eye(size(mean_inter)))) = NaN;

% Plot heatmap
imagesc(mean_inter);
axis square;
colormap(parula);  % Use perceptually uniform colormap

% Colorbar with label
cb = colorbar();
cb.Label.String = 'Euclidean Distance';
cb.Label.FontSize = 12;
cb.Label.FontWeight = 'bold';

% Tick setup
xticks(1:numel(uniqueGroups));
yticks(1:numel(uniqueGroups));
xticklabels(uniqueGroups);
yticklabels(uniqueGroups);
xtickangle(90);

% Axis labels (optional)
xlabel('Cluster', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Cluster', 'FontSize', 12, 'FontWeight', 'bold');

% Title
title(sprintf('\\textbf{Mean Inter-cluster Distances}\n  Across %d Simulations, $\\alpha = %.1f\\%%$', length(entries), round(100*alpha)), ...
    'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');

% clim([90 230]);
% Aesthetic improvements
set(gca, ...
    'FontSize', 10, ...
    'TickLength', [0 0], ...
    'LineWidth', 1.2, ...
    'XColor', 'k', ...
    'YColor', 'k', ...
    'Ydir', 'Normal');

savePath = fullfile("Results", "N"+num2str(N), "nMems" + num2str(nMems), "alpha" + num2str(round(100*alpha)));
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
% print(gcf, savePath + filesep + 'InterCluster', '-dpng', '-r600');   % 600 DPI PNG
% print(gcf, savePath + filesep + 'InterCluster', '-dpdf');           % Vector EPS

%% plot Statistics of all distances
m_idx = 1:nMems;
rnd_idx = nMems+1 : 2*nMems;

% --- Intra-cluster distances ---
intra_type_labels = strings(size(all_intra_labels));
intra_type_labels(contains(all_intra_labels, "m")) = "Intra: m";
intra_type_labels(contains(all_intra_labels, "rnd")) = "Intra: rnd";


% --- m vs m (upper triangle only) ---
mask_m_vs_m = triu(true(nMems), 1);  % exclude diagonal
vals_m_vs_m = all_inter_values(m_idx, m_idx, :);
vals_m_vs_m = vals_m_vs_m(mask_m_vs_m);  % linearize across all sims

% --- m vs rnd ---
vals_m_vs_rnd = all_inter_values(m_idx, rnd_idx, :);
vals_m_vs_rnd = vals_m_vs_rnd(:);  % flatten

% --- rnd vs rnd (upper triangle only) ---
mask_rnd_vs_rnd = triu(true(nMems), 1);  % for 25 rnds
vals_rnd_vs_rnd = all_inter_values(rnd_idx, rnd_idx, :);
vals_rnd_vs_rnd = vals_rnd_vs_rnd(mask_rnd_vs_rnd);  % flatten across sims


% Combine labels
inter_values_all = [vals_m_vs_m; vals_m_vs_rnd; vals_rnd_vs_rnd];
inter_labels_all = [ ...
    repmat("Inter: m vs m", numel(vals_m_vs_m), 1); 
    repmat("Inter: m vs rnd", numel(vals_m_vs_rnd), 1);
    repmat("Inter: rnd vs rnd", numel(vals_rnd_vs_rnd), 1)
];

% Final labels
all_values = [all_intra_values; inter_values_all];
all_labels = [intra_type_labels; inter_labels_all];

valid_mask = all_labels ~= "";
all_values = all_values(valid_mask);
all_labels = all_labels(valid_mask);

% Order of categories for plotting
ordered_cats = ["Intra: m", "Intra: rnd", "Inter: m vs m", "Inter: m vs rnd", "Inter: rnd vs rnd"];
cat_labels = categorical(all_labels, ordered_cats, 'Ordinal', true);


figure('Color', 'w', 'Position', [100, 100, 900, 500], 'Visible', visible);
violinplot(cat_labels, all_values);


ylabel('Euclidean Distance');
xlabel('Group');
title(sprintf(['\\textbf{Cluster Distance Comparison}\n' ...
    'Intra vs Inter (Learned vs Random), Across %d Simulations, $\\alpha$ = %d \\%%'], ...
    size(all_inter_values, 3), round(100*alpha)), ...
    'Interpreter', 'latex', 'FontSize', 14);
set(gca, 'FontSize', 12);

% ylim([0 350]);

savePath = fullfile("Results", "N"+num2str(N), "nMems" + num2str(nMems), "alpha" + num2str(round(100*alpha)));
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
% print(gcf, savePath + filesep + 'statistics', '-dpng', '-r600');   % 600 DPI PNG
% print(gcf, savePath + filesep + 'statistics', '-dpdf');           % Vector EPS

%% Saving cluster-level matrix for downstream analyses

% Compute full cluster matrix INCLUDING diagonal
mean_cluster_mat = mean(all_inter_values, 3, 'omitnan');

% Use integer key to avoid floating-point key issues
alphaKey = round(100 * alpha);

% Path to file for cluster-level data
clusterMatPath = sprintf("Data\\N%d\\nMems%d\\clusterDistanceMatrices.mat", N, nMems);

% Load existing dictionary or initialize
if isfile(clusterMatPath)
    loadedVars = load(clusterMatPath, "clusterDictionary");
    if isfield(loadedVars, "clusterDictionary")
        clusterDictionary = loadedVars.clusterDictionary;
    else
        clusterDictionary = containers.Map("KeyType", "double", "ValueType", "any");
    end
else
    clusterDictionary = containers.Map("KeyType", "double", "ValueType", "any");
end

% Store struct for this alpha
clusterData = struct();
clusterData.mean_cluster_mat = mean_cluster_mat;   % diagonal included
clusterData.uniqueGroups = uniqueGroups;
clusterData.alpha = alpha;
clusterData.alphaKey = alphaKey;
clusterData.N = N;
clusterData.nMems = nMems;
clusterData.nSims = length(entries);

clusterDictionary(alphaKey) = clusterData;

% Save
if isfile(clusterMatPath)
    save(clusterMatPath, "clusterDictionary", "-append");
else
    save(clusterMatPath, "clusterDictionary");
end