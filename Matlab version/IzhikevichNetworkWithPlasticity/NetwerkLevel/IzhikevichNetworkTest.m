clear;
clc; 
mynet = IzhikevichNetwork(400);
mynet.noise = false;
mynet.run(200000);


data = mynet.Data;

%% a single cell voltage trace with syanptic inputs

cell_number = 11;

% ax1 = subplot(2, 1, 1);
plot(data.time, data.v(cell_number, :))

hold on
% ax2 = subplot(2, 1, 2);   
plot(data.time, 1 * data.I_syn(cell_number, :))

hold off
% linkaxes([ax1, ax2], 'x')

%% dynamic of synaptic weights in time
x = (1:size(data.w, 3))*mynet.dt*mynet.sampling_rate;  % Assuming meanValues is your array of mean values

data1 = reshape(data.w(1:mynet.Ne, 1:mynet.Ne, :), mynet.Ne*mynet.Ne, length(x));
data2 = reshape(data.w(1:mynet.Ne, mynet.Ne+1:end, :), mynet.Ne*mynet.Ni, length(x));
data3 = reshape(data.w(mynet.Ne+1:end, 1:mynet.Ne, :), mynet.Ni*mynet.Ne, length(x));
data1(data1 == 0) = nan;    
data2(data2 == 0) = nan;
data3(data3 == 0) = nan;

meanLine1 = squeeze(nanmean(data1, 1));     % Mean values
meanLine2 = squeeze(nanmean(data2, 1));
meanLine3 = squeeze(nanmean(data3, 1));
stdDev1 = squeeze(nanstd(data1, 1));        % Standard deviation values
stdDev2 = squeeze(nanstd(data2, 1)); 
stdDev3 = squeeze(nanstd(data3, 1)); 

% Calculate the upper and lower bounds
upperBound1 = meanLine1 + stdDev1;
lowerBound1 = meanLine1 - stdDev1;
upperBound2 = meanLine2 + stdDev2;
lowerBound2 = meanLine2 - stdDev2;
upperBound3 = meanLine3 + stdDev3;
lowerBound3 = meanLine3 - stdDev3;

% Concatenate the upper bound and reversed lower bound
xPolygon = [x, fliplr(x)];  % x coordinates for the polygon
yPolygon1 = [upperBound1, fliplr(lowerBound1)];  % y coordinates for the polygon
yPolygon2 = [upperBound2, fliplr(lowerBound2)];  % y coordinates for the polygon
yPolygon3 = [upperBound3, fliplr(lowerBound3)];  % y coordinates for the polygon

figure()
% Plot the mean lines
plot(x, meanLine1, 'k', 'LineWidth', 2); 
hold on;
plot(x, meanLine2, 'b', 'LineWidth', 2)
plot(x, meanLine3, 'r', 'LineWidth', 2)

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

