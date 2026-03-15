clear; clc;

T = readtable('classification_metrics_table.csv');
F1_thresh = 0.70;    % Capacity threshold

%% 5. F1 vs M with error bars (single N, alpha)
alpha_target = 0.30;                 % Set your desired alpha

Nvals = unique(T.N);                % All N values in your table
c_map = lines(length(Nvals));

fig = figure; hold on

for i = 1:numel(Nvals)
    N_now = Nvals(i);
    rows = T.N == N_now & abs(T.alpha - alpha_target) < 1e-6;
    Tsub = T(rows, :);
    if isempty(Tsub)
        continue; % No data for this N and alpha
    end
    [G, Mvals] = findgroups(Tsub.M);
    meanF1 = splitapply(@mean, Tsub.memory_f1, G);
    stdF1  = splitapply(@std,  Tsub.memory_f1, G);
    errorbar(Mvals, meanF1, stdF1, '.-', 'LineWidth', 1.5, 'MarkerSize', 10, ...
        'DisplayName', sprintf('N=%d', N_now), 'Color', c_map(i, :));
end
 


yline(F1_thresh, '--r', 'Threshold', HandleVisibility='off');
xlabel('Memories M');
ylabel('Mean Macro F1');
title(sprintf('F1 score vs M (\\alpha = %.2f)', alpha_target));
legend('show','Location','southwest', 'box', 'off');
grid on
% ylim([0.1 1]);

% alpha_target = 0.20;
% Nvals = unique(T.N);
results = table('Size',[0 4], ...
    'VariableTypes',{'double','double','double','double'}, ...
    'VariableNames',{'N','a','b','Rsq'});

for i = 1:numel(Nvals)
    N_now = Nvals(i);
    rows = T.N == N_now & abs(T.alpha - alpha_target) < 1e-6;
    Tsub = T(rows, :);
    if isempty(Tsub), continue; end

    [G, Mvals] = findgroups(Tsub.M);
    meanF1 = splitapply(@mean, Tsub.memory_f1, G);

    x = log(Mvals);
    y = meanF1;
    valid = isfinite(x) & isfinite(y);
    % Fit: y = a - b*x
    p = polyfit(x(valid), y(valid), 1); % p(1)=slope, p(2)=intercept
    b = -p(1);         % slope in F1 = a - b*logM
    a = p(2);          % intercept

    % Predicted values and R² calculation
    y_pred = polyval(p, x(valid));
    SSres = sum((y(valid) - y_pred).^2);
    SStot = sum((y(valid) - mean(y(valid))).^2);
    Rsq = 1 - SSres/SStot;

    % Store in results table
    results = [results; {N_now, a, b, Rsq}];

    % Plot fitted line
    xfit = linspace(min(x), max(x), 100);
    yfit = a - b*xfit;
    plot(exp(xfit), yfit, '--', 'LineWidth', 1.2, 'HandleVisibility','off', 'Color', c_map(i, :));
end

set(gca, 'YScale', 'linear', 'XScale', 'log')
% xlim([1, 10^6])
exportgraphics(fig, fullfile("Results", "capacity", "capacityVsN.pdf"), 'ContentType', 'vector')
exportgraphics(fig, fullfile("Results", "capacity", "capacityVsN.png"), 'ContentType', 'image')

disp('Fit parameters (F1 = a - b*log(M)) for each N:');
results.M_star = exp((results.a - F1_thresh)./results.b);
disp(results);
%%
figure;
plot(results.N, results.M_star, 'ko-');
xlabel("Network Size (N)"); ylabel("Capacity (M^*)")
set(gca, 'YScale', 'log', 'XScale', 'log')

%% 1. M* vs N (for fixed alpha)
alpha_target = 0.1;   % Fix alpha
Nvals = unique(T.N);
Mstars = nan(size(Nvals));
for i = 1:numel(Nvals)
    rows = T.N == Nvals(i) & abs(T.alpha - alpha_target) < 1e-6;
    Tsub = T(rows, :);
    if isempty(Tsub)
        continue; % no data for this N and alpha
    end
    [G, Mvals] = findgroups(Tsub.M);
    meanF1 = splitapply(@mean, Tsub.memory_f1, G);
    idx = find(meanF1 > F1_thresh, 1, 'last');
    if ~isempty(idx)
        Mstars(i) = Mvals(idx);
    end
