% clear; clc;

% spikeTime = [1, 2, 5, 8, 10, 14];
% spikeNeuron = [2, 5, 3, 2, 3, 4];
% firings = [spikeTime; spikeNeuron]';
firings = ff_noise1;


[bursts, ~] = utils.BurstDetector(ff_noise1, [], true, 'all', 5, 5);

[features, f_names] = utils.ExtractBurstFeatures(firings, bursts, 400);

figure; hold on;
scatter(firings(1, :)-bursts(1, 1), firings(2, :), 'filled');
idx = ~isnan(features);
plot(features(1, idx), find(idx), 'ro-', MarkerSize=10);
grid minor; xlabel("time"); ylabel("Cell Index"); title("Example Raster");
