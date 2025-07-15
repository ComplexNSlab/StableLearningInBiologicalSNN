clc;clear;
N = 400; M = 10; alpha = 60;
dirs = dir(fullfile("Data", "N"+num2str(N), num2str(M) + "memories"));
file = fullfile(dirs(3).folder, dirs(3).name, "recallsResponses", "alpha_" + num2str(alpha)+ ".mat");
load(file);
whos

% figure;
% scatter(X_responseActivity(400, :), 1:N, 5, 'filled')

[~, order] = sort(Y_memoryClass);
simMAt = utils.ComputePearsonSimilarity(X_responseActivity(order, :), X_responseActivity(order, :), 10);

figure;
imagesc(simMAt); colorbar();
