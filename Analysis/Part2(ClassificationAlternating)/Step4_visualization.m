

%% ROC curves for memory classes and random recall classes

clear; clc;

N = 200; % Network Size
alpha_range = 5:5:95;

% Get list of all items in the current directory
N_mems = 50;

items = dir(fullfile("Data",  "N"+num2str(N),num2str(N_mems) + "memories/"));
folders = items([items.isdir]); % Keep only directories
folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'


% loop over different partial recall ratios 
for iter = 1:3
    figure; hold on;
    
    % Create title: show pattern and alpha
    title(sprintf("SVM Classification - ROC Curves ($\\alpha = %d \\%%$) \n %d memories over %d simulations", int8(alpha_range(iter)), N_mems, length(folders)), ...
      'Interpreter', 'latex')
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');

    % Loop over each folder of independant simulation
    leg_flag = 'on'; leg_flag_2 = 'on';
    for i = 1:length(folders)
        folderName = fullfile(folders(i).folder, folders(i).name, "ClassificationResults.mat");
        load(folderName, 'roc_curves');
        curves = squeeze(roc_curves(iter, :, :));
        
        plot(curves{end, 1}, curves{end, 2}, 'r', DisplayName='random recalls', HandleVisibility=leg_flag_2); 
        leg_flag_2 = 'off';

        for mem = 1:N_mems
            plot(curves{mem, 1}, curves{mem, 2}, 'k', DisplayName="memory", HandleVisibility= leg_flag);
            leg_flag = 'off';
        end

    end
    legend(Location='southeast');
    grid on;
end
%%
all_labels = [];
all_scores = [];

for mem = 1:N_mems
    % Assuming the format is:
    % curves{mem, 1} = FPR
    % curves{mem, 2} = TPR
    % curves{mem, 3} = scores
    % curves{mem, 4} = true_labels (binary)
    if size(curves, 2) >= 4
        all_scores = [all_scores; curves{mem, 3}(:)];
        all_labels = [all_labels; curves{mem, 4}(:)];
    end
end

[~,~,~,AUC_micro] = perfcurve(all_labels, all_scores, 1);
[FPR_micro, TPR_micro, ~] = perfcurve(all_labels, all_scores, 1);

plot(FPR_micro, TPR_micro, 'b--', 'LineWidth', 2, ...
     'DisplayName', sprintf('Micro-average (AUC = %.2f)', AUC_micro));

%% Performance measures vs Alpha (partial recall ratio)

clear; clc;

N = 400; % Network Size
alpha_range = 5:5:95;

% Get list of all items in the current directory
N_mems = 50;

folder_path = fullfile("Data",  "N"+num2str(N),num2str(N_mems) + "memories/");
items = dir(folder_path);
folders = items([items.isdir]); % Keep only directories
folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'

% Raise an error if no folders found
if isempty(folders)
    error('No subfolders found in path: %s', folder_path);
end

% Fetching metric values

f1_mems = zeros(length(alpha_range), length(folders), N_mems);
f1_rands = zeros(length(alpha_range), length(folders));
p_mems = zeros(length(alpha_range), length(folders), N_mems);
p_rands = zeros(length(alpha_range), length(folders));
r_mems = zeros(length(alpha_range), length(folders), N_mems);
r_rands = zeros(length(alpha_range), length(folders));
auc_mems = zeros(length(alpha_range), length(folders), N_mems);
auc_rands = zeros(length(alpha_range), length(folders));

% Loop over each folder of independant simulations
for i = 1:length(folders)
    % Load the result file
    folderName = fullfile(folders(i).folder, folders(i).name, "ClassificationResults.mat");
    data = load(folderName, 'results');
    results = data.results;

    % Loop over alpha keys
    result_keys = keys(results);
    for k = 1:length(result_keys)
        key = result_keys{k};
        alpha_value = str2double(key);
        alph_idx = find(alpha_range == alpha_value, 1);

        if isempty(alph_idx)
            warning('Alpha value %s not found in alpha_range.', key);
            continue;
        end

        s = results(key);
        f1_mems(alph_idx, i, :) = s.f1(1:end-1);
        f1_rands(alph_idx, i) = s.f1(end);

        p_mems(alph_idx, i, :) = s.p(1:end-1);
        p_rands(alph_idx, i) = s.p(end);

        r_mems(alph_idx, i, :) = s.r(1:end-1);
        r_rands(alph_idx, i) = s.r(end);

        auc_mems(alph_idx, i, :) = s.auc(1:end-1);
        auc_rands(alph_idx, i) = s.auc(end);
    end
