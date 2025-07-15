clear; clc;

% Parameters
N = 100;
alpha_range = 5:5:95;
nMems_range = [10:10:200];
% metric_names = {'F1', 'Precision', 'Recall', 'AUC'};
metric_names = {'F1'};

nMetrics = numel(metric_names);

% Initialize: [nMems × alpha × metric]
perf_mat_memories = NaN(length(nMems_range), length(alpha_range), nMetrics);
perf_mat_randoms = NaN(length(nMems_range), length(alpha_range), nMetrics);

% Loop over memory counts
for m = 1:length(nMems_range)
    nMems = nMems_range(m);
    folder_path = fullfile("Data", "N"+num2str(N), num2str(nMems) + "memories/");
    items = dir(folder_path);
    folders = items([items.isdir]);
    folders = folders(~ismember({folders.name}, {'.', '..'}));

    if isempty(folders), continue; end

    % Temp storage per metric: [alpha × sims × mems]
    f1_temp  = NaN(length(alpha_range), length(folders), nMems+1);
    p_temp   = NaN(length(alpha_range), length(folders), nMems+1);
    r_temp   = NaN(length(alpha_range), length(folders), nMems+1);
    auc_temp = NaN(length(alpha_range), length(folders), nMems+1);

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
                f1_temp(alph_idx, i, :)  = s.f1(1:end);   % memory only
                p_temp(alph_idx, i, :)   = s.p(1:end);
                r_temp(alph_idx, i, :)   = s.r(1:end);
                auc_temp(alph_idx, i, :) = s.auc(1:end);
            end
        end
    end

    % Store average over sims and memories
    perf_mat_memories(m,:,1) = squeeze(mean(f1_temp(:, :, 1:end-1),  [2,3], 'omitnan'));
    perf_mat_memories(m,:,2) = squeeze(mean(p_temp(:, :, 1:end-1),   [2,3], 'omitnan'));
    perf_mat_memories(m,:,3) = squeeze(mean(r_temp(:, :, 1:end-1),   [2,3], 'omitnan'));
    perf_mat_memories(m,:,4) = squeeze(mean(auc_temp(:, :, 1:end-1), [2,3], 'omitnan'));

    % Store average over sims and memories
    perf_mat_randoms(m,:,1) = squeeze(mean(f1_temp(:, :, end),  [2,3], 'omitnan'));
    perf_mat_randoms(m,:,2) = squeeze(mean(p_temp(:, :, end),   [2,3], 'omitnan'));
    perf_mat_randoms(m,:,3) = squeeze(mean(r_temp(:, :, end),   [2,3], 'omitnan'));
    perf_mat_randoms(m,:,4) = squeeze(mean(auc_temp(:, :, end), [2,3], 'omitnan'));
end

%%

perf_mat = perf_mat_memories;
% Plot one figure per metric
for metric_id = 1:nMetrics
    figure('Units', 'inches', 'Position', [1, 1, 7, 4.5]);
    data = perf_mat(:,:,metric_id);

    imagesc(alpha_range, nMems_range, data);

    xlabel('Partial Recall Ratio $ \alpha $ (\%)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('Number of Memories, M', 'Interpreter', 'latex', 'FontSize', 14);
    title(sprintf('%s Heatmap (SVM Classification) for Memory Class', metric_names{metric_id}), 'FontSize', 14);
    yticks(nMems_range);
     
    colormap(parula);
    cb = colorbar();
    cb.Label.String = metric_names{metric_id};
    % clim([0.45, 1]);
    set(gca, 'YDir', 'normal', 'FontSize', 12);

    % % Annotate values
    % for i = 1:size(data,1)
    %     for j = 1:size(data,2)
    %         val = data(i,j);
    %         if ~isnan(val)
    %             text(alpha_range(j), nMems_range(i), sprintf('%.2f', val), ...
    %                 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 8);
    %         end
    %     end
    % end

    % Save figure
    filename = fullfile('Results', 'SVMResults', ...
        sprintf('%s_Heatmap_Memories.pdf', strrep(metric_names{metric_id}, ' ', '')));
    exportgraphics(gcf, filename, 'ContentType', 'vector');
    print(gcf, filename(1:end-3) + "png", '-dpng', '-r300');
end
%%
perf_mat = perf_mat_randoms;
% Plot one figure per metric
for metric_id = 1:nMetrics
    figure('Units', 'inches', 'Position', [1, 1, 7, 4.5]);
    data = perf_mat(:,:,metric_id);

    imagesc(alpha_range, nMems_range, data);

    xlabel('Partial Recall Ratio $ \alpha $ (\%)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('Number of Memories, M', 'Interpreter', 'latex', 'FontSize', 14);
    title(sprintf('%s Heatmap (SVM Classification) for Random Memory Class', metric_names{metric_id}), 'FontSize', 14);
    yticks(nMems_range);
     
    colormap(parula);
    cb = colorbar();
    cb.Label.String = metric_names{metric_id};
    % clim([0.45, 1]);
    set(gca, 'YDir', 'normal', 'FontSize', 12);

    % % Annotate values
    % for i = 1:size(data,1)
    %     for j = 1:size(data,2)
    %         val = data(i,j);
    %         if ~isnan(val)
    %             text(alpha_range(j), nMems_range(i), sprintf('%.2f', val), ...
    %                 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 8);
    %         end
    %     end
    % end

    % Save figure
    filename = fullfile('Results', 'SVMResults', ...
        sprintf('%s_Heatmap_Randoms.pdf', strrep(metric_names{metric_id}, ' ', '')));
    exportgraphics(gcf, filename, 'ContentType', 'vector');
    print(gcf, filename(1:end-3) + "png", '-dpng', '-r300');

end