end

figure;
plot(Nvals, Mstars, 'o-','LineWidth',1.5)
xlabel('Number of Neurons N'); ylabel('Capacity M^*');
title(sprintf('Capacity M^* vs N (alpha=%.2f, F1>%.2f)', alpha_target, F1_thresh));
grid on

%% 2. F1 Heatmap: F1(M, alpha) for fixed N
N_target = 600;
Ms = unique(T.M(T.N==N_target));
alphas = unique(T.alpha(T.N==N_target));
F1map = nan(length(Ms), length(alphas));
for i = 1:length(Ms)
    for j = 1:length(alphas)
        mask = T.N == N_target & T.M == Ms(i) & abs(T.alpha - alphas(j)) < 1e-6;
        F1map(i,j) = mean(T.memory_f1(mask));
    end
end
figure;
imagesc(alphas, Ms, F1map);
set(gca, 'YDir','normal'); % so M increases upward
xlabel('\alpha'); ylabel('Memories M');
title(sprintf('F1 Heatmap (N=%d)', N_target));
colorbar;

%% 3. F1 vs M grouped by N (for fixed alpha)
alpha_target = 0.1;
figure; hold on
for n = Nvals'
    idx = T.N == n & abs(T.alpha - alpha_target) < 1e-6;
    Tsub = T(idx, :);
    if isempty(Tsub)
        continue; % no data for this N and alpha
    end
    [G, Mvals] = findgroups(Tsub.M);
    meanF1 = splitapply(@mean, Tsub.memory_f1, G);
    plot(Mvals, meanF1, '-o', 'DisplayName', sprintf('N=%d', n))
end
xlabel('Memories M'); ylabel('Mean F1'); legend show; grid on
title(sprintf('F1 vs M (alpha=%.2f)', alpha_target))

%% 4. M* surface as a function of (N, alpha)
alphas = unique(T.alpha);
Mstar_grid = nan(length(Nvals), length(alphas));
for i = 1:length(Nvals)
    for j = 1:length(alphas)
        mask = T.N == Nvals(i) & abs(T.alpha - alphas(j)) < 1e-6;
        Tsub = T(mask, :);
        if isempty(Tsub)
            continue; % no data for this N and alpha
        end        
        [G, Mvals] = findgroups(Tsub.M);
        meanF1 = splitapply(@mean, Tsub.memory_f1, G);
        idx = find(meanF1 > F1_thresh, 1, 'last');
        if ~isempty(idx)
            Mstar_grid(i,j) = Mvals(idx);
        end
    end
end
figure;
imagesc(alphas, Nvals, Mstar_grid);
set(gca, 'YDir','normal');
xlabel('\alpha'); ylabel('Neurons N'); colorbar;
title(sprintf('Capacity M^* Surface (F1>%.2f)', F1_thresh));


%% 6. M* vs alpha (for fixed N)
N_target = 400;
alphas = unique(T.alpha(T.N==N_target));
Mstars = nan(size(alphas));
for i = 1:numel(alphas)
    rows = T.N == N_target & abs(T.alpha - alphas(i)) < 1e-6;
    Tsub = T(rows, :);
    [G, Mvals] = findgroups(Tsub.M);
    meanF1 = splitapply(@mean, Tsub.memory_f1, G);
    idx = find(meanF1 > F1_thresh, 1, 'last');
    if ~isempty(idx)
        Mstars(i) = Mvals(idx);
    end
end
figure;
plot(alphas, Mstars, 'o-','LineWidth',1.5);
xlabel('\alpha'); ylabel('Capacity M^*');
title(sprintf('Capacity M^* vs Alpha (N=%d)', N_target));
grid on
%%
N_target = 400;
M_target = 1024;

rows = T.N == N_target & T.M == M_target;
alpha_vals = T.alpha(rows);
f1_vals = T.memory_f1(rows);

% Group by unique alpha values
[alphas_unique, ~, idx] = unique(alpha_vals);
f1_mean = accumarray(idx, f1_vals, [], @mean); % Mean F1 for each alpha

