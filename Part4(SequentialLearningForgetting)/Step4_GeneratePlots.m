clc; clear;
scale50Flag = true;
N = 800;
    
if scale50Flag
    scaleFolder = 'Scaled50';
else
    scaleFolder = 'Constant50';
end
load(fullfile(pwd, 'Data', scaleFolder, "N"+num2str(N), 'FinalRepresentations.mat'));

%% Normalized Acitvity size with just participating cells
figure('Visible','off'); hold on;

% Set figure size and position in inches (e.g., 10 inches wide x 6 inches tall)
fig = gcf;
fig.Units = 'inches';
fig.Position = [1, 1, 12, 8];  % [x, y, width, height] in inches

% Optional: enlarge axes content to use more space
ax = gca;
ax.Position = [0.1 0.15 0.85 0.75];  % [left bottom width height]

% Set paper properties for saving
fig.PaperUnits = 'inches';
fig.PaperPosition = fig.Position;
fig.PaperSize = [fig.Position(3), fig.Position(4)];


mean_curve = nan(size(norm_A,1), 21, nTrials*(nMems-1) + 20*nTrials);
for iter = 1:size(norm_A,1)
    for mem = 1:21
        % Plot individual curves
        plot((nTrials+1:nMems*  nTrials) - mem*nTrials, squeeze(norm_A(iter, mem, nTrials+1:end)), '-', 'Color', 0.8*[1 1 1], HandleVisibility='off', LineWidth=0.1);
        
        % Construct aligned mean curve matrix
        mean_curve(iter, mem, :) = [nan(1, nTrials*(21-mem)), squeeze(norm_A(iter, mem, nTrials+1:end))', nan(1, (mem-1)*nTrials)];
    end
end

% Compute mean and std ignoring NaNs
x_values = (1:size(mean_curve, 3)) - 20 * nTrials; % x-axis values
mean_values = squeeze(nanmean(mean_curve, [1, 2])); % Mean of aligned curves
std_values = squeeze(nanstd(mean_curve, 0, [1, 2]));  % Std deviation of aligned curves

% Remove NaNs for plotting
valid_idx = ~isnan(mean_values); % Find valid indices
x_valid = x_values(valid_idx);   % Valid x values
mean_valid = mean_values(valid_idx); % Valid mean values
std_valid = std_values(valid_idx);   % Valid std values
numExperiments = squeeze(sum(~isnan(mean_curve), [1, 2]));
error = 1.96*std_valid ./ sqrt(numExperiments); 

% Plot the mean curve
plot(x_valid, mean_valid, 'Color', [0.8 0 0], 'LineWidth', 1.5, 'DisplayName', 'Mean'); 

% Plot the filled area for mean ± std
patch([x_valid, flip(x_valid)], [mean_valid - error; flip(mean_valid + error)], ...
     [1 0.4 0.4], 'FaceAlpha', 0.4, 'EdgeColor', 'none', 'DisplayName', 'Mean ± CI');

ymin = prctile(norm_A, 0.01, "all")-0.5; ymax = prctile(norm_A, 99, "all")+1;
% Background shading
for i = -10:110
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
        flag = 'off';
    else
        a = 0.1;
        c = 'k';
        flag = 'off';
    end
    if i == 49
        a = 0.2;
        c = 'g';
        flag = 'on';
    end
    patch(nTrials*(i-1-10) + [0, 0, nTrials, nTrials], [ymin, ymax, ymax, ymin], c, ...
         'EdgeColor', 'none', 'FaceAlpha', a, 'HandleVisibility', flag, DisplayName="onset of learning");
end

% Add labels and settings

ylabel("Response Time (ms)", 'FontWeight', 'bold', 'FontSize', 20);
text(0, ymin + 0.2, "Pre Learning", 'FontSize',20, 'FontWeight', 'bold')
text(60 * nTrials, ymin + 0.2, "Post Learning", 'FontSize',20, 'FontWeight', 'bold')

legend('Location', 'northwest', 'Box', 'off', 'FontSize', 12);
ax = gca; % Get the current axes handle
ax.TickLength = [0, 0];
xticks([]);
ylim([ymin, ymax])
xlim(20*nTrials* [-1 5])
title(sprintf("Single Memory Tracked During Sequential Learning\n N = %d, nSimulations = %d", N, size(norm_A,1)), 'FontSize', 22, 'FontWeight', 'bold');
xlabel("# New Memories", 'FontWeight', 'bold', 'FontSize', 20);

set(gca, 'FontSize', 20);  % Consistent large font

savePath = fullfile(pwd, 'Results', scaleFolder , "N" + num2str(N) );
if ~exist(savePath, 'dir')
    mkdir(savePath);
end

fig.PaperPositionMode = 'auto';
%Save high-resolution PNG
print(gcf, fullfile(savePath, "norm_A"), '-dpng', '-r600');

%Save high-quality PDF
print(gcf, fullfile(savePath, "norm_A"), '-dpdf', '-r600');
%% Participation Rate of Cells
figure('Visible','off'); hold on;

% Set figure size and position in inches (e.g., 10 inches wide x 6 inches tall)
fig = gcf;
fig.Units = 'inches';
fig.Position = [1, 1, 12, 8];  % [x, y, width, height] in inches

% Optional: enlarge axes content to use more space
ax = gca;
ax.Position = [0.1 0.15 0.85 0.75];  % [left bottom width height]

% Set paper properties for saving
fig.PaperUnits = 'inches';
fig.PaperPosition = fig.Position;
fig.PaperSize = [fig.Position(3), fig.Position(4)];


mean_curve_ex = nan(size(participation_ex,1), 21, nTrials*(nMems-1) + 20*nTrials);
mean_curve_inh = nan(size(participation_inh,1), 21, nTrials*(nMems-1) + 20*nTrials);

for iter = 1:size(participation_ex,1)
    for mem = 1:21
        if mod(mem, 1) == 0 && iter == 1
            plot((nTrials+1:nTrials*nMems) - mem*nTrials, squeeze(participation_ex(iter, mem, nTrials+1:end)/Ne), 'Color', 0.8*[1 1 1], HandleVisibility='off')
            plot((nTrials+1:nTrials*nMems) - mem*nTrials, squeeze(participation_inh(iter, mem, nTrials+1:end)/Ni), 'Color', 0.8*[1 1 1], HandleVisibility='off')
        end
        mean_curve_ex(iter, mem, :) = [nan(1, nTrials*(21-mem)), squeeze(participation_ex(iter, mem, nTrials+1:end)/Ne)', nan(1, (mem-1)*nTrials)];
        mean_curve_inh(iter, mem, :) = [nan(1, nTrials*(21-mem)), squeeze(participation_inh(iter, mem, nTrials+1:end)/Ni)', nan(1, (mem-1)*nTrials)];
    end
end

plot((1:size(mean_curve_ex, 3)) - nTrials*20, ...
     squeeze(nanmean(mean_curve_ex, [1, 2])), ...
     '-', 'LineWidth', 3, 'DisplayName', 'Mean Excitatory', 'Color', [0.2 0.4 0.8]);

plot((1:size(mean_curve_inh, 3)) - nTrials*20, ...
     squeeze(nanmean(mean_curve_inh, [1, 2])), ...
     '-', 'LineWidth', 3, 'DisplayName', 'Mean Inhibitory', 'Color', [0.8 0.2 0.2]);

ymin = prctile(mean_curve_ex, 0.01, "all"); ymax = prctile(mean_curve_ex, 99, "all");
ymin = 0.1*floor(ymin*10); ymax = 1;

% Background shading
for i = -10:110
    if mod(i, 2) == 0
        a = 0.05;
        c = 'k';
        flag = 'off';
    else
        a = 0.1;
        c = 'k';
        flag = 'off';
    end
    if i == 49
        a = 0.2;
        c = 'g';
        flag = 'on';
    end
    fill(nTrials*(i-1-10) + [0, 0, nTrials, nTrials], [ymin, ymax, ymax, ymin], c, ...
         'EdgeColor', 'none', 'FaceAlpha', a, 'HandleVisibility', flag, DisplayName="onset of learning");
end

xlim(20*nTrials* [-1 5])
ylim([ymin, 1]);
yticks(ymin:0.1:1);
yticklabels(ymin*100:10:100);
xlabel("# New Memories", 'FontWeight', 'bold', 'FontSize', 20);
xticks([]);
ylabel("Assembly Size (%)", 'FontSize', 20, 'FontWeight', 'bold');
legend('Location', 'south', 'FontSize', 12, 'Box', 'off');
text(0, ymin + 0.04, "Pre Learning", 'FontSize', 20, 'FontWeight', 'bold');
text(60 * nTrials, ymin + 0.04, "Post Learning", 'FontSize', 20, 'FontWeight', 'bold');
title(sprintf("Single Memory Tracked During Sequential Learning\n N = %d, nSimulations = %d", N, size(norm_A,1)), 'FontSize', 22, 'FontWeight', 'bold');

set(gca, 'FontSize', 20);  % Consistent large font
set(gcf, 'Color', 'w', 'PaperPositionMode', 'auto');    % White background

savePath = fullfile(pwd, 'Results', scaleFolder, "N"+num2str(N));
if ~exist(savePath, 'dir')
    mkdir(savePath);
end

%Save high-resolution PNG
print(gcf, fullfile(savePath, "assembly"), '-dpng', '-r600');

% Save high-quality PDF
print(gcf,  fullfile(savePath, "assembly"), '-dpdf', '-r600');
%% 
% % Your data
% idx = length(x_valid)/2-500:length(x_valid)-50000;
% x = x_valid(idx)'/nTrials;
% y = mean_valid(idx);
% 
% % Define model: exponential decay with offset
% ft = fittype('a*(1 - exp(-b*x)) + c', 'independent', 'x');
% 
% % Fit the model to data
% [fitresult, gof] = fit(x, y, ft, 'StartPoint', [1, 0.0001, 7]);
% 
% % Display parameters
% disp(fitresult)
% 
% % Plot the result
% figure; hold on; 
% plot(x_valid/nTrials, mean_valid)
% plot(fitresult, x, y)
% xlabel('x')
% ylabel('y')
% title('Exponential Decay Fit')
% legend('Data','Fitted Curve')
% 
