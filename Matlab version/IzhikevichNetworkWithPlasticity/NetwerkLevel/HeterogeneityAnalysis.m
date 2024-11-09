%% Configuring the network 
clear 
clc
rng(2,"twister");

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
mynet.AddHeterogeneity;
mynet.stimulation = false;
mynet.sampling = true;
mynet.noise = true;
%% Run network

mynet.run(500000, false)
data = mynet.getData;
%% 
figure;
hold on 
p1 = plot(data.time, data.A(1:mynet.Ne, :), 'k', DisplayName='Ex');
p2 = plot(data.time, data.A(mynet.Ne+1:end, :), 'r', DisplayName='Inh');
xlabel("time (s)")
ylabel("A (1/s)")
legend([p1(1), p2(1)], {'Ex', 'Inh'})

%% dynamic of synaptic weights in time
x = data.time;  % Assuming meanValues is your array of mean values

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
plot(ax, x, meanLine1, 'k', 'LineWidth', 2, 'Color',"#77AC30"); 
hold on;
plot(ax, x, meanLine2, 'b.-', 'LineWidth', 2, 'Color',"#7E2F8E")
plot(ax, x, meanLine3, 'r', 'LineWidth', 2, 'Color',"#D95319")

fill(xPolygon, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#77AC30");
hold on
fill(xPolygon, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#7E2F8E");
fill(xPolygon, yPolygon3, 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#D95319");

% Additional plot adjustments
xlabel('time (s)');
ylabel('W');
title('Weigths Evolution in Time (90% CI)');
legend('g_{ee}', 'g_{ei}', 'g_{ie}', Location='southwest')
ylim([-5, 5])
hold off;
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 