% (Optional: Standard deviation for error bars)
f1_std = accumarray(idx, f1_vals, [], @std);

% Sort alphas for clean plot
[alphas_sorted, sort_idx] = sort(alphas_unique);
f1_mean_sorted = f1_mean(sort_idx);
f1_std_sorted = f1_std(sort_idx);

figure;
errorbar(alphas_sorted, f1_mean_sorted, f1_std_sorted, 'o-', 'LineWidth', 1.5, 'MarkerSize', 8)
xlabel('\alpha')
ylabel('F_1 Score')
title(sprintf('F_1 vs \\alpha (N = %d, M = %d)', N_target, M_target))
grid on
%%
N_target = 500;                              % Choose your fixed N
M_list = [10:10:50];       % All unique M for this N
M_list = unique(T.M(T.N == N_target));       % All unique M for this N
cm = parula(length(M_list));

figure; hold on

for i = 1:length(M_list)
    M_now = M_list(i);

    rows = (T.N == N_target) & (T.M == M_now);
    alpha_vals = T.alpha(rows);
    f1_vals = T.memory_f1(rows);

    [alphas_unique, ~, idx] = unique(alpha_vals);
    f1_mean = accumarray(idx, f1_vals, [], @mean);
    f1_std  = accumarray(idx, f1_vals, [], @std);

    [alphas_sorted, sort_idx] = sort(alphas_unique);
    f1_mean_sorted = f1_mean(sort_idx);
    f1_std_sorted  = f1_std(sort_idx);

    errorbar(alphas_sorted, f1_mean_sorted-1, f1_std_sorted, ...
        '.-', 'LineWidth', 0.5, 'MarkerSize', 7, 'DisplayName', sprintf('M=%d', M_now), 'Color', cm(i, :))
end

xlabel('\alpha')
ylabel('1 - F_1 Score')
title(sprintf('F_1 vs \\alpha for different M (N=%d)', N_target))
legend('show')
grid on
hold off
set(gca, 'YScale', 'log')
%%
clear; clc;

T = readtable('classification_metrics_table.csv');

% ===== User settings =====
alpha_target   = 0.10;
F1_thresholds  = [0.60 0.70 0.80];     % plot multiple thresholds
fit_model_str  = 'F1 = a - b log(M)';  % for reporting
outdir         = fullfile("Results", "capacity");
if ~exist(outdir, 'dir'), mkdir(outdir); end

% ===== Prepare =====
Nvals = unique(T.N);
Nvals = sort(Nvals(:));
c_map = lines(numel(Nvals));

% Table to store fit params per N (a,b,Rsq)
fit_tbl = table('Size',[0 4], ...
    'VariableTypes',{'double','double','double','double'}, ...
    'VariableNames',{'N','a','b','Rsq'});

% ============================================================
% Figure 1: F1 vs M with error bars + fitted curves + thresholds
% ============================================================
fig1 = figure('Color','w'); hold on;

for i = 1:numel(Nvals)
    N_now = Nvals(i);

    rows = (T.N == N_now) & (abs(T.alpha - alpha_target) < 1e-6);
    Tsub = T(rows, :);
    if isempty(Tsub), continue; end

    % Group by M and compute mean/std
    [G, Mvals] = findgroups(Tsub.M);
    meanF1 = splitapply(@mean, Tsub.memory_f1, G);
    stdF1  = splitapply(@std,  Tsub.memory_f1, G);

    % Sort by M (important for plots + fits)
    [Mvals, idx] = sort(Mvals);
    meanF1 = meanF1(idx);
    stdF1  = stdF1(idx);

    % Errorbar plot
    errorbar(Mvals, meanF1, stdF1, '.-', ...
        'LineWidth', 1.5, 'MarkerSize', 12, ...
        'DisplayName', sprintf('$N=%d$', N_now), ...
        'Color', c_map(i,:));

    % ---------- Fit: meanF1 = a - b*log(M) ----------
    x = log(Mvals);
    y = meanF1;

    valid = isfinite(x) & isfinite(y);
    p = polyfit(x(valid), y(valid), 1);   % y = p1*x + p2
    a = p(2);
    b = -p(1);

    % R^2
    y_pred = polyval(p, x(valid));
    SSres = sum((y(valid) - y_pred).^2);
    SStot = sum((y(valid) - mean(y(valid))).^2);
    Rsq = 1 - SSres/SStot;

    fit_tbl = [fit_tbl; {N_now, a, b, Rsq}];

    % Fitted line overlay
    xfit = linspace(min(x(valid)), max(x(valid)), 200);
    yfit = a - b*xfit;
    plot(exp(xfit), yfit, '--', 'LineWidth', 1.2, ...
        'HandleVisibility','off', 'Color', c_map(i,:));