fill(xPolygon, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
hold on
fill(xPolygon, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
fill(xPolygon, yPolygon3, 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5);

% Additional plot adjustments
xlabel('time (ms)');
ylabel('W');
title('population average of w Vs. time');
legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')
hold off;

%% dynamic of synaptic weights histogram
pause(5)

fig = figure('name', 'Weights Histogram');
for i = 1:4:size(data.w, 3)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    
    histogram(nonzeros(data.w(1:mynet.Ne, 1:mynet.Ne, i)), Normalization="pdf");
    title(sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    hold on 
    histogram(nonzeros(data.w(1:mynet.Ne, mynet.Ne+1:end, i)), 60, Normalization="pdf");
    histogram(nonzeros(data.w(mynet.Ne+1:end, 1:mynet.Ne, i)), 60, Normalization="pdf");
    legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')

    pause(0.0001); % Pause to view the histogram
end
%% Correlation between smoothed spike trains

kernelWidth = 1; % Width of the kernel in number of samples
kernel = normpdf(-3*kernelWidth:3*kernelWidth, 0, kernelWidth);

numNeurons = size(data.spike_train, 1);
T = size(data.spike_train, 2); % Total time points or length of each spike train

% Preallocate a matrix to hold the smoothed spike trains
smoothedSpikeTrains = zeros(numNeurons, T);

% Smooth each spike train
for i = 1:numNeurons
    % Convolve and keep the central part of the result to match the original length
    smoothed = conv(data.spike_train(i, :), kernel, 'same');
    smoothedSpikeTrains(i, :) = smoothed;
end

% Calculate pairwise correlation efficiently on smoothed data
correlationMatrix = corr(smoothedSpikeTrains');
for i = 1:size(correlationMatrix, 1)
    correlationMatrix(i, i) = 0;
end

clf;
% For the histogram
figure(1);

histogram(correlationMatrix);

% For the imshow
figure(2);
imshow(correlationMatrix);
colormap(jet(256)); % Apply colormap to the current figure (figure 2)
clim([-0.3, 0.4]); % Set color limits for the current axes
colorbar; 

% Add a colorbar to the current figure (figure 2)
% clim([-1 1]); % Fixing the color scale to range from -1 to 1
% colorbar; % Show colorbar
%% population average A Vs. time

x = (1:size(data.A, 2))*mynet.dt*mynet.sampling_rate;  % Assuming meanValues is your array of mean values
meanLine1 = mean(1000*data.A(1:mynet.Ne, :), 1);     % Mean values
meanLine2 = mean(1000*data.A(mynet.Ne+1:end, :), 1);   
stdDev1 = std(data.A(1:mynet.Ne, :), 1);        % Standard deviation values
stdDev2 = std(data.A(mynet.Ne+1:end, :), 1); 

% Calculate the upper and lower bounds
upperBound1 = meanLine1 + stdDev1;
lowerBound1 = meanLine1 - stdDev1;
upperBound2 = meanLine2 + stdDev2;
lowerBound2 = meanLine2 - stdDev2;

% Concatenate the upper bound and reversed lower bound
xPolygon = [x, fliplr(x)];  % x coordinates for the polygon
yPolygon1 = [upperBound1, fliplr(lowerBound1)];  % y coordinates for the polygon
yPolygon2 = [upperBound2, fliplr(lowerBound2)];  % y coordinates for the polygon

figure()
% Plot the mean lines
plot(x, meanLine1, 'k.-', 'LineWidth', 2); 
hold on;
plot(x, meanLine2, 'b.-', 'LineWidth', 2);

% Shade the area between upper and lower bounds
% fillColor = [0.8, 0.8, 0.8]; % Light gray fill
fill(xPolygon, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
hold on
fill(xPolygon, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5);

% Additional plot adjustments
xlabel('time (ms)');
ylabel('A (Hz)');
title('Plot with Shaded Std Dev');
legend('Ex', 'In')
hold off;
%% dynamic of A histogram
% pause(5)

fig = figure('name', 'A Histogram');
for i = 1:1:size(data.A, 2)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('A Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    
    histogram(1000*data.A(1:mynet.Ne, i), 320, Normalization="pdf");
    title(sprintf('A Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    hold on 
    histogram(1000*data.A(mynet.Ne+1:end, i), 80, Normalization="pdf");
    legend('Ex', 'Inh')
    xlim([0, 3])
    pause(0.0001); % Pause to view the histogram
end
%% Raster plot
plot(mynet.firings(:, 1), mynet.firings(:, 2), 'k.')

%% Rater plot of last trial

figure();

for trial_number = 1:round(mynet.t/1000)
    clf;
    check_flag = zeros(1, mynet.N);
    
    indices = (mynet.firings(:, 1) > (trial_number-1) * 1000) & (mynet.firings(:, 1) <= trial_number * 1000);
    spike_times = mynet.firings(indices, 1) - (trial_number-1)*1000;
    neuron_indices = mynet.firings(indices, 2);
    
    counter_ex = 1;
    counter_inh = mynet.Ne+1;
    for i = 1:length(spike_times)
        if neuron_indices(i) <= mynet.Ne
            if check_flag(neuron_indices(i)) == 0
                plot(spike_times(i), counter_ex, 'k.');
                hold on
                check_flag(neuron_indices(i)) = counter_ex;
                counter_ex = counter_ex + 1;
            else
                plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
                hold on 
            end
        else
            if check_flag(neuron_indices(i)) == 0
                plot(spike_times(i), counter_inh, 'k.');
                hold on
                check_flag(neuron_indices(i)) = counter_inh;
                counter_inh = counter_inh + 1;
            else
                plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
                hold on 
            end
        end

    end
    xlim([0, 50]);
    xlabel('time (ms)')
    ylabel('neuron index')
    title(sprintf('trial number %d raster plot', trial_number))
    
    pause(0.1)
end

    





