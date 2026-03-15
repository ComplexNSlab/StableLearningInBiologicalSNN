clear; clc;

results = struct();  

for N = [100, 200, 400, 800, 1600]
    clearvars -except N results
    load(sprintf("Data\\Scaled50\\N%d\\norm_A.mat", N))
    load(sprintf("Data\\Scaled50\\N%d\\assembly.mat", N))
    load(sprintf("Data\\Scaled50\\N%d\\weights_corr.mat", N))

    curves1 = reshape(mean_curve, [], size(mean_curve, 3))';
    curves2 = reshape(mean_curve_ex, [], size(mean_curve_ex, 3))';
    curves3 = reshape(signal_all, [], size(signal_all, 3))';

    [jumps1, f1] = fitExponential(curves1, 'off', 1000);
    [jumps2, f2] = fitExponential(curves2, 'off', 1000);
    f3 = fitExponentialWeights(curves3, 'off', 1);

    % Store using fieldname:
    Nfield = sprintf('N%d', N);

    results.(Nfield).f1 = f1;
    results.(Nfield).f2 = f2;
    results.(Nfield).f3 = f3;

    results.(Nfield).jumps1 = jumps1;
    results.(Nfield).jumps2 = jumps2;
    
end

% Save once at the end
save(fullfile("Data", "Scaled50", "FitResults.mat"), 'results');

%%
function [jumps, f] = fitExponential(curves, show, steps)

    y = nanmean(curves, 2);
    
    
    figure('Visible', show); hold on;
    plot(y)
    y_ends = y(steps:steps:end-steps);
    plot(steps*(1:length(y_ends)), y_ends, Marker='x')
    
    idx = round(length(y_ends)/2);
    scatter(idx*steps, y_ends(idx), 'filled')
    scatter((idx-1)*steps, y_ends(idx-1), 'filled')
    
    %
    y = curves(steps:steps:end-steps, :);
    idx = round(size(y, 1)/2);
    jumps = y(idx, :) - y(idx-1, :);
    
    figure('Visible', show); hold on;
    
    xCat = repmat(categorical("N400"), size(jumps));
    
    % Violin plot
    violinplot(xCat, jumps);
    
    % Swarmchart with proper jitter
    swarmchart(xCat, jumps, 3, 'k', 'filled', 'o', ...
               'XJitter','density', 'XJitterWidth', 1);
    ylabel("jump");
    
    % Print stats
    sprintf("Jump --> mean : %.2f , std: %.2f", mean(jumps), std(jumps))
    
    %
    % Extract and average the tail of the signal
    y = curves(steps:steps:end-steps, :);
    idx = round(size(y, 1) / 2);
    y = nanmean(y(idx:end, :), 2);
    
    % Define x
    x = (1:length(y))';
    
    % Define custom exponential decay with offset: y = a*exp(b*x) + c
    ft = fittype('a*exp(x/b) + c', 'independent', 'x', 'coefficients', {'a', 'b', 'c'});
    
    opts = fitoptions('Method', 'NonlinearLeastSquares', ...
                      'StartPoint', [0.19, -10, 0.6], ...
                      'Lower', [-Inf, -Inf, 0], ...
                      'Upper', [Inf, 0, Inf]);
    f = fit(x, y, ft, opts);
    
    % Plot results
    figure('Visible', show); hold on;
    plot(x, y, 'k-', 'DisplayName', 'Data', LineWidth=4);
    plot(f, 'r-', 'predobs');
    legend('Location', 'northeast');
    xlabel('Index');
    ylabel('Mean Signal');
    title('Exponential Decay with Offset');
    
    % Display parameters
    disp(f);
end

function f = fitExponentialWeights(curves, show, steps)

    y = nanmean(curves, 2);
    
    figure('Visible', show); hold on;
    plot(y)
    y_ends = y(steps:steps:end-steps);
    plot(steps*(1:length(y_ends)), y_ends, Marker='x')

    % Extract and average the tail of the signal
    y = curves(steps:steps:end-steps, :);
    idx = round(size(y, 1) / 2)+1;
    y = nanmean(y(idx:end, :), 2);
    
    % Define x
    x = (1:length(y))'-1;
    
    % Define custom exponential decay with offset: y = a*exp(b*x) + c
    ft = fittype('a*exp(x/b) + c', 'independent', 'x', 'coefficients', {'a', 'b', 'c'});
    
    opts = fitoptions('Method', 'NonlinearLeastSquares', ...
                      'StartPoint', [0.8, -10, 0.2], ...
                      'Lower', [-Inf, -Inf, 0], ...
                      'Upper', [Inf, 0, Inf]);
    f = fit(x, y, ft, opts);
    
    % Plot results
    figure('Visible', show); hold on;
    plot(x, y, 'k-', 'DisplayName', 'Data', LineWidth=4);
    plot(f, 'r-', 'predobs');
    legend('Location', 'northeast');
    xlabel('Index');
    ylabel('Mean Signal');
    title('Exponential Decay with Offset');
    
    % Display parameters
    disp(f);
end