end


% Visualizing or saving Performance Metrics plots
X_mems = {f1_mems, p_mems, r_mems, auc_mems}; X_rands = {f1_rands, p_rands, r_rands, auc_rands}; S = {"F1 Score", "Precision", "Recall", "AUC"};

for i = 1:4
    x_mems = X_mems{i}; x_rands = X_rands{i}; s = S{i};
    fig = plotMeanCurveWithCI(x_mems, x_rands, alpha_range, 95, s);
    
    % Save
    filename = fullfile(pwd, 'Results','SVMResults', "N"+num2str(N), sprintf('%s_Curve_%d_Mems.pdf', strrep(s, ' ', ''), N_mems));
    filename = char(filename);
    exportgraphics(fig, filename, 'ContentType', 'vector');  % high-quality PDF
    print(gcf, filename(1:end-3) + "png", '-dpng', '-r300');
end

%% functions


function fig = plotMeanCurveWithCI(x_mems, x_rands, alpha_range, CI, metric_name)
    % PLOTMEANCURVEWITHCI Plot mean curves and CI bands for memory and random recall
    %
    % Inputs:
    %   x_mems       - [alpha × sims × mems] matrix of memory performance values
    %   x_rands      - [alpha × sims] matrix of random recall performance values
    %   alpha_range  - vector of alpha values (x-axis)
    %   CI           - confidence interval percentage (e.g., 95)
    %   metric_name  - string for labeling the metric (e.g., 'Recall', 'Precision')

    % Figure setup
    fig = figure('Color', 'w', 'Visible', 'on'); hold on;

    % Sizes
    N_mems = size(x_mems, 3);
    N_sims = size(x_mems, 2);

    % --- Memory curve with confidence band ---
    mem_CI_upper = prctile(x_mems, (100 + CI)/2, [2, 3])';
    mem_CI_lower = prctile(x_mems, (100 - CI)/2, [2, 3])';
    mem_mean = squeeze(mean(x_mems, [2, 3]));

    % Shaded confidence region for memory
    fill([alpha_range, fliplr(alpha_range)], ...
         [mem_CI_upper, fliplr(mem_CI_lower)], ...
         [0.7 0.7 0.7], 'EdgeColor', 'none', ...
         'FaceAlpha', 0.4, 'HandleVisibility', 'off');

    % Mean memory line
    plot(alpha_range, mem_mean, 'k', 'LineWidth', 2.5);

    % --- Random recall curve with confidence band ---
    rand_CI_upper = prctile(x_rands, (100 + CI)/2, [2, 3])';
    rand_CI_lower = prctile(x_rands, (100 - CI)/2, [2, 3])';
    rand_mean = squeeze(mean(x_rands, [2, 3]));

    % Shaded confidence region for random recall
    fill([alpha_range, fliplr(alpha_range)], ...
         [rand_CI_upper, fliplr(rand_CI_lower)], ...
         [1 0.5 0.5], 'EdgeColor', 'none', ...
         'FaceAlpha', 0.4, 'HandleVisibility', 'off');

    % Mean random recall line
    plot(alpha_range, rand_mean, 'Color', [0.8 0 0], 'LineWidth', 2.5);

    % --- Labels and styling ---
    xlabel('Partial Recall Ratio, $\alpha$ (\%)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel(metric_name, 'FontSize', 14);

    title(sprintf('%s Performance — SVM Classification\n%d Memories, %d Simulations, %d%% CI', ...
        metric_name, N_mems, N_sims, CI), 'FontSize', 14);

    legend({'Memory Recalls', 'Random Recalls'}, ...
        'Location', 'SouthEast', 'FontSize', 11, 'Box', 'off');

    xlim([min(alpha_range), max(alpha_range)]);
    ylim([0 1]);  % Adjust as needed

    grid off;
    box on;
    set(gca, 'FontSize', 12);
end
