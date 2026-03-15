% PlotSeparationVsAlpha.m  (FigureScripts/)
%
% Plots the mean cluster separation score (S) for Memory and Random
% clusters as a function of recall precision (alpha). For each alpha,
% S_i = mean_offdiag(D_i) / D_ii is computed per cluster, then averaged
% within Memory and Random groups. Error bars show +/- 1 std across
% clusters.
%
% Requires: clusterDistanceMatrices.mat (produced by Step4_plots.m)
% Run from: the Part3(ClassificationSequential) root directory.
% Parameters: N, nMems, alphas (set below)

clear; clc;

visible = true;

N = 400;
nMems = 25;

alphas = [0.1 0.3 0.5 0.7 0.9];

clusterMatPath = fullfile("..", "Data", sprintf("N%d", N), sprintf("nMems%d", nMems), "clusterDistanceMatrices.mat");
load(clusterMatPath, "clusterDictionary");

S_memory_mean = [];
S_random_mean = [];

S_memory_std = [];
S_random_std = [];

for a = alphas

    alphaKey = round(100*a);

    clusterData = clusterDictionary(alphaKey);

    mean_cluster_mat = clusterData.mean_cluster_mat;
    labels = string(clusterData.uniqueGroups);

    % ---- Compute S_i ----
    diag_i = diag(mean_cluster_mat);

    mean_offdiag = zeros(length(diag_i),1);

    for i = 1:length(diag_i)
        row = mean_cluster_mat(i,:);
        row(i) = NaN;
        mean_offdiag(i) = mean(row,'omitnan');
    end

    S_i = mean_offdiag ./ diag_i;

    is_memory = startsWith(labels,"m");
    is_random = startsWith(labels,"rnd");

    S_memory_mean(end+1) = mean(S_i(is_memory));
    S_random_mean(end+1) = mean(S_i(is_random));

    S_memory_std(end+1) = std(S_i(is_memory));
    S_random_std(end+1) = std(S_i(is_random));

end

%% Plot

figure('Color','w','Position',[100 100 650 450],'Visible',visible)

errorbar(alphas,S_memory_mean,S_memory_std,'-o','LineWidth',2)
hold on

errorbar(alphas,S_random_mean,S_random_std,'-o','LineWidth',2)

yline(1,'--k', 'Overlap Threshold', 'LineWidth', 1.2)

xlabel('\alpha','FontSize',13,'FontWeight','bold')
ylabel('Cluster Separation Score','FontSize',13,'FontWeight','bold')

legend('Memory','Random','Overlap Threshold','Location','northwest')

title('\textbf{Cluster Separation vs Recall Precision}','Interpreter','latex')

set(gca,'FontSize',12,'LineWidth',1.2)

box on
xlim([0 1])

%% Save
savePath = fullfile("..", "Results", "N"+num2str(N), "nMems"+num2str(nMems));
if ~exist(savePath, 'dir'), mkdir(savePath); end
print(gcf, fullfile(savePath, 'SeparationVsAlpha'), '-dpng', '-r600');
print(gcf, fullfile(savePath, 'SeparationVsAlpha'), '-dpdf');
