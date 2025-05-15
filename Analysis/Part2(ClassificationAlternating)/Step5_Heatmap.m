clear; clc;

% Parameters
N = 200;
alpha_range = 5:5:95;
nMems_range = [10:10:50];
metric_names = {'F1', 'Precision', 'Recall', 'AUC'};
nMetrics = numel(metric_names);

% Initialize: [nMems × alpha × metric]
perf_mat = NaN(length(nMems_range), length(alpha_range), nMetrics);

% Loop over memory counts
for m = 1:length(nMems_range)
    nMems = nMems_range(m);
    folder_path = fullfile("Data", "N"+num2str(N), num2str(nMems) + "memories/");
    items = dir(folder_path);
    folders = items([items.isdir]);
    folders = folders(~ismember({folders.name}, {'.', '..'}));

    if isempty(folders), continue; end

    % Temp storage per metric: [alpha × sims × mems]
    f1_temp  = NaN(length(alpha_range), length(folders), nMems);
    p_temp   = NaN(length(alpha_range), length(folders), nMems);
    r_temp   = NaN(length(alpha_range), length(folders), nMems);
    auc_temp = NaN(length(alpha_range), length(folders), nMems);

    for i = 1:length(folders)
        file = fullfile(folder_path, folders(i).name, "ClassificationResults.mat");
        if ~isfile(file), continue; end
        data = load(file);
        if ~isfield(data, 'results'), continue; end
        results = data.results;

        result_keys = keys(results);
        for k = 1:length(result_keys)
            key = result_keys{k};
            alpha_val = str2double(key);
            alph_idx = find(alpha_range == alpha_val, 1);
            if isempty(alph_idx), continue; end

            s = results(key);
            if isfield(s, 'f1') && isfield(s, 'p') && isfield(s, 'r') && isfield(s, 'auc')
                f1_temp(alph_idx, i, :)  = s.f1(1:end-1);   % memory only
                p_temp(alph_idx, i, :)   = s.p(1:end-1);
                r_temp(alph_idx, i, :)   = s.r(1:end-1);
                auc_temp(alph_idx, i, :) = s.auc(1:end-1);
            end
        end
    end

    % Store average over sims and memories
    perf_mat(m,:,1) = squeeze(mean(f1_temp,  [2,3], 'omitnan'));
    perf_mat(m,:,2) = squeeze(mean(p_temp,   [2,3], 'omitnan'));
    perf_mat(m,:,3) = squeeze(mean(r_temp,   [2,3], 'omitnan'));
    perf_mat(m,:,4) = squeeze(mean(auc_temp, [2,3], 'omitnan'));
end

%%
% Plot one figure per metric
for metric_id = 1:nMetrics
    figure('Units', 'inches', 'Position', [1, 1, 7, 4.5]);
    data = perf_mat(:,:,metric_id);

    imagesc(alpha_range, nMems_range, data);

    xlabel('Partial Recall Ratio $ \alpha $ (\%)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('Number of Memories', 'Interpreter', 'latex', 'FontSize', 14);
    title(sprintf('%s Heatmap (SVM Classification)', metric_names{metric_id}), 'FontSize', 14);

    colormap(parula);
    colorbar;
    set(gca, 'YDir', 'normal', 'FontSize', 12);

    % Annotate values
    for i = 1:size(data,1)
        for j = 1:size(data,2)
            val = data(i,j);
            if ~isnan(val)
                text(alpha_range(j), nMems_range(i), sprintf('%.2f', val), ...
                    'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 8);
            end
        end
    end

    % Save figure
    filename = fullfile('Results', 'SVMResults', ...
        sprintf('%s_Heatmap.pdf', strrep(metric_names{metric_id}, ' ', '')));
    exportgraphics(gcf, filename, 'ContentType', 'vector');
end
