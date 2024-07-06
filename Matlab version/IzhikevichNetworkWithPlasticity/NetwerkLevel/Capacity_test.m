%% Configuring the network 
clear 
clc

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
mynet.stimulation = true;
mynet.sampling = false;

%% In Series Learning
% Feeding the stims to the network to learn (In series)
M_max = 10; % maximum number of memory to encode in the network
stims = []; 
interval = 100; %ms
N_trials = 1000;

for m = 1:M_max
    stims = [stims, Stimulation(mynet, interval, 2, 30, 50, 0)];
  
    mynet.run(N_trials*interval);
    mynet.stims = []; % clear the stims list as it slows down the computaiton speed
end
%%
% Retrieval of memories by just one stimulation per stim (In series)
N_retrievals = 15;
for m = 1:M_max
    stims(m).on = true;
    mynet.stims = [stims(m)];
    mynet.run(interval*N_retrievals)
end
%%
data = mynet.getData();
%% Parallel Learning
% Feeding the stims to the network to learn (In Parallel)
M_max = 5; % maximum number of memory to encode in the network
stims = []; 
interval = M_max*100; %ms
N_trials = 1000;

for m = 1:M_max
    stims = [stims, Stimulation(mynet, interval, 2, 30, 50, (m-1)*100)];
end 

mynet.run(N_trials * interval)

data = mynet.getData();

%% Computing the order vectors :)

firings = transpose(data.firings);
interval = 100; % ms 
off_set_time = 0;

%check_flag_save = zeros(round(mynet.t/interval), mynet.N);
%total_spike_count = zeros(1, round(mynet.t/interval));
%ex_neurons_engagement_count = zeros(1, round(mynet.t/interval));
%inh_neurons_engagement_count = zeros(1, round(mynet.t/interval));

f = waitbar(0, "Computing First to Spike Orders ...");
for trial_number = 10000:round(mynet.t/interval)
    % Computing the orders
    check_flag = zeros(1, mynet.N);
    
    indices = (firings(:, 1) > (trial_number-1) * interval + off_set_time) & (firings(:, 1) <= trial_number * interval + off_set_time);
    spike_times = firings(indices, 1) - (trial_number-1)*interval - off_set_time;
    neuron_indices = firings(indices, 2);    
    
    counter_ex = 1;
    counter_inh = mynet.Ne+1;
  
    neuron_sorted_indices = zeros(size(spike_times, 1), 1);
   
    for i = 1:length(spike_times)
        if true
            if neuron_indices(i) <= mynet.Ne
                if check_flag(neuron_indices(i)) == 0 % First excitatory spikes
                    neuron_sorted_indices(i) = counter_ex;
                    check_flag(neuron_indices(i)) = counter_ex;
                    counter_ex = counter_ex + 1;
                else % Repeated excitatory spikes
                    neuron_sorted_indices(i) = check_flag(neuron_indices(i));
                end
            else
                if check_flag(neuron_indices(i)) == 0 % First Inhibitory spikes
                    neuron_sorted_indices(i) = counter_inh;
                    check_flag(neuron_indices(i)) = counter_inh;
                    counter_inh = counter_inh + 1;
                else % Repeated Inhibitory spikes
                    neuron_sorted_indices(i) = check_flag(neuron_indices(i));
                end
            end
        end
    end
    
    check_flag_save(trial_number, :) = check_flag;
    total_spike_count(trial_number) =  length(spike_times);
    ex_neurons_engagement_count(trial_number) = sum(unique(neuron_indices)<=mynet.Ne);
    inh_neurons_engagement_count(trial_number) = sum(unique(neuron_indices)>mynet.Ne);
    
    waitbar(trial_number/round(mynet.t/interval), f, sprintf("Computing First to Spike Orders ..., trial %d", trial_number))
end

close(f)
%% Spearman Corr Matrix  Analysis (Poster Component)

%corrmat = 1-squareform(pdist(check_flag_save(1:1:end, 1:320), 'spearman')); % Replace this with your actual data

%temp = [];
%for m = 1:M_max
%    temp = [temp; check_flag_save(m:M_max:end, :)]; 
%end

corrmat = corr([check_flag_save(1:10000, 1:400); temp(:, 1:400)]','type', 'spearman');

submat = corrmat(1000:1000:end, 10001:5:10050);
%submat(logical(eye(size(submat, 1)))) = 0;

% Create the heatmap

figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed
fsize = 25; % font size


% Create axes with the desired position and size
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]

%imagesc(submat, 'Parent', ax, 'AlphaData', ~isnan(submat));
imagesc(submat, 'Parent', ax)
colormap(flipud(hsv));
c = colorbar;

% Adjust the position of the colorbar to the left
c.Units = 'normalized'; % Use normalized units
c.Position = [0.15, 0.2, 0.03, 0.6]; % [left, bottom, width, height]
% Move the colorbar title to the middle and set font properties

