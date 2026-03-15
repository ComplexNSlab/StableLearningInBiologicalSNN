
clear; clc;
memory = 60;
N = 1600; Ne = round(0.8*N); Ni = round(0.2*N);
nTrials = 1000; 
nMems = 100;
filename = fullfile(pwd, sprintf("Data/N%d/Trials%d/Apr_24_2025_11_09_45/Memory%dRecalls.mat", N, nTrials, memory));
load(filename)

%% Video of network first spike response to each trials 

figure();

p = plot(TTFS(:, 1), 1:N, 'k.');
xlim([2, 50]);
tl = title("");
xlabel("time, ms");

for trial = 1*nTrials:nMems*nTrials
    tl.String = sprintf("Memroy %d Response in Trial %d/%d while learning memory %d", memory, mod(trial, nTrials), nTrials, 1+floor(trial/nTrials));
    p.XData = TTFS(:, trial);

    pause(0.001);
end
%% Plotting first time to spike of some example cells separately
dt = TTFS(:, 2:end) - TTFS(:, 1:end-1);
dt2 = dt.*dt;
N_samples = 50; 
dist = 35;
selected_cells = randi(N, 1, N_samples);
figure; hold on; plot(TTFS(selected_cells, :)' + repmat(dist * (0:N_samples-1), nTrials*nMems, 1))

plot(repmat(dist * (0:N_samples-1), nTrials*nMems, 1), 'k-', HandleVisibility='off')
for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(nTrials*(i-1) + [0, 0, nTrials, nTrials], dist*N_samples* [0, 1, 1, 0], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end

yyaxis left
yticks(dist:dist:dist*N)
yticklabels(repmat([dist], 1, N))
ylim([0, N_samples*dist])
ylabel("Time to First Spike, ms")

yyaxis right
yticks(dist/2:dist:dist*N_samples)
yticklabels("cell " + string(selected_cells))
ylim([0, N_samples*dist])

xticks(nTrials/2:nTrials: nTrials*nMems)
xticklabels(1:100)

xlabel(sprintf("Memory Number Being Learnt (each has %d trials)", nTrials))
title("Response of Example Cells to Memory " + num2str(memory) + " recalls")

ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
%% Plotting first time to spike of all cells together
% Preprocess TTFS to ignore zeros
TTFS_no_zeros = TTFS;
TTFS_no_zeros(TTFS_no_zeros == 0) = NaN; % Replace zeros with NaN

% Plot data
% Calculate means
mean1 = nanmean(TTFS_no_zeros(Ne+1:end, :)', 2);
mean2 = nanmean(TTFS_no_zeros(1:Ne, :)', 2);

% Calculate standard deviations
std1 = nanstd(TTFS_no_zeros(321:end, :)', [], 2);
std2 = nanstd(TTFS_no_zeros(1:320, :)', [], 2);

% Define confidence intervals (mean ± 1.96*std for ~95% CI)
ci1_upper = mean1 + 1.96 * std1;
ci1_lower = mean1 - 1.96 * std1;
ci2_upper = mean2 + 1.96 * std2;
ci2_lower = mean2 - 1.96 * std2;

% Plot the mean and fill the CI
figure; hold on;
% CI for red plot
fill([1:length(mean1), fliplr(1:length(mean1))], [ci1_upper', fliplr(ci1_lower')], 'r', ...
    'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(mean1, 'r', 'LineWidth', 1.5, DisplayName= "Inhibitory");

% CI for blue plot
fill([1:length(mean2), fliplr(1:length(mean2))], [ci2_upper', fliplr(ci2_lower')], 'b', ...
    'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(mean2, 'b', 'LineWidth', 1.5, DisplayName= "Excitatory");

% Customize x-axis
xticks(nTrials/2:nTrials:nTrials*nMems);
xticklabels(1:100);
% Highlight regions
for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(nTrials*(i-1) + [0, 0, nTrials, nTrials], dist * [0, 1, 1, 0], c, 'EdgeColor', 'none', 'FaceAlpha', a, HandleVisibility='off')
end

legend()
ylabel("Time to First Spike, ms")
xlabel("Memory Number Being Learnt (each has 500 trials)")
ylim([0, 30])
title("First time to Spike of All Cells to Memory " + num2str(memory) + "Recalls, Averaged on Existing Cells")
set(gca, 'FontSize', 15)
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
%% Projection of Activity in Selected Memory PCA Subspace
figure; hold on;

n_last_trials = [50, 70, 100, 200, 400];
colors = lines(length(n_last_trials));
for i = 1:length(n_last_trials)
    data = TTFS(:, (500-n_last_trials(i):500) + (memory-1)*500)';
    [coeff_main, score, latent, tsquared, explained, mu] = pca(data);
    
   
    plot(cumsum(explained), 'o--', 'Color', colors(i, :), 'MarkerFaceColor', colors(i, :), ...
          DisplayName=num2str(n_last_trials(i)) + " last trials");
end
xlabel("Principal Components")
legend()
ylabel("Cumulative Varaince Explained, %")
xlim([0, 20])
title("Variance Curve of PCA for Last trials of learning a Memory")
set(gca, 'fontsize', 20)

n_last_trials = 500;
data = TTFS(:, (500-n_last_trials:500) + (memory-1)*500)';
[coeff_main, score, latent, tsquared, explained, mu] = pca(data);


figure; hold on;

for n_comps = [2, 3, 10, 20]
    coeff = coeff_main(:, 1:n_comps);
    % mathematical equation : data = score*coeff' + mu
    errors = zeros(1, 50000);
    
    mem_data = TTFS';
    mem_score = mem_data*coeff - mu*coeff;
    pred_data = mem_score*coeff' + mu;
    
    errors = 1 -  sum((pred_data - mem_data).^2, 2)./sum((mem_data-mean(mem_data, 2)).^2, 2);
    % errors = nanmean(100*abs((mem_data - pred_data)./mem_data), 2);
    
    plot(errors, '-', DisplayName=num2str(n_comps) + " PC comps")
end

for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(500*(i-1) + [0, 0, 500, 500], 1.2*max(errors) * [-1, 1, 1, -1], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end

xticks(250:500:50000)
xticklabels(1:100)

ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
ylim(1.2*max(errors)*[-0.1, 1])
ylabel("Coefficient of Determination R^2")
xlabel("Memory Response while learning other memories")
legend()
title("Projection of Memory " + num2str(memory) + " responses into the learnt responses PCA Subspace")
set(gca, 'fontsize', 17)
%% cosine angle of responses with the reference response (learnt one)

cos_ang = sum(TTFS .* TTFS(:, memory*500), 1)./(sqrt(sum(TTFS.^2, 1)) *sqrt(sum(TTFS(:, memory*500).^2)) );

figure;hold on; plot(1:50000, 180*acos(cos_ang)/pi)
xticks(250:500:50000)
xticklabels(1:100)


for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(500*(i-1) + [0, 0, 500, 500], 70 * [-1, 1, 1, -1], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
ylim([0, 70])
ylabel("angle, degree")
xlabel("Memory Number Being Learnt (each has 500 trials)")
title("cosine angle of responses with the reference response (learnt one)")
set(gca, 'fontsize', 17)
%% Consecutive cosine angle of responses 

step = 1;
sliced_TTFS = TTFS(:, 1: step:end);
cos_ang = sum(sliced_TTFS(:, 1:end-1) .* sliced_TTFS(:, 2:end), 1)./(sqrt(sum(sliced_TTFS(:, 1:end-1).^2, 1)) .*sqrt(sum(sliced_TTFS(:, 2:end).^2)) );

figure;hold on; plot(1:step:50000-step, 180*acos(cos_ang)/pi, '.-')
xticks(250:500:50000)
xticklabels(1:100)


for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(500*(i-1) + [0, 0, 500, 500], 70 * [-1, 1, 1, -1], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
ylim([0, 70])
ylabel("angle, degree")
xlabel("Memory Number Being Learnt (each has 500 trials)")
title("Consecutive cosine angle of responses")
set(gca, 'fontsize', 17)

%% Effect of Not fired Cells Timing Value on Norm of Timing Vector
figure; hold on;
plot(sqrt(sum(TTFS, 1))/max(sqrt(sum(TTFS, 1)), [], 'all'), DisplayName="zero", LineWidth=1)

for large = [10, 20, 100, 1000, 10^18]
    TTFS_copy = TTFS;
    TTFS_copy(TTFS == 0) = large;
    plot(sqrt(sum(TTFS_copy, 1))/max(sqrt(sum(TTFS_copy, 1)), [], 'all'), DisplayName= num2str(large) + " ms", LineWidth=1)
end

for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(500*(i-1) + [0, 0, 500, 500], 1* [0, 1, 1, 0], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end
legend(Location="southwest")
ylabel("Norm of Timing Vector Scaled to 1")
xticks(250:500:50000)
xticklabels(1:100)

ylabel("Scaled Norm")
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
xlabel("Memory Number Being Learnt (each has 500 trials)")
title("Effect of Not fired Cells Timing Value on Norm of Timing Vector")
set(gca, 'fontsize', 17)

%% Computing cos angles (respect to global reference + consecutively)

step = 1;

cos_ang = zeros(21, 50000);
cos_ang_consec = zeros(21, floor(50000/step)-1);
norm_A = zeros(21, 50000);
participation_ex = zeros(21, 50000);
participation_inh = zeros(21, 50000);

for sim = 1:length()
for memory = 40:60
    load("C:\Users\Arshia\Desktop\StableLearningInBiologicalSNN\PrePostLearningDifferenceInSequentialLearning\Data\" + filename + "\Memory" + num2str(memory)  + "Recalls.mat")


    sliced_TTFS = TTFS(:, 1: step:end);
    cos_ang_consec(memory-39, :) = sum(sliced_TTFS(:, 1:end-1) .* sliced_TTFS(:, 2:end), 1)./(sqrt(sum(sliced_TTFS(:, 1:end-1).^2, 1)) .*sqrt(sum(sliced_TTFS(:, 2:end).^2)) );

    participation_ex(memory-39, :) = sum(TTFS(1:320, :) ~= 0, 1);
    participation_inh(memory-39, :) = sum(TTFS(321:end, :) ~= 0, 1);

    norm_A(memory-39, :) = vecnorm(TTFS, 2, 1) ./ sqrt((400 - sum(TTFS == 0, 1)));
    cos_ang(memory-39, :) = sum(TTFS .* TTFS(:, memory*500), 1)./(sqrt(sum(TTFS.^2, 1)) *sqrt(sum(TTFS(:, memory*500).^2)) );
end

cos_ang(cos_ang > 1) = 1;
angles = 180*acos(cos_ang)/pi;

cos_ang_consec(cos_ang_consec > 1) = 1;
angles_consec = 180*acos(cos_ang_consec)/pi;

%% statistics for angle between responses respect to global reference

figure; hold on;

% Initialize a matrix to store shifted curves
shifted_curves = nan(21, 100000); % Adjust size depending on angles

% Plot shifted curves
for i = 1:21
    shift = (-24999:25000) - (i-1)*500; % Define x-axis shifts
    plot(shift, smooth(angles(i, :)',1), 'k-', HandleVisibility='off'); % Individual curves
    shifted_curves(i, shift+50000) = angles(i, :);
end



% % Plot the average curve in red
plot((1:size(shifted_curves, 2))-50000, nanmean(shifted_curves, 1), 'r-', 'LineWidth', 2, 'DisplayName', 'Average Curve');

% Add background shading
for i = 1:200
    if mod(i, 2) == 0
        a = 0.05; c = 'k';
    else
        a = 0.1; c = 'k';
    end
    fill(500*(i-1) + [0, 0, 500, 500]-50000, 70 * [0, 1, 1, 0], c, ...
         'EdgeColor', 'none', 'FaceAlpha', a, 'HandleVisibility', 'off');
end

% Axis properties
xlabel('Time Shift')
ylabel('Angles, Degree')
title('Cos Angle Respect to Learnt Sequence while Learning Other memories (Ensemble on 21 Memories)')
legend('show');

ylim([0 70])
xlabel("Memories Being Learnt")
xticks([])
xlim([-40000, 30000])
set(gca, 'fontsize', 20)

%% statistics for angle between responses consecutively
figure; hold on;

% % Initialize a matrix to store shifted curves
% shifted_curves = nan(1, size(angles_consec, 2)); % Adjust size depending on angles

% Plot shifted curves
for i = 1:21
    shift = (-24999:step:25000-step) - (i-1)*500; % Define x-axis shifts
    plot(shift, angles_consec(i, :)', 'k-', 'Color', 0.7*[1 1 1], HandleVisibility='off'); % Individual curves
    % shifted_curves() = shifted_curves + angles_consec(i, :);
end


% % Plot the average curve in red
% plot((1:size(shifted_curves, 2))-50000, nanmean(shifted_curves, 1), 'r-', 'LineWidth', 2, 'DisplayName', 'Average Curve');

% Add background shading
for i = 1:200
    if mod(i, 2) == 0
        a = 0.05; c = 'k';
    else
        a = 0.1; c = 'k';
    end
    fill(500*(i-1) + [0, 0, 500, 500]-50000, 70 * [0, 1, 1, 0], c, ...
         'EdgeColor', 'none', 'FaceAlpha', a, 'HandleVisibility', 'off');
end

% Axis properties
xlabel('Time Shift')
ylabel('Angles, Degree')
title('ConsecutiveCos Angle while Learning Other memories (Ensemble on 21 Memories)')
legend('show');

ylim([0 30])
xlabel("Memories Being Learnt")
xticks([])
xlim([-40000, 30000])
set(gca, 'fontsize', 20)

%% Delta Angle after each learning
final_angles = angles(:, 500:500:end);
delta_A = angles(:, 500:500:end)- angles(:, 1:500:end);
figure;
imagesc(delta_A)
cb = colorbar();

 
xlabel("Learning Procedure of 100 memories")
ylabel("# Memory")
yticks(1:21)
yticklabels(40:60)
cb.Label.String = "Angle Difference, Degree";
title("Consecutive Angle difference \DeltaA Calculated")

set(gca, 'fontsize', 17)

%% Delta_A in time after each learning for 21 observed memories

past_A = [];
future_A = [];
x_past = [];
x_future = [];

figure; hold on;
delta_A = delta_A(:, 2:end);
% Loop to collect past and future data
for m = 40:60
    % Past data
    past_A = [past_A, delta_A(m-39, 1:m-1)];
    x_past = [x_past, (1:m-1) - (m-1) - 1];
    scatter((1:m-1) - (m-1) - 1, delta_A(m-39, 1:m-1), 'r', HandleVisibility='off');

    % Future data
    future_A = [future_A, delta_A(m-39, m:end)];
    x_future = [x_future, (m:99) - m + 1];
    scatter((m:99) - m + 1, delta_A(m-39, m:end), 'b', HandleVisibility='off');

    % plot((1:99) - m, cumsum(delta_A(m-39, :)), 'k.-', HandleVisibility='off')
end

% Compute average past and future curves
[x_past_unique, ~, idx_past] = unique(x_past); % Align x-past
avg_past = accumarray(idx_past, past_A', [], @mean);

[x_future_unique, ~, idx_future] = unique(x_future); % Align x-future
avg_future = accumarray(idx_future, future_A', [], @mean);

% Plot average curves
plot(x_past_unique, avg_past, 'r-', 'LineWidth', 5, 'DisplayName', 'Average Past');
plot(x_future_unique, avg_future, 'b-', 'LineWidth', 5, 'DisplayName', 'Average Future');
% plot(x_past_unique, cumsum(avg_past), 'r-.', 'LineWidth', 3, 'DisplayName', 'Cumulative Average Past');
% plot(flip(x_future_unique), -cumsum(flip(avg_future)), 'b-.', 'LineWidth', 3, 'DisplayName', 'Cumulative Average Future');
plot([x_past_unique, x_future_unique], cumsum([avg_past', avg_future']), 'g*-', 'LineWidth', 3, 'DisplayName', 'Cumulative Average');


% Customize plot
grid on;

legend('show');

title("\DeltaA before and after leanring for 21 memories(40 to 60)")
ylabel("\DeltaA")
xlabel("")

set(gca, 'fontsize', 18)
%% histogram of past and future Delta_A s
figure;
subplot(2, 1, 1); hold on;
h = histogram(past_A, 100, DisplayName = "Past");
plot(mean(past_A)* [1 1], max(h.BinCounts)*[0, 1.2], 'r-', LineWidth=2,  DisplayName="Mean = " + num2str(mean(past_A)))
legend()
xlabel("\DeltaA, Degree")
ylabel("Hist Count");
title("Future \DeltaA histogram for 21 memories(40 to 60)")

xlim([-15, 15])
set(gca, 'fontsize', 20)

subplot(2, 1, 2); hold on;
histogram(future_A, 100, DisplayName = "Future")
plot(mean(future_A)* [1 1], max(h.BinCounts)*[0, 1.2], 'r-', LineWidth=2,  DisplayName="Mean = " + num2str(mean(future_A)))

legend()
xlabel("\DeltaA, Degree")
xlim([-15, 15])
ylabel("Hist Count");

set(gca, 'fontsize', 20)
%% Computing Jaccard similarity between memories 50 cells
addpath 'C:\Users\SeyedArshia.Razavi\Desktop\StableMemoriesWithUnstableSynapses\Matlab version\IzhikevichNetworkWithPlasticity\NetwerkLevel';
load("C:\Users\SeyedArshia.Razavi\Desktop\StableMemoriesWithUnstableSynapses\Matlab version\IzhikevichNetworkWithPlasticity\NetwerkLevel\PrePostLearningDifferenceInSequentialLearning\Data\" + filename + "\Stims.mat");


J_dists = zeros(21, 100);
for m = 40:60
    A = stims(m).pattern_indices;
    for M = 1:100
        B = stims(M).pattern_indices;
        jaccard_similarity = length(intersect(A, B)) ;
        J_dists(m-39, M) = jaccard_similarity;
    end
end

figure;
subplot(2, 1, 1);
histogram(J_dists, 100)
xlabel("Jaccard Smilarity (intersection size)")
ylabel("Bin Count")
title("Spread of Jaccard Similarities")
set(gca, 'fontsize', 17)

subplot(2, 1, 2); axis tight; axis square;
imagesc(J_dists)
cb = colorbar();
xlabel("Memory Number")
ylabel("Reference Memory")
yticks(1:21)
yticklabels(40:60)
cb.Label.String = "Jaccard Similarity";
title("Jaccard Similarity of 50 cells respect to each memories (40 to 60)")
clim([0 max(J_dists, [], 'all')])

set(gca, 'fontsize', 17)

%%
figure; hold on;
X = []; Y = [];
for m = 40:60
    x = delta_A(m-39, m+5:end); y = J_dists(m-39, m+5:end);
    X = [X, x]; Y = [Y,  y];
    scatter(x, y, 'ko', HandleVisibility='off')
    % plot(delta_A(m-39, :), J_dists(m-39, 2:100), 'k-')
end

Y = Y(X>-10 & X<10);
X = X(X>-10 & X<10);
[P, S, mu] = polyfit(X, Y, 1);
x_fit = linspace(min(X), max(X), 100); % Range of X for the fit line
y_fit = polyval(P, x_fit);
equation_str = sprintf('y = %.2fx + %.2f', P(1), P(2));
plot(x_fit, y_fit, 'r--', 'LineWidth', 2, 'DisplayName', equation_str); % Fit line

xlabel("\DeltaA, Degree")
ylabel("Jaccard Similarty")
title("Jaccard Similarity Vs \DeltaA for memories (40 to 60) ")
set(gca, 'fontsize', 20)
% ylim([0 16])
legend()
% xlim([-10 10])
%%
x_range = linspace(min(X), max(X), 500);
y_range = linspace(min(Y), max(Y), 500); 
[X_grid, Y_grid] = meshgrid(x_range, y_range);

grid_points = [X_grid(:), Y_grid(:)];

data = [X(:), Y(:)]; % Combine X and Y data into a 2D array
[f, xi] = ksdensity(data, grid_points, 'Kernel', 'triangle'); 

F = reshape(f, size(X_grid));

figure;
contourf(X_grid, Y_grid, F, 20, 'LineColor', 'none'); % 20 contour levels
colorbar; % Add color bar to visualize density
hold on;

title("Jaccard Similarity Vs \DeltaA for memories (40 to 60) ")

xlabel("\DeltaA, Degree")
ylabel("Jaccard Similarty")
set(gca, 'fontsize', 20)

scatter(X, Y, 10, 'w', 'filled', 'MarkerFaceAlpha', 0.1);
set(gca, 'FontSize', 14);

%% Analyzing consecutive angles between responses
mem = 45;
figure;hold on;
k_size = 0.00001;

yyaxis right
plot(cumsum(smooth(angles_consec(mem-39, :), k_size)), DisplayName="cumulative d\theta", Color=0.7* [0 0 1], LineStyle='-', LineWidth=2)
ylabel("Cumulative d\theta, Degree")

yyaxis left; hold on;
plot(smooth(angles_consec(mem-39, :), k_size), DisplayName="d\theta", Color='b')
% plot(cumsum(smooth(angles_consec(mem-39, :), k_size)), HandleVisibility="off")

dddd = angles(mem-39, 2:end)-angles(mem-39, 1:end-1);
plot(smooth(dddd, k_size), DisplayName="d\theta_{ref}", Color='r', LineStyle= '-')
plot(cumsum(smooth(dddd, k_size)), DisplayName="cumulative d\theta_{ref}", Color=0.7* [1 0 0], LineStyle='-', LineWidth=2)

legend()
title(sprintf("Changes in Memory %d Responses In time", mem))
ylabel("Angle, Degree")
xlabel("Memory Number Being Learnt")
for i = 1:100
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == mem
        a = 0.3;
        c = 'g';
    end
    fill(500*(i-1) + [0, 0, 500, 500], 70 * [-1, 1, 1, -1], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
xticks(250:500:50000)
xticklabels(1:100)
set(gca, 'fontsize', 15)
%% dtheta ref versus dtheta consecutive
figure; hold on;
X = []; Y = [];

for mem = 40
    colors = [repmat([1 0 0], (mem-1)*500, 1); repmat([0 1 0], 500, 1); repmat([0 0 1], (100-mem)*500-1, 1)];
    dddd = angles(mem-39, 2:end)-angles(mem-39, 1:end-1);
    scatter(dddd(mem*500+1:end), angles_consec(mem-39, mem*500+1:end), 4, 'r', 'filled', DisplayName="Post Learning")    
    scatter(dddd(1:(mem-1)*500), angles_consec(mem-39, 1:(mem-1)*500), 4, 'k', 'filled', DisplayName="Pre Learning")
    scatter(dddd((mem-1)*500+1:mem*500), angles_consec(mem-39,(mem-1)*500+1:mem*500), 20, 'b', 'filled', DisplayName="Learning")


    X = [X, dddd]; Y = [Y, angles_consec(mem-39, :)];
end

legend()
title(sprintf("Memory %d Responses In time", mem))
xlabel("d\theta_{ref}, Degree")
ylabel("d\theta, Degree")
xlim([-2, 2])
ylim([0, 20])
set(gca, 'fontsize', 20)

%% Normalized Acitvity size with just participating cells
figure; hold on;

mean_curve = nan(21, 60000);
for mem = 1:21
    % Plot individual curves
    plot((501:50000) - mem*500, norm_A(mem, 501:end), '-', 'Color', 0.7*[1 1 1], HandleVisibility='off');
    
    % Construct aligned mean curve matrix
    mean_curve(mem, :) = [nan(1, 500*(21-mem)), norm_A(mem, 501:end), nan(1, mem*500)];
end

% Compute mean and std ignoring NaNs
x_values = (1:60000) - 10000; % x-axis values
mean_values = nanmean(mean_curve); % Mean of aligned curves
std_values = nanstd(mean_curve);  % Std deviation of aligned curves

% Remove NaNs for plotting
valid_idx = ~isnan(mean_values); % Find valid indices
x_valid = x_values(valid_idx);   % Valid x values
mean_valid = mean_values(valid_idx); % Valid mean values
std_valid = std_values(valid_idx);   % Valid std values

% Plot the mean curve
plot(x_valid, mean_valid, 'r', 'LineWidth', 3, DisplayName="Mean Response Size");

% Plot the filled area for mean ± std
fill([x_valid, flip(x_valid)], [mean_valid - std_valid, flip(mean_valid + std_valid)], ...
     'r', 'FaceAlpha', 0.4, 'EdgeColor', 'none', HandleVisibility='off');

% Background shading
for i = -10:110
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    fill(500*(i-1-10) + [0, 0, 500, 500], [8, 14, 14, 8], c, ...
         'EdgeColor', 'none', 'FaceAlpha', a, 'HandleVisibility', 'off');
end

% Add labels and settings
ylabel("Norm Activity, ms");
text(0, 9.2, "Pre Learning", 'FontSize',20, 'FontWeight', 'bold')
text(30000, 9.2, "Post Learning", 'FontSize',20, 'FontWeight', 'bold')

% smooth_data = smooth(mean_valid, 2000);
% plot((1:length(smooth_data)) - 10000, smooth_data, 'g-', LineWidth=4, DisplayName="Smoothed Mean")


legend()
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
xticks([]);
ylim([9, 14])
xlim(10000* [-1 5])
title("Normalized Norm Activity of Only Participating Cells in The Responses")
set(gca, 'fontsize', 20)

%% Participation Rate of Cells
figure; hold on;

mean_curve_ex = nan(21, 100000);
mean_curve_inh = nan(21, 100000);

for mem = 1:21
    plot((501:50000) - mem*500, participation_ex(mem, 501:end)/320, 'Color', 0.8*[1 1 1], HandleVisibility='off')
    plot((501:50000) - mem*500, participation_inh(mem, 501:end)/80, 'Color', 0.8*[1 1 1], HandleVisibility='off')
    mean_curve_ex(mem, 50000 + (501:50000) - mem*500) = participation_ex(mem, 501:end)/320;
    mean_curve_inh(mem, 50000 + (501:50000) - mem*500) = participation_inh(mem, 501:end)/80;
end

plot((1:100000) - 50000, nanmean(mean_curve_ex), 'b-', LineWidth=3, DisplayName="Mean Ex Participation")
plot((1:100000) - 50000, nanmean(mean_curve_inh), 'r-', LineWidth=3, DisplayName="Mean Inh Participation")

ylabel("Active Percentage %")
for i = -10:110
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == 49
        a = 0.4;
        c = 'g';
    end

    fill(500*(i-1-10) + [0, 0, 500, 500], [0, 1, 1, 0], c, ...
         'EdgeColor', 'none', 'FaceAlpha', a, 'HandleVisibility', 'off');
end
ylim([0.2, 1])
xlim(10000* [-1 5])
xticks([])
yticks(0:0.1:1)
yticklabels(0:10:100)
legend()
text(0, 0.25, "Pre Learning", 'FontSize',20, 'FontWeight', 'bold')
text(30000, 0.25, "Post Learning", 'FontSize',20, 'FontWeight', 'bold')
title("Participation of Cells in Respones on Ensemble of Memories (40 to 60)")
set(gca, 'fontsize', 20)

%% 
addpath 'C:\Users\SeyedArshia.Razavi\Desktop\StableMemoriesWithUnstableSynapses\Matlab version\IzhikevichNetworkWithPlasticity\NetwerkLevel';

w_record = zeros(i, 400, 400);
for i = 1:100
    load("C:\Users\SeyedArshia.Razavi\Desktop\StableMemoriesWithUnstableSynapses\Matlab version\IzhikevichNetworkWithPlasticity\NetwerkLevel\PrePostLearningDifferenceInSequentialLearning\Data\" + filename + "\ttfs_mem" + num2str(i) + ".mat", "mynet")

    w_record(i, :, :) = mynet.w;
end
%%
ex_synapses = w_record(:, 1:320, 1:320);
ex_synapses = ex_synapses(:,  mynet.Adjacency_matrix(1:320, 1:320));

figure; hold on;
% plot(mean(ex_synapses, 2), 'ko-')
% plot(sum(ex_synapses > 2.9, 2), 'r')
imagesc(ex_synapses')
cb = colorbar();
% % for i = 1:6400
% for i = 1:20
%     plot(ex_synapses(:, randi(6400)), 'o-')
% end
%%
mat = 1- squareform(pdist(ex_synapses, 'cosine'));
mat(boolean(eye(length(mat)))) = nan;
figure;
imagesc(acos(mat)*180/pi);
cb = colorbar();
cb.Label.String = "Angle, Degree";
%% Theta_ref VS Norm Activity space trajectory of a single memory
figure; hold on;

for mem = 40:60
    colors = [repmat([1 0 0], (mem-2)*500, 1); repmat([0 1 0], 500, 1); repmat([0 0 1], (100-mem)*500, 1)];
    plot(angles(mem-39, 501:end), norm_A(mem-39, 501:end), 'Color', 0.8*[1 1 1], HandleVisibility='off')
    scatter(angles(mem-39, 501:end), norm_A(mem-39, 501:end), 10, colors, 'filled', HandleVisibility='off')
end

xlabel("\theta_{ref}(t), Degree")
ylabel("Norm Response (t), ms")
title("Trajectory of All Memories Responses in \theta_{ref} and Norm activity Space")

scatter([], [], 'r', 'filled', DisplayName="Pre Learning")
scatter([], [], 'b',  'filled',DisplayName="Post Learning")
scatter([], [], 'g', 'filled', DisplayName="Learinng")

legend(Location='best')
set(gca, 'fontsize', 25)

%% Theta_ref VS Norm Activity space trajectory of a single memory
figure; hold on;
d_norm_A = norm_A(:, 2:end)-norm_A(:, 1:end-1);

for mem = 45
    colors = [repmat([1 0 0], (mem-2)*500, 1); repmat([0 1 0], 500, 1); repmat([0 0 1], (100-mem)*500-1, 1)];
    dddd = angles(mem-39, 2:end)-angles(mem-39, 1:end-1);
    
    % plot(d_norm_A(mem-39, 501:end), dddd(501:end), 'Color', 0.8*[1 1 1], HandleVisibility='off')
    scatter(d_norm_A(mem-39, 501:end), dddd(501:end), 5, colors, 'filled', HandleVisibility='off')
end

ylabel("d\theta_{ref}(t), Degree")
xlabel("\Delta Norm Response (t), ms")
% title("Trajectory of All Memories Responses in \theta_{ref} and Norm activity Space")
% 
% scatter([], [], 'r', 'filled', DisplayName="Pre Learning")
% scatter([], [], 'b',  'filled',DisplayName="Post Learning")
% scatter([], [], 'g', 'filled', DisplayName="Learinng")

% legend(Location='best')
set(gca, 'fontsize', 25)
%%
figure; hold on;

d_norm_A = norm_A(:, 2:end) - norm_A(:, 1:end-1);

for mem = 45
    % Colors for scatter points
    colors = [repmat([1 0 0], (mem-2)*500, 1); repmat([0 1 0], 500, 1); repmat([0 0 1], (100-mem)*500-1, 1)];
    dddd = angles(mem-39, 2:end) - angles(mem-39, 1:end-1);
    
    % Extract data for KDE and scatter plot
    x_data = d_norm_A(mem-39, 501:end);
    y_data = angles_consec(mem-39, 501:end);
    y_data = dddd(501:end);

    % % Kernel density estimation
    % x_range = linspace(-0.1, 0.1, 100);
    % y_range = linspace(-0.8, 0.8, 100);
    % [X_grid, Y_grid] = meshgrid(x_range, y_range);
    % grid_points = [X_grid(:), Y_grid(:)];
    % [density, xi] = ksdensity([x_data', y_data'], grid_points);
    % 
    % % Reshape density for contour plot
    % F = reshape(density, size(X_grid));
    % contourf(X_grid, Y_grid, F, 20, 'LineColor', 'none');
    % colormap(parula);
    % colorbar;
    
    % Scatter plot
    scatter(x_data, y_data, 100, colors, 'filled', 'HandleVisibility', 'off');
end

% Labels and settings
title("Trajectory of Memory " + num2str(mem))
ylabel("d\theta(t), Degree");
xlabel("\Delta Norm Response (t), ms");
set(gca, 'fontsize', 25);
%%
figure; hold on;

% Extract 2D data
d_norm_A = norm_A(:, 2:end) - norm_A(:, 1:end-1);

for mem = 45
    % Data for histogram
    x_data = d_norm_A(mem-39, 501:end);
    y_data = angles(mem-39, 2:end) - angles(mem-39, 1:end-1);
    y_data = y_data(501:end);
end

% Bin edges
x_edges = linspace(min(x_data), max(x_data), 200); % Adjust bin count as needed
y_edges = linspace(min(y_data), max(y_data), 200);

% Compute 3D histogram
hist_counts = hist3([x_data', y_data'], 'Edges', {x_edges, y_edges});

% Plot 3D histogram as bars
h = bar3(hist_counts);
for k = 1:length(h)
    z_data = h(k).ZData;
    h(k).CData = z_data; % Use z-data for color mapping
    h(k).FaceColor = 'interp'; % Interpolated colors
end

% Labels and settings
xlabel('\Delta Norm Response (t), ms');
ylabel('d\theta_{ref}(t), Degree');
zlabel('Count');
title('3D Histogram of Scatter Points');
colormap(parula);
colorbar;

% Adjust view
view(3); % Set to 3D view
grid on;
set(gca, 'fontsize', 15);
%%
figure; hold on;
mem = randi(21) + 39;
colors = [repmat([1 0 0], (mem-2)*500, 1); repmat([0 1 0], 500, 1); repmat([0 0 1], (100-mem)*500, 1)];

plot(norm_A(mem-39, 501:end), participation_ex(mem-39, 501:end) + participation_inh(mem-39, 501:end), 'color', 0.8*[1 1 1])
scatter(norm_A(mem-39, 501:end), participation_ex(mem-39, 501:end) + participation_inh(mem-39, 501:end), 10, colors, 'filled')
%%
curves = nan(21, 60000);
for memory = 40:60
    load("C:\Users\SeyedArshia.Razavi\Desktop\StableMemoriesWithUnstableSynapses\Matlab version\IzhikevichNetworkWithPlasticity\NetwerkLevel\PrePostLearningDifferenceInSequentialLearning\Data\" + filename + "\Memory" + num2str(memory)  + "Recalls.mat")
    TTFS(TTFS == 0) = nan;
    ref = TTFS(:, 500*memory);
    % diff = 0.01*(TTFS - ref);
    % diff = nanmean(abs(diff), 1);
    diff = sum(~isnan(TTFS) & ~isnan(ref), 1);
    curves(memory - 39, (1:length(diff2)) - 500 *(memory-40) + 10000) = diff;
end
%%
figure; hold on;

plot(1:size(curves, 2), curves', linewidth = 0.2)

plot(nanmean(curves, 1), 'r', linewidth = 4)
for i = 1:120
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
    else
        a = 0.1;
        c = 'k';
    end
    if i == memory
        a = 0.3;
        c = 'g';
    end
    fill(500*(i-1) + [0, 0, 500, 500], 0.2 * [0, 1, 1, 0], c, 'EdgeColor','none', 'FaceAlpha', a, HandleVisibility='off')
end

xticks([])
text(10000, 0.25, "Pre Learning", 'FontSize',20, 'FontWeight', 'bold')
text(40000, 0.25, "Post Learning", 'FontSize',20, 'FontWeight', 'bold')

title("Average Response Time Shift per Cell (ensemble on 21 memories)")
ylabel("time shift per cell, ms")
set(gca, 'fontsize', 20)
