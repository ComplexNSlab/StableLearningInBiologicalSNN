
%%
w_all = data.w(1:net.Ne, 1:net.Ne, 600:300:end);
w_all = reshape(w_all, [], size(w_all, 3));
w_all = w_all(net.Adjacency_matrix(1:net.Ne, 1:net.Ne), :);

%%
% Extract value at t = 300
cval = w_all(:, 600);                 % values you want to base color on
[~, sort_idx] = sort(cval);          % optional: sort if you want lines drawn in order

% Normalize values to 1–N for colormap
cmap = parula(6400);                 % or use fewer entries and interpolate
norm_idx = rescale(cval, 1, 6400);   % scale to 1–6400 range
norm_idx = round(norm_idx);

figure; hold on;
for i = 1:6400
    plot(w_all(i,:), 'Color', cmap(norm_idx(i), :))
end

%%
mat = 1 - squareform(pdist(w_all', 'correlation'));
figure;
imagesc(mat);
colormap("jet")
cb = colorbar();

%%
mat = 1 - squareform(pdist(spike_counts(1500:1500:end, :), 'correlation'));
figure;
imagesc(mat);
colormap("jet")
cb = colorbar();
%%
mat = 1 - squareform(pdist(delays(1500:1500:end, :), 'correlation'));
figure;
imagesc(mat);
colormap("jet")
cb = colorbar();

%%
mat = 1 - squareform(pdist(orders_together(1500:1500:end, :), 'spearman'));
figure;
imagesc(mat);
colormap("jet")
cb = colorbar();