c.Label.String = 'Spearman Rank Correlation';
c.Label.Rotation = 90; % Rotate the label to be vertical
c.Label.Position = [-2, 0.3, 0]; % Adjust the position to be centered and beside the colorbar
c.Label.FontName = 'Arial'; % Set the font name
c.Label.FontSize = fsize; % Set the font size
c.Label.FontWeight = 'bold'; % Set the font weight to bold

% Set the title and axis labels with consistent font properties
xlabel('Learnt Sequence', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
ylabel('Learnt Sequence', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 90);

% Fix the aspect ratio to square
% axis square;

set(gca, 'YDir', 'normal')

% Define the x-tick positions and labels
% xTickPositions = 0:200:size(corrmat, 1);
% xTickPositions(1) = xTickPositions(1) + 1;
% xTickLabels = xTickPositions;

% Set the x-ticks and labels with consistent font properties
% xticks(xTickPositions);
% xticklabels(xTickLabels);
xtickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for x-tick labels

% Similarly, you can set y-ticks if needed
% yticks(xTickPositions);
% yticklabels(xTickLabels);
ytickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for y-tick labels

% Set x-ticks to top and y-ticks to right
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'right');


% Add text annotations for different phases using annotation
% Add arrows or lines to span the phases at the bottom of the plot
%starts = ([0, 1000, 1500, 2000]+25)*0.6/2500 + 0.2;
%ends = ([1000, 1500, 2000, 2500]-25)*0.6/2500 + 0.2;
%phases = ["Learning", "Stim + Noise", "Noise", "Stim + Noise"];
%for i = 1:length(phases)
%    annotation('line', [starts(i), ends(i)], [0.18 0.18], 'Color', 'black', 'LineWidth', 1.5); % Stimulation
%    annotation('textbox', [starts(i)/2+ends(i)/2 - 0.05, 0.1, 0.1, 0.05], 'String', phases(i), 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none')
%end

% Adjust paper size and position for saving as PDF
set(gcf, 'PaperPositionMode', 'auto');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 10 10]); % [left, bottom, width, height]
set(gcf, 'PaperSize', [10 10]); % [width, height]


