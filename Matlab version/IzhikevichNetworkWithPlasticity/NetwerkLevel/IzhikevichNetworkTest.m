clear;
clc; 
mynet = IzhikevichNetwork(400);

mynet.noise = false;
mynet.sigma = 5;

mynet.STDP = true;

mynet.input = true;
mynet.input_interval = 1000;
mynet.input_duration = 10;

mynet.scaling = false;
mynet.A_goal = [0.001*ones(mynet.Ne, 1); 0.002*ones(mynet.Ni, 1)];
mynet.alpha = 20;

%%
for i=1:12
    mynet.run(250000);
end
% data = mynet.getData();

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

figure()
% Plot the mean lines
plot(x/1000, meanLine1, 'k', 'LineWidth', 2); 
hold on;
plot(x/1000, meanLine2, 'b.-', 'LineWidth', 2)
plot(x/1000, meanLine3, 'r', 'LineWidth', 2)

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

fill(xPolygon/1000, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
hold on
fill(xPolygon/1000, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
fill(xPolygon/1000, yPolygon3, 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5);

% Additional plot adjustments
xlabel('time (s)');
ylabel('W');
title('population average of w Vs. time');
legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')
ylim([-20, 10])
hold off;

%% dynamic of synaptic weights histogram

fig = figure('name', 'Weights Histogram');
for i = 1:5:size(data.w, 3)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    % histogram(nonzeros(data.w(:, :, i)), 400);
    title(sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    hold on 
    histogram(data1(:, i), 100, 'Normalization', 'probability');
    histogram(data2(:, i), 100, 'Normalization', 'probability');
    histogram(data3(:, i), 100, 'Normalization', 'probability');
    legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')

    pause(0.1); % Pause to view the histogram
end

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
    histogram(1000*data.A(1:mynet.Ne, i), mynet.Ne/4, 'Normalization', 'probability');
    histogram(1000*data.A(mynet.Ne+1:end, i), mynet.Ni/4, 'Normalization', 'probability');
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
%% Raster plot
figure()
firings = data.firings;
plot(firings(1, :), firings(2, :), 'k.')


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
figure();
firings = transpose(data.firings);
interval = mynet.input_interval;
for trial_number = 1500:round(mynet.t/interval)
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
    title(sprintf('trial number %d raster plot', trial_number))
    plot([0, mynet.input_interval], (mynet.Ne + 0.5)*[1, 1], 'r-')
    plot([0, mynet.input_interval], (10 + 0.5)*[1, 1], 'b-')
    xlim([0, 100])
    ylim([0, mynet.N + 0.5])
    
    
    pause(0.05)

end
%% save mp4 file for raster plots animation

% Define the video file name
videoFileName = 'raster_plots2';

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
    
    title(sprintf('trial number %d raster plot', trial_number))
    plot([0, mynet.input_interval], (mynet.Ne + 0.5)*[1, 1], 'r-')
    plot([0, mynet.input_interval], (10 + 0.5)*[1, 1], 'b-')
    xlim([0, 100])
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
t_min = 149000; t_max = 150000;
check = firings(1, :) >= t_min & firings(1, :) <= t_max;
firings = firings(:, check);

idx = 20; % neuron to analyze
in_cells = mynet.in_cells(idx);
out_cells = mynet.out_cells(idx);

in_firings = firings(:, ismember(firings(2, :), in_cells));
out_firings = firings(:, ismember(firings(2, :), out_cells));

y_in = replace_by_order(in_firings(2, :));
y_out = replace_by_order(out_firings(2, :)) + max(unique(y_in)) + 1;

hold on

plot(in_firings(1, :), y_in, 'r*');
plot(firings(1, firings(2, :) == idx), repmat(length(unique(y_in)) + 1, 1, sum(firings(2, :) == idx)), 'k*');
plot(out_firings(1, :), y_out, 'b*');

yticks([unique(y_in), max(unique(y_in)) + 1, unique(y_out)])
yticklabels({unique(in_firings(2, :)), 'Selected Neuron', unique(out_firings(2, :))})

legend('input', 'cell', 'output')
xline(firings(1, firings(2, :) == idx), 'HandleVisibility', 'off', 'Alpha', 0.1, 'LineWidth', 0.2)

xlabel('t (ms)')
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

%% 
function list = replace_by_order(list)
    unique_elements = sort(unique(list));
    element_order = containers.Map(unique_elements, 1:numel(unique_elements));
    for i = 1:numel(list)
        list(i) = element_order(list(i));
    end
end
