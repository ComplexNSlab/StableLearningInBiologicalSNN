%% Configuring the network 
clear 
clc
rng(2,"twister");

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
mynet.stimulation = true;
mynet.sampling = false;
%% Imprinting A Single Memory without any noise

Stimulation(mynet, 100, 2, 30, 50, 0);
mynet.run(100000);
%% Loading the same state of system each time for different noise intensities to check the drop 
patch_number = 2;
rng(2,"twister");
sigma_ex = 0.9*5; sigma_inh = 0.9*2;
datas = [];
f = waitbar(0, "Please wait ...");
for i = 1:10
    mynet = load("Data" + filesep + "Jul_5_2024_20_17" + filesep + "Patch1", 'obj');
    mynet = mynet.obj;
    mynet.PatchNumber = patch_number;
    
    mynet.stims(1).on = false; % Turn off the stimulation
    mynet.noise = true; mynet.sigma_ex = sigma_ex; mynet.sigma_inh = sigma_inh;% Turn on the noise 
    
    for i = 1:100
        mynet.run(9900) % Run just with noise
        mynet.stims(1).on = true;
        mynet.noise = false;
        mynet.run(100); % Retrieve memory once
        mynet.stims(1).on = false;
        mynet.noise = true;
    end
    data = mynet.getData();
    datas = [datas, data];
    waitbar(i/10, f, sprintf("Repeatition : %d out of %d",i, 10));
end
close(f)

patch_number = mynet.PatchNumber;

%% Computing the order vectors :)

check_flag_saves = zeros(11000, 400, 10);

for i = 1:length(datas)
    temp = computeOrders(datas(i), mynet);
    check_flag_saves(:, :, i) = temp;
end

%%
corrs = zeros(10, 100);
for i = 1:10
    corrmat = corr(check_flag_saves(:, 1:400, i)','type', 'spearman');
    submat = corrmat(1000:100:end, 1000:100:end);
    corrs(i, :) = submat(1, 2:end);
end
%%
mean_corrs = mean(corrs, 1);
std_corrs = std(corrs, 1);
figure;
hold on
for i = 1:10
    scatter([1:100]*10, corrs(i, :), 10, "black",Marker="o", MarkerFaceColor="flat")
end
%errorbar([1:60]*5, mean_corrs, 0, 0, LineStyle="none", CapSize=20)
plot([1:100]*10, mean_corrs, LineWidth=5)
xlabel("Time after Learning Phase (ms)")
ylabel("Correlation of retrieved memory with learnt memory")
title("Stability of Memory facing Noise")
%% Spearman Corr Matrix  Analysis
submat = zeros(101,101);
for i = 1:10
    corrmat = corr(check_flag_saves(:, 1:400, i)','type', 'spearman'); 
    submat = submat + corrmat(1000:100:end, 1000:100:end);
end
submat = submat / 10;
submat(logical(eye(size(submat, 1)))) = max(triu(submat,1), [], "All");
%%
% Create the heatmap

figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed
fsize = 15; % font size


% Create axes with the desired position and size
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]

%imagesc(submat, 'Parent', ax, 'AlphaData', ~isnan(submat));
imagesc(submat, 'Parent', ax)
colormap(parula);
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
xlabel('Retrieved Sequence', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
ylabel('Retrieved Sequence', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 90);

set(gca, 'YDir', 'normal')

xtickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for x-tick labels

ytickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for y-tick labels

% Set x-ticks to top and y-ticks to right
set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'right');

% Adjust paper size and position for saving as PDF
set(gcf, 'PaperPositionMode', 'auto');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 10 10]); % [left, bottom, width, height]
set(gcf, 'PaperSize', [10 10]); % [width, height]


title("Correlation of Retrieved Sequences after Learning (Every 5ms)", 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold')

print(gcf, 'Spearman_Corr_Matrix.png', '-dpng', '-r300');
%% Order of spikes analysis 
figure('Name', "Single Neuron Spike Order")
fsize = 15;
temp = check_flag_saves([1:1000, 1100:100:end], :, 1);
temp(temp == 0) = nan;

%active_ex_cells = find(temp(end, :) ~= 0 & temp(end, :) <= mynet.Ne);
%active_inh_cells = find(temp(end, :) ~= 0 & temp(end, :) > mynet.Ne);

stable_order_ex = check_flag_save(1000, 1:320);
stable_order_inh = check_flag_save(1000, 321:end)-320;
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
%% Raster plot in any time window

figure('Name', "Raster Plot", 'Renderer', 'painters', 'Position', [100 100 1000 1000]); 
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
firings = data.firings;
fsize = 20;
start_time = 494; % in seconds
end_time = 495; % in seconds

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

%%
activation = zeros(101, 10);
for i = 1:10
    orders = check_flag_saves(1000:100:end, 1:320, i);
    activation(:, i) = sum(orders ~= 0, 2);
end

figure; 
hold on
for i = 1:10
    scatter([1:101]*10, activation(:, i), 5, 'black', MarkerEdgeColor='flat')
    hold on 
end
plot([1:101]*10, mean(activation, 2), '-', LineStyle='-', LineWidth=2);
yline(50, LineWidth=2, LineStyle="-", Color='red')
ylim([0 320])
xlim([0 1000])
xlabel("Retrieval time (ms)")
ylabel("Active Ex Cells")
title("# of Active Cells in Memory with Time (Noise on)")
set(gca, 'FontName', 'Arial', 'FontSize', 15, 'FontWeight', 'bold'); 
%% Functions

function check_flag_save = computeOrders(data, mynet)
    firings = transpose(data.firings);
    interval = 100; % ms 
    off_set_time = 0;
    
    check_flag_save = zeros(round(mynet.t/interval), mynet.N);
    %total_spike_count = zeros(1, round(mynet.t/interval));
    %ex_neurons_engagement_count = zeros(1, round(mynet.t/interval));
    %inh_neurons_engagement_count = zeros(1, round(mynet.t/interval));
    
    f = waitbar(0, "Computing First to Spike Orders ...");
    for trial_number = 1:round(mynet.t/interval)
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
        %total_spike_count(trial_number) =  length(spike_times);
        %ex_neurons_engagement_count(trial_number) = sum(unique(neuron_indices)<=mynet.Ne);
        %inh_neurons_engagement_count(trial_number) = sum(unique(neuron_indices)>mynet.Ne);
        
        waitbar(trial_number/round(mynet.t/interval), f, sprintf("Computing First to Spike Orders ..., trial %d", trial_number))
    end
    
    close(f)
end