title("First to Spike Orders Correlation Matrix", 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold')
% Save the figure as a PDF with higher resolution
% print(gcf, 'Spearman_Corr_Matrix.pdf', '-dpdf', '-vector', '-r300');
print(gcf, 'Spearman_Corr_Matrix.png', '-dpng', '-r300');
%% Order of spikes analysis (In input mode!)
figure('Name', "Single Neuron Spike Order")
fsize = 15;
temp = check_flag_save(1:end, :);
temp(temp == 0) = nan;

%active_ex_cells = find(temp(end, :) ~= 0 & temp(end, :) <= mynet.Ne);
%active_inh_cells = find(temp(end, :) ~= 0 & temp(end, :) > mynet.Ne);

stable_order_ex = check_flag_save(10045, 1:320);
stable_order_inh = check_flag_save(10045, 321:end)-320;
stable_order_ex(stable_order_ex == 0) = 320;
stable_order_inh(stable_order_inh == -320) = 80;

colormap_ex = jet(320);
colormap_ex = colormap_ex(stable_order_ex, :);

colormap_inh = jet(80);
colormap_inh = colormap_inh(stable_order_inh, :);

hold on 
wsize = 1.5;
for cell_id =1:320
    
    plot(temp(1:end, cell_id), 'color', colormap_ex(cell_id, :), LineWidth= wsize)
end
for cell_id = 321:400
    
    plot(temp(1:end, cell_id), 'color', colormap_inh(cell_id-320, :), LineWidth= wsize)
end

xlabel("Trial")
ylabel("Single Neuron Spike Order")
title("First to Fire Order Vector")
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
%% Raster plot in any time window (Poster Content)

figure('Name', "Raster Plot", 'Renderer', 'painters', 'Position', [100 100 1000 1000]); 
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
firings = data.firings;
fsize = 20;
start_time = 1000.5; % in seconds
end_time = 1002; % in seconds

ex_indices = ((firings(1, :)/1000 > start_time) & (firings(1, :)/1000 < end_time)) & (firings(2, :) <= 320);
inh_indices = ((firings(1, :)/1000 > start_time) & (firings(1, :)/1000 < end_time)) & (firings(2, :) > 320);

% stable_order = check_flag_save(1000, :);
% ex = stable_order(1:mynet.Ne) == 0;
% inh = stable_order(mynet.Ne+1:end) == 0;
% stable_order(logical([ex, zeros(1, mynet.Ni)])) = mynet.Ne-sum(ex)+1:mynet.Ne;
% stable_order(logical([zeros(1, mynet.Ne), inh])) = mynet.N - sum(inh)+1:mynet.N;
% 
% for i = 1:size(firings, 2)
%     firings(2, i) = stable_order(firings(2, i));
% end

plot(ax, firings(1, ex_indices)/1000, firings(2, ex_indices), 'b.', 'MarkerSize', 6)
hold on
plot(ax, firings(1, inh_indices)/1000, firings(2, inh_indices), 'r.', 'MarkerSize', 6)

xlabel("time (s)")
ylabel("neuron index")
title("After Learning (Just Noise Phase)")

y_starts = [0.2, 0.685];
y_ends = [0.675, 0.8];
phases = ["Excitatory", "Inhibitory"];
for i = 1:length(phases)
    annotation('line',[0.81 0.81], [y_starts(i), y_ends(i)], 'Color', 'Black', 'LineWidth', 3, LineStyle='-'); % Stimulation
    annotation('textbox', [0.83,  y_starts(i)/2 + y_ends(i)/2 - 0.05, 0.1, 0.01], 'String', phases(i), 'FontName', 'Arial', 'FontSize', 15, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'EdgeColor', 'none', Rotation=90)
end

ylim([0, mynet.N])
yticks([1, 50:50:300, 321, 360,400])
yticklabels([1, 50:50:300, 1, 40,80])
xlim([start_time end_time])
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');

%% Engagement of Cells Analysis


%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Population Analysis')

subplot(3, 1, 1)
hold on
plot(100* ex_neurons_engagement_count(1:1:end)/mynet.Ne)
%plot(100* ex_neurons_engagement_count(2:2:end)/mynet.Ne, DisplayName= 'memory 2')
%legend()

title("Excitatory Population Engagement")
xlabel('Trial')
ylabel('Engagement %')
%%%%%%%%%%%%%%%%%%%%%
subplot(3, 1, 2)
hold on
plot(100* inh_neurons_engagement_count(1:1:end)/mynet.Ni)
%plot(100* inh_neurons_engagement_count(2:2:end)/mynet.Ni, DisplayName= 'memory 2')
%legend()

title("Inhibitory Population Engagement")
xlabel('Trial')
ylabel('Engagement %')

%%%%%%%%%%%%%%%%%%%%%

subplot(3, 1, 3)
hold on
plot(total_spike_count(1:1:end))
%plot(total_spike_count(2:2:end), DisplayName= 'memory 2')
%legend()
title("Total Spike Count per Trial")
xlabel('Trial')
ylabel('Spike Count')
%%%%%%%%%%%%%%%%%%%%%

%% PCA on order vectors
% Perform PCA
[coeff, score, latent, tsquared, explained, mu] = pca(check_flag_save(1:M_max*N_trials, 1:400));

% coeff    - Principal component coefficients (eigenvectors)
% score    - Principal component scores (projected data)
% latent   - Principal component variances (eigenvalues)
% tsquared - Hotelling's T-squared statistic for each observation
% explained- Percentage of total variance explained by each principal component
% mu       - Estimated mean of each variable

x = score(:, 1);
y = score(:, 2);
z = score(:, 3);

mem_colors = hsv(M_max);
colors = [];
for m = 1:M_max
    colors = [colors; [flip(gray(999)); mem_colors(m, :)]];
end

figure;
ax1 = axes;
ax2 = axes;
ax2.Position = ax1.Position; % Align the second axes with the first
ax2.Color = 'none'; % Make the background of the second axes transparent
linkprop([ax1, ax2], {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'});


for m = 1:M_max
    indices = (m-1)*N_trials+1:m*N_trials;
    scatter3(x(indices), y(indices), z(indices),10, colors(indices, :), Marker="o", MarkerFaceColor="flat", HandleVisibility='off');
    hold on
end

hold on

indices = 1000:1000:M_max*1000;

scatter3(ax2, x(indices), y(indices), z(indices), 200, colors(indices, :), Marker="o", MarkerFaceColor="flat", DisplayName= "Learnt M", HandleVisibility='on');

%%%%%%%%%%%%%%%%% Plotting retrieved sequences
test_data_centered = bsxfun(@minus, temp, mu);
score = test_data_centered * coeff;
x = score(:, 1);
y = score(:, 2);
z = score(:, 3);

c = [];
for m = 1:M_max
    c = [c;repmat(mem_colors(m, :), N_retrievals, 1)];
end

scatter3(ax2, x, y, z, 150, c, marker="pentagram", MarkerFaceColor="flat", DisplayName='Retrieved M')


colormap(ax1, flipud(gray))
clim(ax1,[0 1000]);
cb1 = colorbar(ax1,'Position',[.05 .11 .0675 .810]);
ylabel(cb1, 'Trial Number');

colormap(ax2, mem_colors)
clim(ax2, [0 M_max]);
cb2 = colorbar(ax2,'Position',[.88 .11 .0675 .810]);
cb2.Ticks = 0.5:1:M_max-0.5;
cb2.TickLabels = 1:M_max ;
ylabel(cb2, 'Memories');

%%Then add colorbars and get everything lined up
set([ax1,ax2],'Position',[.17 .11 .685 .815]);


xlabel('PC 1');
ylabel('PC 2');
zlabel('PC 3')
title('Order Vector Evolution in PCA Space');
legend(Location='best')
%%
temp = [];
for i = 1:M_max
    indices = [10000+5*(i-1)+1:10000+5*i, 10050+15*(i-1)+1:10050+15*i];
    temp = [temp; check_flag_save(indices, :)];
end