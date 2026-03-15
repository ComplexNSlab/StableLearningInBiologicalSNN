clear 
clc

rng(2,"twister");

mynet = IzhikevichNetwork(400);

mynet.noise = true;
mynet.sigma_ex = 0.5*5;
mynet.sigma_inh = 0.5*2;

mynet.SetInitialConnectivity(0.5, 2, 2);

mynet.STDP = true;

mynet.input = true;
mynet.input_interval = 1000; % ms
mynet.input_duration = 2; % ms
mynet.input_strength = 30; % current
pattern1_indices = [1];
pattern2_indices = [3];
nNeurons = 50;

for i = 1:nNeurons-1
    connected_to = mynet.out_cells(pattern1_indices(end));
    for j = 1:length(connected_to)
        if ~ismember(connected_to(j), pattern1_indices)
            pattern1_indices = [pattern1_indices, connected_to(j)];
            break
        end
    end
end
pattern1_indices = randperm(mynet.Ne, nNeurons);

for i = 1:nNeurons-1
    connected_to = mynet.out_cells(pattern2_indices(end));
    for j = 1:length(connected_to)
        if ~ismember(connected_to(j), pattern2_indices)
            pattern2_indices = [pattern2_indices, connected_to(j)];
            break
        end
    end
end
pattern2_indices = randsample(setxor(1:mynet.Ne, pattern1_indices), nNeurons, false);


%pattern_indices = randperm(mynet.Ne, nNeurons);
% mynet.input_pattern = [pattern1_indices; repmat([5], 1, nNeurons)]';
dt = 0.2; %ms
%mynet.input_pattern = [pattern1_indices, pattern2_indices; 5:dt:5+(nNeurons-1)*dt, 500:dt:500+(nNeurons-1)*dt]'; % two stimulation 
mynet.input_pattern = [pattern1_indices; 5:dt:5+(nNeurons-1)*dt]'; % one stimulation 
mynet.SetInputCurrent

mynet.scaling = false;
mynet.A_goal = [0.001*ones(mynet.Ne, 1); 0.002*ones(mynet.Ni, 1)];
mynet.alpha = 20;

mynet.sampling_rate = 5000;

%% Run 

mynet.run(200000)

data = mynet.getData();

%% Calculating correlation between Spike time signals
signals = zeros(mynet.N, length(mynet.time));

firings = data.firings;
for i = 1: size(firings,2)
    signals(firings(2, i), round(firings(1, i)/mynet.dt)) = 1;
end

% Initialize an empty matrix to store the correlation coefficients
pair_correlation = zeros(mynet.N, mynet.N);

% Loop through each pair of neurons
for i = 1:mynet.N
    for j = 1:mynet.N
        % Calculate cross-correlation between spike trains of neuron i and neuron j
        correlation_coefficient = xcorr(signals(i,:), signals(j,:));
        
        % Normalize the cross-correlation coefficient
        normalization_factor = sqrt(sum(signals(i,:).^2) * sum(signals(j,:).^2));
        pair_correlation(i, j) = max(correlation_coefficient) / normalization_factor;
    end
end

%% a single cell voltage trace with syanptic inputs

cell_number = 11;

% ax1 = subplot(2, 1, 1);
plot(data.time, data.v(cell_number, :))

hold on

% ax2 = subplot(2, 1, 2);   
plot(data.time, 10 * data.I(cell_number, :))

hold off
legend('v', 'I')
% linkaxes([ax1, ax2], 'x')

%% dynamic of synaptic weights in time
x = (1:size(data.w, 3))*mynet.dt*mynet.sampling_rate;  % Assuming meanValues is your array of mean values

data1 = reshape(data.w(1:mynet.Ne, 1:mynet.Ne, :), mynet.Ne*mynet.Ne, length(x));
data2 = reshape(data.w(1:mynet.Ne, mynet.Ne+1:end, :), mynet.Ne*mynet.Ni, length(x));
data3 = reshape(data.w(mynet.Ne+1:end, 1:mynet.Ne, :), mynet.Ni*mynet.Ne, length(x));

rowsToRemove = all(data1 == 0, 2);
data1(rowsToRemove, :) = [];
rowsToRemove = all(data2 == 0, 2);
data2(rowsToRemove, :) = [];
rowsToRemove = all(data3 == 0, 2);
data3(rowsToRemove, :) = [];

meanLine1 = squeeze(mean(data1, 1));     % Mean values
meanLine2 = squeeze(mean(data2, 1));
meanLine3 = squeeze(mean(data3, 1));

% Calculate the upper and lower bounds
upperBound1 = prctile(data1, 95, 1);
lowerBound1 = prctile(data1, 5, 1);
upperBound2 = prctile(data2, 95, 1);
lowerBound2 = prctile(data2, 5, 1);
upperBound3 = prctile(data3, 95, 1);
lowerBound3 = prctile(data3, 5, 1);

% Concatenate the upper bound and reversed lower bound
xPolygon = [x, fliplr(x)];  % x coordinates for the polygon
yPolygon1 = [upperBound1, fliplr(lowerBound1)];  % y coordinates for the polygon
yPolygon2 = [upperBound2, fliplr(lowerBound2)];  % y coordinates for the polygon
yPolygon3 = [upperBound3, fliplr(lowerBound3)];  % y coordinates for the polygon

figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed
% Plot the mean lines
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
fsize = 25;
plot(ax, x/1000, meanLine1, 'k', 'LineWidth', 2, 'Color',"#77AC30"); 
hold on;
plot(ax, x/1000, meanLine2, 'b.-', 'LineWidth', 2, 'Color',"#7E2F8E")
plot(ax, x/1000, meanLine3, 'r', 'LineWidth', 2, 'Color',"#D95319")

% Shade the area between upper and lower bounds
% fillColor = [0.8, 0.8, 0.8]; % Light gray fill
% plot(x, upperBound1, 'k')
% plot(x, lowerBound1, 'k')
% 
% plot(x, upperBound2, 'b')
% plot(x, lowerBound2, 'b')
% 
% plot(x, upperBound3, 'r')
% plot(x, lowerBound3, 'r')

