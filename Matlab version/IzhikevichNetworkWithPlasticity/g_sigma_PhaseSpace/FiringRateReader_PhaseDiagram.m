%% This codes enable us to read average firing rates of (Inh, Exc) cells in g_sigma phase diagram 

load("./HighResolutionWorkSpaceData2.mat", 'i_rates', 'e_rates', 'g', 'sigma');

g_max = 1;
sigma_max = 15;

g_max = find(g == g_max);
sigma_max = find(sigma == sigma_max);

data1 = transpose(e_rates(1:g_max, 1:sigma_max)); 
data2 = transpose(i_rates(1:g_max, 1:sigma_max));

% Define custom x and y axis values
x_values = g(1:g_max); % Replace with your actual x axis values
y_values = sigma(1:sigma_max); % Replace with your actual y axis values



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot 3D surf of rates Vs. g-sigma plane
figure('Name', 'Excitatory cells firing rates');
surf(x_values, y_values, data1);
xlabel('g');
ylabel('sigma');
zlabel('rate (Hz)');
title('Excitatory cells');

figure('Name', 'Inhibitory cells firing rates');
surf(x_values, y_values, data2);
xlabel('g');
ylabel('sigma');
zlabel('rate (Hz)');
title('Inhibitory cells');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot heatmap with custom axis values
figure('Name', 'Excitatory cells firing rates');
imagesc(x_values, y_values, data1);
c = colorbar; % Adds a colorbar to indicate the scale
c.Label.String = 'Hz';
set(gca,'YDir','normal') % Keeps the Y-axis direction normal
% Labeling the axes
xlabel('g');
ylabel('sigma');
title('Excitatory cells')

% Enable data cursor mode
dcm_obj = datacursormode(gcf);
set(dcm_obj,'Enable','on'); % Explicitly enable data cursor mode
% Set the custom update function with an anonymous function
set(dcm_obj, 'UpdateFcn', @(src, event)myupdatefcn(src, event, data1, g, sigma));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Inhibitory cells firing rates');
imagesc(x_values, y_values, data2);
c = colorbar; % Adds a colorbar to indicate the scale
c.Label.String = 'Hz';
set(gca,'YDir','normal') % Keeps the Y-axis direction normal
% Labeling the axes
xlabel('g');
ylabel('sigma');
title('Inhibitory cells')

% Enable data cursor mode
dcm_obj = datacursormode(gcf);
set(dcm_obj,'Enable','on'); % Explicitly enable data cursor mode
% Set the custom update function with an anonymous function
set(dcm_obj, 'UpdateFcn', @(src, event)myupdatefcn(src, event, data2, g, sigma));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the custom update function as a local function
function txt = myupdatefcn(~, event_obj, data, x, y)
    pos = get(event_obj, 'Position'); % Get the position of the data cursor
    

    dataValue = data(abs(y - pos(2)) < 0.0001, abs(x - pos(1)) < 0.0001); % Extract the data value at the cursor's position
    
   % Create the tooltip text
    txt = {['g: ', num2str(pos(1))], ...
           ['sigma: ', num2str(pos(2))], ...
           ['Value: ', num2str(dataValue, '%.4f')]}; % Display value with 4 decimal places
end