end

% Threshold lines (multiple)
for th = F1_thresholds
    yline(th, '--', ...
        sprintf('$\\mathrm{F1}=%.2f$', th), ...
        'Interpreter','latex', ...
        'LabelHorizontalAlignment','left', ...
        'HandleVisibility','off');
end

set(gca, 'XScale', 'log');
grid on; box on;
set(gca,'GridLineStyle',':','LineWidth',1,'FontSize',11);

xlabel('Number of stored memories $M$', 'Interpreter','latex');
ylabel('Mean Macro F1', 'Interpreter','latex');
title(sprintf('Retrieval performance vs. stored memories (\\alpha = %.2f)', alpha_target), ...
    'Interpreter','none');

legend('show','Location','southwest','Interpreter','latex','Box','off');

exportgraphics(fig1, fullfile(outdir, sprintf("F1_vs_M_alpha_%.2f.pdf", alpha_target)), ...
    'ContentType','vector');
exportgraphics(fig1, fullfile(outdir, sprintf("F1_vs_M_alpha_%.2f.png", alpha_target)), ...
    'ContentType','image');

disp('Fit parameters per N using model:');
disp(fit_model_str);
disp(fit_tbl);

% ============================================================
% Compute M*(N) for multiple thresholds using fitted (a,b)
% M* = exp((a - F1_thresh)/b)
% ============================================================
cap_tbl = table();
cap_tbl.N = fit_tbl.N;

for j = 1:numel(F1_thresholds)
    th = F1_thresholds(j);

    Mstar = exp((fit_tbl.a - th) ./ fit_tbl.b);

    % If b<=0, the model doesn't make sense (would imply F1 increases with M).
    % Mark those as NaN to avoid misleading points.
    Mstar(fit_tbl.b <= 0) = NaN;

    cap_tbl.(sprintf('Mstar_F1_%02d', round(100*th))) = Mstar;
end

% ============================================================
% Figure 2: Capacity M*(N) curves for multiple thresholds
% ============================================================
fig2 = figure('Color','w'); hold on;

mk = {'o-','s-','^-','d-','v-','>-','<-'}; % enough marker styles
for j = 1:numel(F1_thresholds)
    th = F1_thresholds(j);
    Mstar = cap_tbl.(sprintf('Mstar_F1_%02d', round(100*th)));

    plot(cap_tbl.N, Mstar, mk{1+mod(j-1,numel(mk))}, ...
        'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', 'w', ...
        'DisplayName', sprintf('$\\mathrm{F1}_{\\rm th}=%.2f$', th));
end

set(gca, 'XScale', 'log', 'YScale', 'log');
grid off; box on;
set(gca,'GridLineStyle',':','LineWidth',1,'FontSize',11);

xlabel("Network Size (N)"); ylabel("Capacity (M^*)");

% title(sprintf('Capacity scaling extracted from %s (\\alpha = %.2f)', fit_model_str, alpha_target));
title('Capacity scaling vs N for different F1 thresholds (\alpha = 0.10 fixed)')

legend('show','Location','northwest','Interpreter','latex','Box','off');

exportgraphics(fig2, fullfile(outdir, sprintf("Capacity_vs_N_multiThresh_alpha_%.2f.pdf", alpha_target)), ...
    'ContentType','vector');
exportgraphics(fig2, fullfile(outdir, sprintf("Capacity_vs_N_multiThresh_alpha_%.2f.png", alpha_target)), ...
    'ContentType','image');

disp('Capacity table (M* for each threshold):');
disp(cap_tbl);
