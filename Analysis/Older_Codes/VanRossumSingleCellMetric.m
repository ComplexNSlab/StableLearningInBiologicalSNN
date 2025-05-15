%% Reading a particular memory learning phase
clc; clear;
RecordingDirectory = "Data\Aug_16_2024_18_58";

memnum = 1;
file = RecordingDirectory + filesep + "patch" + num2str(memnum);

data = load(file);
data = getfield(data, "data"+num2str(memnum));
firings = data.firings;
firings(1, :) = firings(1, :)/1000;

clearvars -except firings memnum
%% Filtering for a particular trial in learning 
trialnum = 1000;
idx = ((memnum-1)*100 + 0.1*(trialnum-1) <= firings(1, :)) & (firings(1, :) <= (memnum-1)*100 + 0.1*trialnum);
firings_ = firings(:, idx);
firings_(1, :) = mod(firings_(1, :), 0.1)*1000;

figure;
plot(firings_(1, :), firings_(2, :), 'k.')
xlabel("Time (ms)")
ylabel("Neuron ID")
title(sprintf("Raster Plot Memory %d Trial %d", memnum, trialnum))
set(gca, 'fontsize', 15)
%% Computing A (low pass filter) with a given parameter tau
A = zeros(400, 1000);
tau = 0.1; %ms

for i = 1:size(firings_, 2)
    A(firings_(2, i), :) = A(firings_(2, i), :) + (((1:1000)*0.1 - firings_(1, i)) >= -0.001) .* exp(-((1:1000)*0.1 - firings_(1, i))/tau);
end

figure;
imagesc(A)
cb = colorbar; cb.Label.String = sprintf("A (tau = %0.1f ms)", tau);
xticks((1:100:1001)-0.5);
xticklabels((0:100:1001)*0.1)
xlabel("Time (ms)")
ylabel("Neuron label")
title(sprintf("Memory %d Trial %d", memnum, trialnum))
set(gca, 'ydir', 'normal', 'fontsize', 15)
%% Euclidean distance between low pass filter signals
distances = zeros(400, 400);
for i = 1:size(A, 1)
    for j = 1:size(A, 1)
        df = A(i, :) - A(j, :);
        df2 = df .* df;
        d = sum(df2) * 0.1 / tau;
        distances(i, j) = sqrt(d);
    end
end

figure;
imagesc(distances)
cb = colorbar; cb.Label.String = "Euclidean Distance";
xlabel("Neuron Label")
ylabel("Neuron Label")
title(sprintf("A (tau = %0.1f ms)", tau))
set(gca, 'YDir', 'normal', 'FontSize', 15)

%% Euclidean distance between low pass filter signals from pdist
distances1 = squareform(pdist(A, 'euclidean'))*0.1/tau;

figure;
imagesc(distances1)
cb = colorbar; cb.Label.String = "Euclidean Distance";
xlabel("Neuron Label")
ylabel("Neuron Label")
title(sprintf("A (tau = %0.1f ms)", tau))
set(gca, 'YDir', 'normal', 'FontSize', 15)

