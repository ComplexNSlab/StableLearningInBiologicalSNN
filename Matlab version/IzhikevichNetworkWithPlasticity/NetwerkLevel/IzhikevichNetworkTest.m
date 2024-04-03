clear;
clc; 
mynet = IzhikevichNetwork(400);

mynet.noise = false;
mynet.sigma = 2;

mynet.input = true;

mynet.plasticity = true;
mynet.alpha = 20;


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
ylim([-20, 5])
hold off;

%% dynamic of synaptic weights histogram


fig = figure('name', 'Weights Histogram');
for i = 1:10:size(data.w, 3)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    histogram(nonzeros(data.w(:, :, i)), 400);
    title(sprintf('Weights Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000))
    % hold on 
    % histogram(nonzeros(data.w(1:mynet.Ne, mynet.Ne+1:end, i)), 'Normalization', 'probability');
    % histogram(nonzeros(data.w(mynet.Ne+1:end, 1:mynet.Ne, i)), 'Normalization', 'probability');
    % legend('Ex -> Ex', 'Inh -> Ex', 'Ex -> Inh')

    pause(0.1); % Pause to view the histogram
end

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
hold on;
% Plot the mean lines
plot(x/1000, meanLine1, 'k-', 'LineWidth', 2); 

plot(x/1000, meanLine2, 'b-', 'LineWidth', 2);

% Shade the area between upper and lower bounds
% fillColor = [0.8, 0.8, 0.8]; % Light gray fill
fill(xPolygon/1000, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5);

fill(xPolygon/1000, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5);

% Additional plot adjustments
xlabel('time (s)');
ylabel('A (Hz)');
title('Plot with Shaded Std Dev');
legend('Ex', 'In')
hold off;
%% dynamic of A histogram


fig = figure('name', 'A Histogram');
for i = 1:5:size(data.A, 2)
    clf; % Clear the figure for the next histogram
    % Update figure title dynamically
    set(fig, 'Name', sprintf('A Histogram at Time %.2f s', i*mynet.sampling_rate*mynet.dt/1000));
    
    hold on
    histogram(1000*data.A(1:mynet.Ne, i), mynet.Ne, 'Normalization', 'probability');
    histogram(1000*data.A(mynet.Ne+1:end, i), mynet.Ni, 'Normalization', 'probability');
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
plot(mynet.firings(:, 1), mynet.firings(:, 2), 'k.')


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
    
%% Sorted Rater plot of different trials (Input should be on!)

figure();

for trial_number = 198:round(mynet.t/1000)
    clf;
    check_flag = zeros(1, mynet.N);
    
    indices = (mynet.firings(:, 1) > (trial_number-1) * 1000) & (mynet.firings(:, 1) <= trial_number * 1000);
    spike_times = mynet.firings(indices, 1) - (trial_number-1)*1000;
    neuron_indices = mynet.firings(indices, 2);
    
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
                plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
                
            end
        else
            if check_flag(neuron_indices(i)) == 0
                plot(spike_times(i), counter_inh, 'k.');
                
                check_flag(neuron_indices(i)) = counter_inh;
                counter_inh = counter_inh + 1;
            else
                plot(spike_times(i), check_flag(neuron_indices(i)), 'r.');
                
            end
        end

    end
    
    xlabel('time (ms)')
    ylabel('neuron index')
    title(sprintf('trial number %d raster plot', trial_number))
    plot([0, 50], (mynet.Ne + 0.5)*[1, 1], 'r-')
    plot([0, 50], (10 + 0.5)*[1, 1], 'b-')
    xlim([0, 50])
    pause(0.1)
end

%% 
Ne = 320;
Ni = 80;
N = Ne + Ni;


w = zeros(N, N);

for i = 1:Ne
    array = [1:i-1, i+1:Ne]; % Example array
    randomChoices = array(randperm(length(array), 20));
      
    w(i, randomChoices) = abs(0.5 + sqrt(0.05*0.5)*randn(1, 20));
    w(i, Ne + randperm(Ni, 5)) = -8 + sqrt(0.05*8)*randn(1, 5);
end

for i = Ne+1:N
    w(i, randperm(Ne, 5)) = 2 + sqrt(0.05*2)*randn(1, 5);
end