fill(xPolygon/1000, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#77AC30");
hold on
fill(xPolygon/1000, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#7E2F8E");
fill(xPolygon/1000, yPolygon3, 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#D95319");

% Additional plot adjustments
xlabel('time (s)');
ylabel('W');
title('Weigths Evolution in Time (90% CI)');
legend('g_{ee}', 'g_{ei}', 'g_{ie}', Location='southwest')
ylim([-5, 5])
hold off;
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 
%% dynamic of synaptic weights histogram

fig = figure('name', 'Weights Histogram');
for i = 1:5:size(data.w, 3)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    % histogram(nonzeros(data.w(:, :, i)), 400);
    title(sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    hold on 
    histogram(data1(:, i), 100, 'Normalization', 'pdf', 'EdgeColor', 'none');
    histogram(data2(:, i), 100, 'Normalization', 'pdf', 'EdgeColor', 'none');
    histogram(data3(:, i), 100, 'Normalization', 'pdf', 'EdgeColor', 'none');
    legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')
    
    pause(0.1); % Pause to view the histogram
end
%% Histogram of weigths plot
figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
fsize = 25;
trial_number = 2500;
frame = 1000*trial_number/(mynet.sampling_rate*mynet.dt);

hold on 
histogram(ax, data1(:, frame), 50, 'Normalization', 'pdf', 'EdgeColor', 'none', 'FaceColor', "#77AC30", 'FaceAlpha', 1, DisplayName="g_{ee}");
histogram(ax, data2(:, frame), 50, 'Normalization', 'pdf', 'EdgeColor', 'none', 'FaceColor', "#7E2F8E", 'FaceAlpha', 0.5, DisplayName="g_{ei}");
histogram(ax, data3(:, frame), 50, 'Normalization', 'pdf', 'EdgeColor', 'none', 'FaceColor', "#D95319", 'FaceAlpha', 0.5, DisplayName="g_{ie}");
title(sprintf("After Learning Weights PDF", trial_number))
xlabel('w') 
ylabel('PDF')

lgd = legend();
%fontsize(lgd,14,'points')
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 
%% save mp4 file for weights histograms
% Define the video file name
videoFileName = 'weights_histogram3';

% Create a VideoWriter object
writerObj = VideoWriter(videoFileName, 'MPEG-4');

% Set the frame rate (frames per second)
frameRate = 20; % Adjust this value as needed
writerObj.FrameRate = frameRate;
% writerObj.Quality = 100;

% Open the VideoWriter object
open(writerObj);
f = waitbar(0, 'please wait ...');

fig = figure('name', 'Weights Histogram');
for i = 1:5:size(data.w, 3)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    waitbar(i/size(data.w, 3), f, 'please wait')

    % histogram(nonzeros(data.w(:, :, i)), 400);
    title(sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    hold on 
    histogram(data1(:, i), 100, 'Normalization', 'probability', 'EdgeColor', 'none');
    histogram(data2(:, i), 100, 'Normalization', 'probability', 'EdgeColor', 'none');
    histogram(data3(:, i), 100, 'Normalization', 'probability', 'EdgeColor', 'none');
    legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')
    
    % Get the current frame
    frame = getframe(gcf);
    
    % Write the current frame to the video file
    writeVideo(writerObj, frame);
    
end

% Close the VideoWriter object
close(writerObj);
close(f)
%% dynamic of A in time
x = (1:size(data.A, 2))*mynet.dt*mynet.sampling_rate/1000;  % Assuming meanValues is your array of mean values
meanLine1 = mean(1000*data.A(1:mynet.Ne, :), 1);     % Mean values
meanLine2 = mean(1000*data.A(mynet.Ne+1:end, :), 1);   

%stdDev1 = std(data.A(1:mynet.Ne, :), 1);        % Standard deviation values
%stdDev2 = std(data.A(mynet.Ne+1:end, :), 1); 

% Calculate the upper and lower bounds
upperBound1 = prctile(data.A(1:mynet.Ne, :), 95, 1);
lowerBound1 = prctile(data.A(1:mynet.Ne, :), 5, 1);
upperBound2 = prctile(data.A(mynet.Ne+1:end, :), 95, 1);
lowerBound2 = prctile(data.A(mynet.Ne+1:end, :), 5, 1);

% Concatenate the upper bound and reversed lower bound
xPolygon = [x, fliplr(x)];  % x coordinates for the polygon
yPolygon1 = [upperBound1, fliplr(lowerBound1)];  % y coordinates for the polygon
yPolygon2 = [upperBound2, fliplr(lowerBound2)];  % y coordinates for the polygon

figure()
hold on;
% Plot the mean lines
plot(x, meanLine1, 'k-', 'LineWidth', 2, 'DisplayName', 'Ex'); 

plot(x, meanLine2, 'b-', 'LineWidth', 2, 'DisplayName', 'Inh');

% Shade the area between upper and lower bounds
% fillColor = [0.8, 0.8, 0.8]; % Light gray fill
fill(xPolygon, 1000*yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

fill(xPolygon, 1000*yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

if mynet.scaling    
    A_goal_Ex = 1000* mean(mynet.A_goal(1:mynet.Ne));
    A_goal_Inh = 1000* mean(mynet.A_goal(mynet.Ne+1:end));
    plot(x, A_goal_Ex*ones(1, length(x)), 'k--', 'DisplayName', 'Ex target rate')
    plot(x, A_goal_Inh*ones(1, length(x)), 'b--', 'DisplayName', 'Inh target rate')
end

% Additional plot adjustments
xlabel('time (s)');
ylabel('A (Hz)');

% set(gca, 'YScale', 'log')

grid on
title('Avtivity Distribution (95% CI)');
legend()
hold off;

%% dynamic of A histogram
fig = figure('name', 'A Histogram');
for i = 1:5:size(data.A, 2)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('A Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    hold on
    histogram(1000*data.A(1:mynet.Ne, i), 40, 'Normalization', 'count', 'EdgeColor', 'none');
    histogram(1000*data.A(mynet.Ne+1:end, i), 40, 'Normalization', 'count', 'EdgeColor', 'none');
    title(sprintf('A Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    xlabel('Hz')
    legend('Ex', 'Inh')
    xlim([0, 20])
    % hold on 
    % histogram(nonzeros(data.w(1:mynet.Ne, mynet.Ne+1:end, i)), 'Normalization', 'probability');
    % histogram(nonzeros(data.w(mynet.Ne+1:end, 1:mynet.Ne, i)), 'Normalization', 'probability');
    % legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')

    pause(0.1); % Pause to view the histogram
end
%% Input Analysis
figure('Name', "Input Struture")
hold on 

%area(mynet.dt:mynet.dt:mynet.input_interval, mynet.input_current', 'FaceColor', 'black', 'FaceAlpha', 0.4, 'EdgeColor', 'none')

%t_arr = mynet.dt:mynet.dt:mynet.input_interval;
%for i=1:size(mynet.input_pattern, 1)
%    fill([t_arr, fliplr(t_arr)], [mynet.input_current(i, :), zeros(1, length(t_arr))], 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
%end

plot(mynet.dt:mynet.dt:mynet.input_interval, mynet.input_current', '.-')
xlim([0, max(mynet.input_pattern(:, 2)) + 10])
ylim([0, mynet.input_strength * 1.05])
xlabel("time (ms)")
ylabel("Stimulation Current")
%% Raster plot after Learning in noise phase (Poster Content)

figure('Name', "Raster Plot", 'Renderer', 'painters', 'Position', [100 100 1000 1000]); 
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
firings = data.firings;
fsize = 20;
start_time = 1800;
end_time = 1880;

ex_indices = ((firings(1, :)/1000 > start_time) & (firings(1, :)/1000 < end_time)) & (firings(2, :) <= 320);
inh_indices = ((firings(1, :)/1000 > start_time) & (firings(1, :)/1000 < end_time)) & (firings(2, :) > 320);
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
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');

%% Sorted Raster Plot

clf;
check_flag = zeros(1, mynet.N);

spike_times = mynet.firings(:, 1);
neuron_indices = mynet.firings(:, 2);

counter_ex = 1;
counter_inh = mynet.Ne+1;
hold on 
for i = 1:length(spike_times)
    if neuron_indices(i) <= mynet.Ne
        if check_flag(neuron_indices(i)) == 0
            plot(spike_times(i), counter_ex, 'k.');
           
            check_flag(neuron_indices(i)) = counter_ex;
            counter_ex = counter_ex + 1;
        else
            if counter_ex > mynet.Ne
                counter_ex = 1;
                check_flag(1:mynet.Ne) = zeros(1, mynet.Ne);
                plot(spike_times(i), counter_ex, 'k.');
            else
                plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
            end
        end
    else
        if check_flag(neuron_indices(i)) == 0
            plot(spike_times(i), counter_inh, 'k.');
     
            check_flag(neuron_indices(i)) = counter_inh;
            counter_inh = counter_inh + 1;
        else
            if counter_inh > mynet.N      
                counter_inh = mynet.Ne+1;
                check_flag(mynet.Ne+1:end) = zeros(1, mynet.Ni);
                plot(spike_times(i), counter_inh, 'k.');
            else
                plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
            end
        end
    end

end

plot([0, mynet.t], [mynet.Ne + 0.5, mynet.Ne + 0.5], 'r-')
xlabel('time (ms)')
ylabel('neuron index')
title('Sorted raster plot')
    
%% Sorted Rater plot of different trials (Just Input Only Situation!)
figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); 
fsize = 25;
msize = 12.5;


firings = transpose(data.firings);
interval = mynet.input_interval/2;

%check_flag_save = zeros(round(mynet.t/interval), mynet.N);
%total_spike_count = zeros(1, round(mynet.t/interval));
%ex_neurons_engagement_count = zeros(1, round(mynet.t/interval));
%inh_neurons_engagement_count = zeros(1, round(mynet.t/interval));

for trial_number = [399] 
    clf;
    ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]

    check_flag = zeros(1, mynet.N);
    
    indices = (firings(:, 1) > (trial_number-1) * interval) & (firings(:, 1) <= trial_number * interval);
    spike_times = firings(indices, 1) - (trial_number-1)*interval;
    neuron_indices = firings(indices, 2);
    
    counter_ex = 1;
    counter_inh = mynet.Ne+1;
    hold on
    
    neuron_sorted_indices = zeros(size(spike_times, 1), 1);
    clear h1 h2
    for i = 1:length(spike_times)
        if true
            if neuron_indices(i) <= mynet.Ne
                if check_flag(neuron_indices(i)) == 0
                    h1 = plot(ax, spike_times(i), counter_ex, 'k.', 'MarkerSize', msize, DisplayName='First Spike');
                    neuron_sorted_indices(i) = counter_ex;
    
                    check_flag(neuron_indices(i)) = counter_ex;
                    counter_ex = counter_ex + 1;
                else
                    h2 = plot(ax, spike_times(i), check_flag(neuron_indices(i)), 'r.', 'MarkerSize', msize, DisplayName='Repeated Spike');
                    neuron_sorted_indices(i) = check_flag(neuron_indices(i));
                end
            else
                if check_flag(neuron_indices(i)) == 0
                    h1 = plot(ax, spike_times(i), counter_inh, 'k.', 'MarkerSize', msize, DisplayName='First Spike');
                    neuron_sorted_indices(i) = counter_inh;
    
                    check_flag(neuron_indices(i)) = counter_inh;
                    counter_inh = counter_inh + 1;
                else
                    h2 = plot(ax, spike_times(i), check_flag(neuron_indices(i)), 'r.', 'MarkerSize', msize, DisplayName='Repeated Spike');
                    neuron_sorted_indices(i) = check_flag(neuron_indices(i));
    
                end
            end
        end
    end
    
    %check_flag_save(trial_number, :) = check_flag;
    %total_spike_count(trial_number) =  length(spike_times);
    %ex_neurons_engagement_count(trial_number) = sum(unique(neuron_indices)<=mynet.Ne);
    %inh_neurons_engagement_count(trial_number) = sum(unique(neuron_indices)>mynet.Ne);
    
    % plot(spike_times, neuron_indices, 'k.')
    hold on 
    %plot(spike_times, neuron_sorted_indices, 'b.' , DisplayName= sprintf('%d neurons spiked, %d total spikes', length(nonzeros(check_flag)), length(spike_times)))

    xlabel('time (ms)');
    ylabel('sorted neuron index');
    title(sprintf('Trial Number %d Raster Plot', round(trial_number/2)));
    plot(ax, [0, mynet.input_interval], (mynet.Ne + 0.5)*[1, 1], 'k-', HandleVisibility='off')
    plot(ax, [0, mynet.input_interval], (0.5*size(mynet.input_pattern, 1) + 0.5)*[1, 1], 'k--', HandleVisibility='off')
    xlim([0, 30])
    ylim([0, mynet.N + 0.5])
    if exist("h1") && exist("h2")
        lgd = legend([h1, h2], "First Spike","Repeated Spike", Location="northwest");
        fontsize(lgd,14,'points')
    elseif exist("h1")
        lgd = legend([h1], "First Spike", Location="northwest");
        fontsize(lgd,14,'points')
    elseif exist("h2")
        lgd = legend([h2], "Repeated Spike", Location="northwest");
        fontsize(lgd,14,'points')
    end

    % Add text annotations for different phases using annotation
    % Add arrows or lines to span the phases at the bottom of the plot
    y_starts = [0.2, 0.28, 0.685];
    y_ends = [0.28, 0.675, 0.8];
    phases = ["Stimulation Set", "Excitatory", "Inhibitory"];
    for i = 1:length(phases)
        annotation('line',[0.81 0.81], [y_starts(i), y_ends(i)], 'Color', 'Black', 'LineWidth', 3, LineStyle='-'); % Stimulation
        annotation('textbox', [0.83,  y_starts(i)/2 + y_ends(i)/2 - 0.05, 0.1, 0.01], 'String', phases(i), 'FontName', 'Arial', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'EdgeColor', 'none', Rotation=90)
    end
    
    yticks([1, 50:50:300, 321, 360,400])
    yticklabels([1, 50:50:300, 1, 40,80])
    set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 
    pause(1)
    
end
%% Order of spikes analysis (In input mode!)
figure('Name', "Single Neuron Spike Order")
plot(check_flag_save(2:2:end, 1:320))
xlabel("Trial")
ylabel("Single Neuron Spike Order")
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Change in Order Measure')
distance1 = zeros(1, size(check_flag_save, 1));
distance2 = zeros(1, size(check_flag_save, 1));
crossDistance = zeros(1, size(check_flag_save, 1));

% First Memory consecutive trials distance in time
for trial = 3:2:size(check_flag_save, 1)
    order1 = check_flag_save(trial-2, 1:mynet.Ne);
    order2 = check_flag_save(trial, 1:mynet.Ne);
    
    diff = order1 - order2;
    if sum(diff) == 0
        distance1(1, trial) = sqrt(dot(diff, diff));
    end
end

% Second Memory consecutive trials distance in time
for trial = 4:2:size(check_flag_save, 1)
    order1 = check_flag_save(trial-2, 1:mynet.Ne);
    order2 = check_flag_save(trial, 1:mynet.Ne);
    
    diff = order1 - order2;
    if sum(diff) == 0
        distance2(1, trial) = sqrt(dot(diff, diff));
    end
end

% Cross Memories consecutive trials distance in time
for trial = 2:1:size(check_flag_save, 1)
    order1 = check_flag_save(trial-1, 1:mynet.Ne);
    order2 = check_flag_save(trial, 1:mynet.Ne);
    
    diff = order1 - order2;
    if true
        crossDistance(1, trial) = sqrt(dot(diff, diff));
    end
end

hold on 
plot(find(distance1 > 0), nonzeros(distance1)/mynet.Ne,'r.', DisplayName='Distance 1')
plot(find(distance2 > 0), nonzeros(distance2)/mynet.Ne,'b.', DisplayName='Distance 2')
plot(find(crossDistance > 0), nonzeros(crossDistance)/mynet.Ne,'k.', DisplayName='Cross Distance')

legend()
xlabel('Trial')
ylabel('Change in Order Measure')

%% Spearman corr analysis of orders

figure('Name', 'Spearman Correlation')
title('Spearman Correlation Between Consecutive Trials')
distance1 = zeros(1, size(check_flag_save, 1));
distance2 = zeros(1, size(check_flag_save, 1));
crossDistance = zeros(1, size(check_flag_save, 1));

for trial = 3:2:size(check_flag_save, 1)
    order1 = check_flag_save(trial-2, 1:mynet.Ne);
    order2 = check_flag_save(trial, 1:mynet.Ne);
    
    if true
        distance1(1, trial) = corr(order1', order2', 'type', 'Spearman');
    end
end

for trial = 4:2:size(check_flag_save, 1)
    order1 = check_flag_save(trial-2, 1:mynet.Ne);
    order2 = check_flag_save(trial, 1:mynet.Ne);
    

    if size(order1,2) ~= 0 
        distance2(1, trial) = corr(order1', order2', 'type', 'Spearman');
    end
    
end

for trial = 2:1:size(check_flag_save, 1)
    order1 = check_flag_save(trial-1, 1:mynet.Ne);
    order2 = check_flag_save(trial, 1:mynet.Ne);
    

    if size(order1,2) ~= 0 
        crossDistance(1, trial) = corr(order1', order2', 'type', 'Spearman');
    end
end

hold on 
plot(3:2:size(check_flag_save, 1), distance1(3:2:size(check_flag_save, 1)),'r.-', DisplayName='Distance 1')
plot(4:2:size(check_flag_save, 1), distance2(4:2:size(check_flag_save, 1)),'b.-', DisplayName='Distance 2')
plot(find(crossDistance ~= 0), nonzeros(crossDistance),'k.-', DisplayName='Cross Distance')

legend()
xlabel('Trial')
ylabel('SpearMan Correltion')

%% Spearman Corr Matrix Analysis (Poster Component)

%corrmat = 1-squareform(pdist(check_flag_save(1:1:end, 1:320), 'spearman')); % Replace this with your actual data
corrmat = corr(check_flag_save(1:1:end, 1:320)','type', 'spearman');
submat = corrmat(2:2:end, 1:2:end);

% Create the heatmap

figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed
fsize = 25; % font size


% Create axes with the desired position and size
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]

%imagesc(submat, 'Parent', ax, 'AlphaData', ~isnan(submat));
imagesc(submat, 'Parent', ax)
colormap parula;
c = colorbar;

% Adjust the position of the colorbar to the left
c.Units = 'normalized'; % Use normalized units
c.Position = [0.15, 0.2, 0.03, 0.6]; % [left, bottom, width, height]
% Move the colorbar title to the middle and set font properties

c.Label.String = 'Spearman Rank Correlation';
c.Label.Rotation = 90; % Rotate the label to be vertical
c.Label.Position = [-2, 0.1, 0]; % Adjust the position to be centered and beside the colorbar
c.Label.FontName = 'Arial'; % Set the font name
c.Label.FontSize = fsize; % Set the font size
c.Label.FontWeight = 'bold'; % Set the font weight to bold

% Set the title and axis labels with consistent font properties
xlabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
ylabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 0);

% Fix the aspect ratio to square
% axis square;

set(gca, 'YDir', 'normal')

% Define the x-tick positions and labels
xTickPositions = [1, 1000, 1500, 2000, 2500];
xTickLabels = xTickPositions;

% Set the x-ticks and labels with consistent font properties
xticks(xTickPositions);
xticklabels(xTickLabels);
xtickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for x-tick labels

% Similarly, you can set y-ticks if needed
yticks(xTickPositions);
yticklabels(xTickLabels);
ytickangle(-45)
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); % Set for y-tick labels

% Set x-ticks to top and y-ticks to right
set(gca, 'XAxisLocation', 'top', 'YAxisLocation', 'right');


% Add text annotations for different phases using annotation
% Add arrows or lines to span the phases at the bottom of the plot
starts = ([0, 1000, 1500, 2000]+25)*0.6/2500 + 0.2;
ends = ([1000, 1500, 2000, 2500]-25)*0.6/2500 + 0.2;
phases = ["Learning", "Stim + Noise", "Noise", "Stim + Noise"];
for i = 1:length(phases)
    annotation('line', [starts(i), ends(i)], [0.18 0.18], 'Color', 'black', 'LineWidth', 1.5); % Stimulation
    annotation('textbox', [starts(i)/2+ends(i)/2 - 0.05, 0.1, 0.1, 0.05], 'String', phases(i), 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none')
end

% Adjust paper size and position for saving as PDF
set(gcf, 'PaperPositionMode', 'auto');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 10 10]); % [left, bottom, width, height]
set(gcf, 'PaperSize', [10 10]); % [width, height]

% Add horizontal and vertical lines to separate phases
hold on;
line([1001 1001], ylim, 'Color', 'black', 'LineWidth', 1.5); % Vertical line at 1000
line([1501 1501], ylim, 'Color', 'black', 'LineWidth', 1.5); % Vertical line at 1500
line([2001 2001], ylim, 'Color', 'black', 'LineWidth', 1.5); % Vertical line at 2000
line(xlim, [1001 1001], 'Color', 'black', 'LineWidth', 1.5); % Horizontal line at 1000
line(xlim, [1501 1501], 'Color', 'black', 'LineWidth', 1.5); % Horizontal line at 1500
line(xlim, [2001 2001], 'Color', 'black', 'LineWidth', 1.5); % Horizontal line at 2000
hold off;

title("Cross Correlation", 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold')
% Save the figure as a PDF with higher resolution
% print(gcf, 'Spearman_Corr_Matrix.pdf', '-dpdf', '-vector', '-r300');
print(gcf, 'Spearman_Corr_Matrix.png', '-dpng', '-r300');

%% Noise and Stimulation Decay Analysis (Poster Component)
figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed

title('Auto Correlation of Memories in Time(Learning)')
fsize = 25;

start_trial = 2001;
end_trial = 3000;
N_trials = round((end_trial-start_trial)/2)-1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% First Memory
submat = corrmat(start_trial:2:end_trial, start_trial:2:end_trial);
mean_corr = zeros(1, N_trials);
mean_error = zeros(1,N_trials);
CI_upper = zeros(1, N_trials);
CI_lower = zeros(1, N_trials);

hold on
for i=1:N_trials
    %plot(submat(i, i:500), '.', MarkerFaceColor='none', MarkerEdgeColor='k')
 
    mean_corr(i) = nanmean(diag(submat, i));
    mean_error(i) = std(diag(submat, i))/sqrt(length(diag(submat, i)));
    CI_upper(i) = prctile(diag(submat, i), 97.5);
    CI_lower(i) = prctile(diag(submat, i), 2.5); 
    plot((1:N_trials-i+1) + round(start_trial/2), submat(i, i+1:end), 'LineStyle', 'none','Marker','o', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none', 'MarkerSize', 0.2, HandleVisibility='off')
end
plot((1:N_trials) + round(start_trial/2), mean_corr, 'k-', LineWidth=3, DisplayName="Memory 1")
%errorbar(1:N_trials, mean_corr, mean_error, mean_error, 'bo', LineStyle='-', DisplayName="Memory 1")
%fill([1:N_trials, fliplr(1:N_trials)], [CI_upper, fliplr(CI_lower)], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, HandleVisibility='off');


xlabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
ylabel('Spearman Correlation', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 90);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Second Memory
submat = corrmat(start_trial+1:2:end_trial, start_trial+1:2:end_trial);
mean_corr = zeros(1, N_trials);
mean_error = zeros(1,N_trials);
CI_upper = zeros(1, N_trials);
CI_lower = zeros(1, N_trials);

hold on
for i=1:N_trials
    %plot(submat(i, i:500), '.', MarkerFaceColor='none', MarkerEdgeColor='k')
    mean_corr(i) =  nanmean(diag(submat, i));
    mean_error(i) = std(diag(submat, i))/sqrt(length(diag(submat, i)));
    CI_upper(i) = prctile(diag(submat, i), 97.5);
    CI_lower(i) = prctile(diag(submat, i), 2.5); 
    plot((1:N_trials-i+1) + round(start_trial/2), submat(i, i+1:end), 'LineStyle', 'none','Marker','o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'none', 'MarkerSize', 0.2, HandleVisibility='off')
end

plot((1:N_trials) + round(start_trial/2), mean_corr, 'b-', LineWidth=3, DisplayName="Memory 2")
%errorbar(1:N_trials, mean_corr, mean_error, mean_error, 'bo', LineStyle='-', DisplayName="Memory 2")
%fill([1:N_trials, fliplr(1:N_trials)], [CI_upper, fliplr(CI_lower)], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, HandleVisibility='off');

xlabel('Trial', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
ylabel('Spearman Correlation', 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'Rotation', 90);

ylim([0, 1])
legend(Location="south")
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 
%%
figure;
hold on
plot(nanmean(corrmat(1:2:end, 1:2:end), 2), DisplayName='memory 1')
plot(nanmean(corrmat(1:2:end, 1:2:end), 2), DisplayName='memory 2')
plot(nanmean(corrmat(1:2:end, 2:2:end), 2), DisplayName='a')
legend()
%% Orders in time
figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed

ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
title('Memory 1 Color Coded by Memory 2')
fsize = 20;
temp = check_flag_save(1:2:end, :);
temp(temp == 0) = nan;

%stable_order_ex = temp(1000, 1:320);
%stable_order_inh = temp(1000, 321:end)-320;

cmap = jet(320);
colormap_ex = ones(320, 3);
for i = 1:320
    index = stable_order_ex == i;
    if sum(index) == 1
        colormap_ex(index, :) = cmap(i, :);
    end
end

cmap = jet(80);
colormap_inh = ones(80, 3);
for i = 1:80
    index = stable_order_inh == i;
    if sum(index) == 1
        colormap_inh(index, :) = cmap(i, :);
    end
end


hold on 
wsize = 1;
for cell_id =1:1:320
    
    plot(temp(1:end, cell_id), 'color', colormap_ex(cell_id, :), LineWidth= wsize)
end
for cell_id = 321:1:400
    
    plot(temp(1:end, cell_id), 'color', colormap_inh(cell_id-320, :), LineWidth= wsize)
end


xlabel('Trial')
ylabel('Sorted Neuronal Order')
ylim([0 400])
% Add text annotations for different phases using annotation
% Add arrows or lines to span the phases at the bottom of the plot
starts = ([0, 1000, 1500, 2000]+25)*0.6/2500 + 0.2;
ends = ([1000, 1500, 2000, 2500]-25)*0.6/2500 + 0.2;
phases = ["Learning", "Stim + Noise", "Noise", "Stim + Noise"];
for i = 1:length(phases)
    annotation('line', [starts(i), ends(i)], [0.18 0.18], 'Color', 'black', 'LineWidth', 1.5); % Stimulation
    annotation('textbox', [starts(i)/2+ends(i)/2 - 0.05, 0.1, 0.1, 0.05], 'String', phases(i), 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none')
end

set(gca,'xaxisLocation','top')
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 
%% Poulation Analysis
%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Population Analysis')

subplot(3, 1, 1)
hold on
plot(100* ex_neurons_engagement_count(1:2:end)/mynet.Ne, DisplayName='memory 1')
plot(100* ex_neurons_engagement_count(2:2:end)/mynet.Ne, DisplayName= 'memory 2')
legend()

title("Excitatory Population Engagement")
xlabel('Trial')
ylabel('Engagement %')
%%%%%%%%%%%%%%%%%%%%%
subplot(3, 1, 2)
hold on
plot(100* inh_neurons_engagement_count(1:2:end)/mynet.Ni, DisplayName='memory 1')
plot(100* inh_neurons_engagement_count(2:2:end)/mynet.Ni, DisplayName= 'memory 2')
legend()

title("Inhibitory Population Engagement")
xlabel('Trial')
ylabel('Engagement %')

%%%%%%%%%%%%%%%%%%%%%

subplot(3, 1, 3)
hold on
plot(total_spike_count(1:2:end), DisplayName='memory 1')
plot(total_spike_count(2:2:end), DisplayName= 'memory 2')
legend()
title("Total Spike Count per Trial")
xlabel('Trial')
ylabel('Spike Count')
%%%%%%%%%%%%%%%%%%%%%
%% save mp4 file for raster plots animation

% Define the video file name
videoFileName = 'raster_plots3';

% Create a VideoWriter object
writerObj = VideoWriter(videoFileName, 'MPEG-4');

% Set the frame rate (frames per second)
frameRate = 20; % Adjust this value as needed
writerObj.FrameRate = frameRate;
% writerObj.Quality = 100;

% Open the VideoWriter object
open(writerObj);

% Your existing code
figure('Visible', 'off');

firings = transpose(data.firings);
interval = mynet.input_interval;
f = waitbar(0, 'please wait ...');
total_trials = round(mynet.t/interval);

for trial_number = 1:total_trials
    waitbar(trial_number/total_trials, f, 'please wait')
    clf;
    check_flag = zeros(1, mynet.N);
   
    indices = (firings(:, 1) > (trial_number-1) * interval) & (firings(:, 1) <= trial_number * interval);
    spike_times = firings(indices, 1) - (trial_number-1)*interval;
    neuron_indices = firings(indices, 2);
    
    counter_ex = 1;
    counter_inh = mynet.Ne+1;
    hold on
    
    neuron_sorted_indices = zeros(size(spike_times, 1), 1);
 
    for i = 1:length(spike_times)
        if neuron_indices(i) <= mynet.Ne
            if check_flag(neuron_indices(i)) == 0
                % plot(spike_times(i), counter_ex, 'k.');
                neuron_sorted_indices(i) = counter_ex;

                check_flag(neuron_indices(i)) = counter_ex;
                counter_ex = counter_ex + 1;
            else
                % plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
                neuron_sorted_indices(i) = check_flag(neuron_indices(i));
            end
        else
            if check_flag(neuron_indices(i)) == 0
                % plot(spike_times(i), counter_inh, 'k.');
                neuron_sorted_indices(i) = counter_inh;

                check_flag(neuron_indices(i)) = counter_inh;
                counter_inh = counter_inh + 1;
            else
                %plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
                neuron_sorted_indices(i) = check_flag(neuron_indices(i));

            end
        end
        
    end
    
   
    plot(spike_times, neuron_sorted_indices, 'k.')
    xlabel('time (ms)')
    ylabel('neuron index')
    title(sprintf('trial number %d raster plot, real time : %0.1f', trial_number, trial_number))
    plot([0, mynet.input_interval], (mynet.Ne + 0.5)*[1, 1], 'r-')
    plot([0, mynet.input_interval], (size(mynet.input_pattern, 1) + 0.5)*[1, 1], 'b-')
    xlim([0, 40])
    ylim([0, mynet.N + 0.5])
    
    % Get the current frame
    frame = getframe(gcf);
    
    % Write the current frame to the video file
    writeVideo(writerObj, frame);
    
    %pause(0.05)

end

% Close the VideoWriter object
close(writerObj);
close(f)
%% Analyzing STDP
firings = data.firings;
w_data = data.w;
time = (1:size(data.w, 3))*mynet.dt*mynet.sampling_rate;

t_min = 0; t_max = 5000;
check = firings(1, :) >= t_min & firings(1, :) <= t_max;
firings = firings(:, check);

idx =1; % neuron to analyze
in_cells = mynet.in_cells(idx);
out_cells = mynet.out_cells(idx);

in_firings = firings(:, ismember(firings(2, :), in_cells));
out_firings = firings(:, ismember(firings(2, :), out_cells));

y_in = replace_by_order(in_firings(2, :));
y_out = replace_by_order(out_firings(2, :)) + max(unique(y_in)) + 1;

figure()
hold on

plot(in_firings(1, :)/1000, y_in, 'r*');
plot(firings(1, firings(2, :) == idx)/1000, repmat(length(unique(y_in)) + 1, 1, sum(firings(2, :) == idx)), 'k*');
plot(out_firings(1, :)/1000, y_out, 'b*');



yticks([unique(y_in), max(unique(y_in)) + 1, unique(y_out)])
yticklabels({unique(in_firings(2, :)), 'Selected Neuron', unique(out_firings(2, :))})

legend('input', 'cell', 'output')
xline(firings(1, firings(2, :) == idx)/1000, 'HandleVisibility', 'off', 'Alpha', 0.1, 'LineWidth', 0.2)

xlabel('t (s)')
ylabel('Neuron Index')
title('Spike Trains')
hold off


%%
w_in = squeeze(data.w(idx, in_cells, :));
w_out = squeeze(data.w(out_cells, idx, :));

hold on
HandleFlag = 'on';
for i = 1:size(w_in, 1)
    plot((1:size(w_in, 2)) * mynet.sampling_rate,  w_in(i, :), 'r-', LineWidth=0.1, HandleVisibility=HandleFlag)
    HandleFlag = 'off';
end

HandleFlag = 'on';
for i = 1:size(w_out, 1)
    plot((1:size(w_out, 2)) * mynet.sampling_rate,  w_out(i, :), 'b-', LineWidth=0.1, HandleVisibility=HandleFlag)
    HandleFlag = 'off';
end
legend('input weights', 'output weights')

%% Visualizing network graph (Color Coding)
figure()
% Example adjacency matrix for a directed graph
A = mynet.w(pattern_indices, pattern_indices);

% Define a threshold for strong connections
threshold = 1; % Adjust this value based on your criteria for strong connections

% Create a directed graph object
G = digraph(A);

% Extract the weights from the adjacency matrix
weights = G.Edges.Weight;

% Filter edges based on the threshold
strongEdges = weights > threshold;
G = rmedge(G, find(~strongEdges)); % Remove edges that are below the threshold

% Extract the weights again after filtering
weights = G.Edges.Weight;

% Normalize the weights for colormap indexing
minW = min(weights);
maxW = max(weights);
normalizedWeights = (weights - minW) / (maxW - minW);

% Define the colormap that goes from blue to red
cmap = jet(256); % 256 colors

% Map the normalized weights to colormap indices
colorIndices = round(normalizedWeights * (size(cmap, 1) - 1)) + 1;

% Plot the graph with layered layout
h = plot(G, 'Layout', 'layered');

% Set the edge color based on normalized weights
h.EdgeCData = colorIndices;

% Apply the colormap
colormap(cmap);

% Display colorbar to show weight-color mapping
c = colorbar;
c.Label.String = 'Connection Strength';

% Set the node size based on degree or another metric
nodeSizes = 5 ; % Adjust multiplier for better visualization
h.MarkerSize = nodeSizes;

% Add node indices as labels
nodeLabels = arrayfun(@num2str, 1:numnodes(G), 'UniformOutput', false);
labelnode(h, 1:numnodes(G), nodeLabels);

% Set the color limits of the colorbar
caxis([minW maxW]);
%% Example adjacency matrix for a directed graph
A = mynet.w(:, :)';

% Define a threshold for strong connections
min_threshold = -10; % Adjust this value based on your criteria for strong connections
max_threshold = -9;

% Create a directed graph object
G = digraph(A);

% Extract the weights from the adjacency matrix
weights = G.Edges.Weight;

% Filter edges based on the threshold
strongEdges = (weights > min_threshold) & (weights < max_threshold);
G = rmedge(G, find(~strongEdges)); % Remove edges that are below the threshold

% Define the number of excitatory and inhibitory cells
numExcitatory = 320;
numInhibitory = 80;

% Define node colors
nodeColors = zeros(numnodes(G), 3);
nodeColors(1:numExcitatory, :) = repmat([0 0 1], numExcitatory, 1); % Blue for excitatory
nodeColors(numExcitatory+1:end, :) = repmat([1 0 0], numInhibitory, 1); % Red for inhibitory

% Generate node positions to cluster excitatory and inhibitory cells
positions = zeros(numnodes(G), 2);
positions(1:numExcitatory, 1) = linspace(1, 5, numExcitatory); % Cluster excitatory cells in one area
positions(numExcitatory+1:end, 1) = linspace(1, 5, numInhibitory); % Cluster inhibitory cells in another area
positions(1:numExcitatory, 2) = 20 + 3*randn(1, numExcitatory); % Set a common y-position for excitatory cells
positions(numExcitatory+1:end, 2) = -20 + 3*randn(1, numInhibitory); % Set a common y-position for inhibitory cells

% Plot the graph
h = plot(G, 'XData', positions(:, 1), 'YData', positions(:, 2));

% Set node colors
h.NodeColor = nodeColors;

% Customize edge colors based on weights
weights = G.Edges.Weight;
minW = min(weights);
maxW = max(weights);
normalizedWeights = (weights - minW) / (maxW - minW);
cmap = [linspace(1, 0, 256)', linspace(1, 0, 256)', linspace(1, 0, 256)']; % White to black colormap
colorIndices = round(normalizedWeights * (size(cmap, 1) - 1)) + 1;
edgeColors = cmap(colorIndices, :);

% Apply edge colors
h.EdgeCData = colorIndices;
h.EdgeColor = 'flat';

% Apply the colormap and display colorbar
colormap(cmap);
colorbar;

% Optionally, customize other plot properties
h.MarkerSize = 5;
h.LineWidth = 1.5; % Make edges more visible

%% ISI (InterSpike Interval) Analysis

Ex_firings = data.firings(:, data.firings(2, :) <= mynet.Ne);
Inh_firings = data.firings(:, data.firings(2, :) > mynet.Ne);

ISI = ISI_Calculator(data.firings);
ISI_ex = ISI_Calculator(Ex_firings);
ISI_inh = ISI_Calculator(Inh_firings);
       
hold on 
%figure("Name" , "Interspike Interval (ISI) Analysis", HandleVisibility= 'on')
%tiledlayout(2, 1);

caption = strcat('$$\sigma_{e} = ', num2str(mynet.sigma_ex), ',  \sigma_{i} = ', num2str(mynet.sigma_inh),  ',  g_{ee} = ' , num2str(mynet.g_ee), ',  g_{ei} = ', num2str(mynet.g_ei), ',  g_{ie} = ', num2str(mynet.g_ie), '$$');
nbins_ex = 250;
nbins_inh = 400;

ax1 = nexttile;
title(ax1, {'Interspike Interval (ISI)'}, 'interpreter', 'latex')

hold on 

h = histogram(ax1, ISI_ex, nbins_ex, 'Normalization', 'pdf', EdgeColor='none', FaceAlpha = 0.2, DisplayName=strcat('Ex , ', caption));
hold on 
% xline(ax1, min(ISI_ex), 'k--', Label= strcat('Min (' , int2str(min(ISI_ex)), ' ms)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
xline(ax1, mean(ISI_ex), 'k--', Label= strcat('Mean ('  , int2str(mean(ISI_ex)), ' ms)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
%[kernel, edges] = ksdensity(ISI_ex, 'Function','pdf', 'Bandwidth', 0.01,'Support','positive');
%plot(edges,kernel)
%t_max = edges(kernel == max(kernel));
t_max = h.BinWidth/2 + h.BinEdges(h.Values == max(h.Values));
% t_max = mode(ISI_ex); 
xline(ax1, t_max, 'k--', Label= strcat('Max (', int2str(t_max), ' ms)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')

h = histogram(ax1, ISI_inh, nbins_inh, 'Normalization', 'pdf', EdgeColor='none', FaceAlpha = 0.2, DisplayName=strcat('Inh , ', caption));
hold on 
% xline(ax1, min(ISI_inh), 'k--', Label= strcat('Min (' , int2str(min(ISI_inh)), ' ms)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
xline(ax1, mean(ISI_inh), 'k--', Label= strcat('Mean ('  , int2str(mean(ISI_inh)), ' ms)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
%[kernel, edges] = ksdensity(ISI_inh, 'Function','pdf', 'Bandwidth', 0.01,'Support','positive');
%plot(edges,kernel)
%t_max = edges(kernel == max(kernel));
t_max = h.BinWidth/2 + h.BinEdges(h.Values == max(h.Values));
% t_max = mode(ISI_inh);
xline(ax1, t_max, 'k--', Label= strcat('Max (', int2str(t_max), ' ms)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')

xlabel('time (ms)')
ylabel('PDF')
xlim([0, prctile(ISI, 90)])
legend('interpreter', 'latex')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax2 = nexttile;
title(ax2, 'Frequency (Inverse of ISI)', 'interpreter', 'latex')

hold on
f =  1000*ISI.^-1;
f_ex = 1000*ISI_ex.^-1;
f_inh = 1000*ISI_inh.^-1;

hold on
h = histogram(ax2, f_ex, nbins_ex,'Normalization', 'pdf', EdgeColor='none', FaceAlpha=0.2, DisplayName=strcat('Ex , ', caption));
% xline(ax2, min(f_ex), 'k--', Label= strcat('Min (' , num2str(round(mean(f_ex), 1)), ' Hz)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
xline(ax2, mean(f_ex), 'k--', Label= strcat('Mean ('  , num2str(round(mean(f_ex), 1)), ' Hz)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
%[kernel, edges] = ksdensity(f_ex, 'Function','pdf', 'Bandwidth', 0.001 ,'Support','positive');
%plot(edges, kernel)
% f_max = edges(kernel == max(kernel));
f_max = h.BinWidth/2 + h.BinEdges(h.Values == max(h.Values));
% f_max = mode(f_ex);
xline(ax2, f_max, 'k--', Label= strcat('Max (', num2str(round(f_max, 1)), ' Hz)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')

h = histogram(ax2, f_inh, nbins_inh,'Normalization', 'pdf', EdgeColor='none', FaceAlpha=0.2, DisplayName=strcat('Inh , ', caption));
hold on 
% xline(ax2, min(f_inh), 'k--', Label= strcat('Min (' , num2str(round(mean(f_inh), 1)), ' Hz)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
xline(ax2, mean(f_inh), 'k--', Label= strcat('Mean ('  , num2str(round(mean(f_inh), 1)), ' Hz)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')
%[kernel, edges] = ksdensity(f_inh, 'Function','pdf', 'Bandwidth', 0.001,'Support','positive');
%plot(edges, kernel)
%f_max = edges(kernel == max(kernel));
f_max = h.BinWidth/2 + h.BinEdges(h.Values == max(h.Values));
% f_max = mode(f_inh);
xline(ax2, f_max, 'k--', Label= strcat('Max (', num2str(round(f_max, 1)), ' Hz)'), LabelOrientation='aligned', HandleVisibility= 'off', LabelHorizontalAlignment='left')

xlabel('frequency (Hz)')
ylabel('PDF')   
xlim([0, prctile(f, 90)])
legend('interpreter', 'latex')

%%

% Define the ranges for w and t
w_arr = -10:0.5:10;  % Using a larger step size to reduce the number of lines for clarity
t_arr = -100:0.1:100;  % Using a larger step size to reduce the number of points for clarity

% Create a new figure
figure;
hold on;

% Loop through each value of w and plot the STDP_kernel function
for w = w_arr
    dw_values = arrayfun(@(t) IzhikevichNetwork.STDP_kernel([], w, t), t_arr);
    plot(t_arr, dw_values, 'DisplayName', ['w = ' num2str(w)]);
end

% Add labels and legend
xlabel("time (ms)");
ylabel("dw");
title("STDP Kernel for different values of w");

hold off;

% Create a new figure
figure;
hold on;

% Loop through each value of w and plot the STDP_kernel function
for t = t_arr
    dw_values = arrayfun(@(w) IzhikevichNetwork.STDP_kernel([], w, t), w_arr);
    plot(w_arr, dw_values, 'DisplayName', ['w = ' num2str(w)]);
end

% Add labels and legend
xlabel("w");
ylabel("dw");
title("STDP Kernel for different values of t");

hold off;

%% Two consecutive patterns fed to the network 


%% Functions
function list = replace_by_order(list)
    unique_elements = sort(unique(list));
    element_order = containers.Map(unique_elements, 1:numel(unique_elements));
    for i = 1:numel(list)
        list(i) = element_order(list(i));
    end
end

function ISI = ISI_Calculator(firings)

    num_neurons = max(firings(2, :)); % Assuming neuron indices are 1-based
    base = zeros(num_neurons, 1); % Initialize the last spike times to zero
    ISI = []; % Initialize an empty list to store ISIs
    
    for i = 1:size(firings, 2)
        current_time = firings(1, i); % Spike time
        neuron_index = firings(2, i); % Neuron index
        
        if base(neuron_index) > 0 % Check if this is not the first spike
            current_ISI = current_time - base(neuron_index); % Calculate ISI
            ISI = [ISI, current_ISI]; % Append ISI to the list
        end
    
        base(neuron_index) = current_time; % Update the last spike time for the neuron
    end

end



