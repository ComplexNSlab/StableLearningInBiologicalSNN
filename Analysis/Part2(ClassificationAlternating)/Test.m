clc;clear;
N = 100; M = 50; alpha = 50;
dirs = dir(fullfile("Data", "N"+num2str(N), num2str(M) + "memories"));
file = fullfile(dirs(3).folder, dirs(3).name, "recallsResponses", "alpha_" + num2str(alpha)+ ".mat");
load(file);
whos

% figure;
% scatter(X_responseActivity(400, :), 1:N, 5, 'filled')

[~, order] = sort(Y_memoryClass);
simMAt = utils.ComputePearsonSimilarity(X_responseActivity(order, 1:round(0.8*N)), X_responseActivity(order,  1:round(0.8*N)), 5);

figure;
imagesc(simMAt); cb = colorbar(); cb.Label.String = "Pearson Correlation";
mList = [arrayfun(@(x) sprintf('%d', x), 1:M, 'UniformOutput', false), {'random'}];
title(sprintf("N = %d, M = %d, $\\alpha$ = %d \\%%", N, M, alpha), 'Interpreter','latex')
xticks(-50 + 100*(1:M+1)); xticklabels(mList);
yticks(-50 + 100*(1:M+1)); yticklabels(mList);
set(gca, 'ydir', 'normal');

simMat = simMAt(1:100*M, 1:100*M);

Nblock = 100;
nBlocks = M;

% Reshape: [block_row, row_within_block, block_col, col_within_block]
B = reshape(simMat, Nblock, nBlocks, Nblock, nBlocks);
B = permute(B, [2 4 1 3]);  % now B(i,j,:,:) is the (i,j) block (100x100)

mask = ~eye(Nblock);  % logical mask to remove self-comparisons

% Intra similarities (excluding diagonal)
d_intra = cell2mat(arrayfun(@(k) reshape(reshape(B(k,k,:,:),Nblock,Nblock), [],1), 1:nBlocks, 'UniformOutput', false));
d_intra = d_intra(repmat(mask(:), nBlocks, 1));

% Inter similarities (all off-diagonal blocks)
[i_idx, j_idx] = find(~eye(nBlocks)); % off-diagonal block indices
d_inter = cell2mat(arrayfun(@(a,b) reshape(B(a,b,:,:),[],1), i_idx, j_idx, 'UniformOutput', false));


%%
mu_intra = nanmean(d_intra);
mu_inter = nanmean(d_inter);
sigma_intra = nanstd(d_intra);
sigma_inter = nanstd(d_inter);

d_prime = (mu_intra - mu_inter) / sqrt(0.5*(sigma_intra^2 + sigma_inter^2));


edges = linspace(-1, 1, 200);  % use same bins as your plot
counts_intra = histcounts(d_intra, edges, 'Normalization', 'probability'); counts_intra = counts_intra/sum(counts_intra);
counts_inter = histcounts(d_inter, edges, 'Normalization', 'probability'); counts_inter = counts_inter/sum(counts_inter);
overlap_area = sum(min(counts_intra, counts_inter));

% Randomly sample a subset for speed if needed
N1 = length(d_intra); N2 = length(d_inter);
nSample = min([1e5, N1*N2]);
idx1 = randi(N1, nSample, 1);
idx2 = randi(N2, nSample, 1);
auc = mean(d_intra(idx1) > d_inter(idx2));


figure; hold on
histogram(d_intra, 'Normalization', 'probability', 'DisplayStyle', 'stairs', 'LineWidth', 2)
histogram(d_inter, 'Normalization', 'probability', 'DisplayStyle', 'stairs', 'LineWidth', 2)
legend('Intra-cluster', 'Inter-cluster', 'Location', 'northwest')
xlabel('Pearson similarity')
ylabel('Probability')
title(sprintf('N = %d, M = %d, \\alpha = %d%%', N, M, alpha))

% Display metrics as text box
metrics_str = sprintf(['d'' = %.2f\nOverlap = %.2f\nAUC = %.2f'], ...
                     d_prime, overlap_area, auc);
annotation('textbox', [0.20 0.25 0.25 0.15], 'String', metrics_str, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'FontSize', 12);

% Optionally, mark the means
yl = ylim;
plot([mu_intra mu_intra], yl, 'b--', 'LineWidth', 1)
plot([mu_inter mu_inter], yl, 'r--', 'LineWidth', 1)
text(mu_intra, yl(2)*0.95, sprintf('\\mu_{intra}=%.2f',mu_intra), 'Color','b','HorizontalAlignment','right')
text(mu_inter, yl(2)*0.90, sprintf('\\mu_{inter}=%.2f',mu_inter), 'Color','r','HorizontalAlignment','left')