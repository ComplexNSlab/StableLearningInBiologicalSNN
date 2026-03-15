clear; clc;
load('C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\Analysis\Part5(NoisyConsolidation)\Results\C(delta_m).mat');

figure; hold on;
for i = 1:numel(allRecords)
    rec = allRecords(i);
    plot(rec.X, rec.Y, 'o-','DisplayName', sprintf('N=%d', rec.N));
end
hold off;
xlabel('X');
ylabel('Y');
legend('show');
title('Y vs X for different N');
grid on;
set(gca, 'XScale', 'log', 'YScale', 'log');
%%
figure; hold on;
nRec = numel(allRecords);
exponents = zeros(nRec, 1);
errors = zeros(nRec, 1);
Nlist = zeros(nRec, 1);

for i = 1:nRec
    rec = allRecords(i);
    valid = rec.X > 0 & rec.Y > 0;
    x = rec.X(valid);
    y = rec.Y(valid);

    % --- Remove tail: only first 70% of points ---
    cutoff = round(0.7 * numel(x));
    x = x(1:cutoff);
    y = y(1:cutoff);

    % --- Linear fit in log-log space ---
    p = polyfit(log10(x), log10(y), 1);
    yfit = 10.^(polyval(p, log10(x)));
    plot(x, y, 'o-'); % original (trimmed)
    plot(x, yfit, '--', 'LineWidth', 1); % fit

    % --- Save exponent and N ---
    exponents(i) = p(1);
    Nlist(i) = rec.N;

    % --- Standard error of slope ---
    mdl = fitlm(log10(x), log10(y));
    errors(i) = mdl.Coefficients.SE(2);
end

set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('X'); ylabel('Y');
legend(arrayfun(@(n) sprintf('N=%d', n), Nlist, 'UniformOutput', false), 'Location', 'best');
title('Y vs X for different N with Power-Law Fit');

% --- Display table of results ---
T = table(Nlist, exponents, errors, 'VariableNames', {'N', 'Exponent', 'Error'});
disp(T)
%% Plot exponents vs N with error bars and reference line.
errorbar(Nlist, exponents, errors, 'o', 'LineWidth', 2)
hold on
yline(-1, '--r', 'True exponent = -1')
xlabel('N')
ylabel('Exponent')
title('Exponent vs N with error bars')
set(gca, 'XScale', 'log') % optional if N covers orders of magnitude
grid on
%% Compute weighted mean and its error.
w = 1 ./ errors.^2;
b_mean = sum(exponents .* w) / sum(w);
b_err = sqrt(1 / sum(w));
fprintf('Weighted mean exponent = %.4f ± %.4f\n', b_mean, b_err)
%% Do a chi-square test for b = -1
b0 = -1;
chi2 = sum((exponents - b0).^2 ./ errors.^2);
dof = numel(exponents) - 1;
fprintf('Chi-square/dof = %.2f/%d = %.2f\n', chi2, dof, chi2/dof)
