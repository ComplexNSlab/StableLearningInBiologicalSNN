%clearvars -except mynet stims
clearvars -except mynet
data = mynet.getData();

firings = data.firings;

%%
%clearvars -except mynet data stims
nrows = 3; ncols = 2;
% Get the screen size
screenSize = get(0, 'ScreenSize');

% Create a full-screen figure
figure('Position', screenSize);

% Prepare data
w = data.w(1:mynet.Ne, 1:mynet.Ne, :);
if mynet.stimulation
    pattern = mynet.stims(1).pattern_indices;
    neworder = [pattern setdiff(1:mynet.Ne, pattern)];
    w = w(neworder, neworder, :);
 end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows, ncols, 1:ncols:ncols*nrows);


img = imagesc(w(:, :, 1)); % Create the initial image
clim([0 3]);
alphaData = ones(size(w(:, :, 1))); % Create initial alpha data
%alphaData(w(:, :, 1) == 0) = 0;
set(img, 'AlphaData', alphaData);
cb = colorbar();
cb.Label.String = "Synapse Strength";
colormap jet;
if mynet.stimulation
    rectHandle = rectangle('Position', [0.1 0.1 length(pattern) length(pattern)], 'EdgeColor', 'r', 'LineWidth', 3);
end
set(gca, 'YDir', 'normal', 'fontsize', 15);

% Set up the axes properties outside of the loop
titleHandle = title(""); % Initialize the title handle
xlabel("Pre Synaptic Cell");
ylabel("Post Synaptic Cell");
axis equal;
axis tight;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows, ncols, 2);
hold on;
xlabel("Time (s)");
ylabel("Synaptic Strength");
set(gca, 'fontsize', 15)
ylim([0 3])
xlim([0 mynet.t/1000])

if mynet.stimulation
    cell = pattern(randi(length(pattern)));
else
    cell = randi(mynet.Ne);
end

out_cells = mynet.out_cells(cell); 
out_cells = out_cells(out_cells <= mynet.Ne);
yData222 = squeeze(data.w(out_cells, cell, :))'; % Collect Y data

hlines222 = plot(yData222-3, 'k-');
title(sprintf("Outward Synaptic connections of Cell %d", cell))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows, ncols, 4);
hold on;
xlabel("Time (s)");
ylabel("Synaptic Strength");
set(gca, 'fontsize', 15)
ylim([0 3])
xlim([0 mynet.t/1000])


out_cells = mynet.in_cells(cell); 
out_cells = out_cells(out_cells <= mynet.Ne);
yData223 = squeeze(data.w(cell, out_cells, :))'; % Collect Y data

hlines223 = plot(yData223-3, 'k-');
title(sprintf("Inward Synaptic connections of Cell %d", cell))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows, ncols, 6);
hold on;
xlabel("Time (s)");
ylabel("Neuron index");
title("Raster plot")

xlim([0 100])
% ylim([0 mynet.N])
% firings = data.firings;
% yData224 = firings;
% 
% hline224 = plot([1 2], [1 2], MarkerSize=1, Marker = '.', MarkerFaceColor='r', LineStyle='none');
hline224 = plot(firings(1, 1:2), firings(2, 1:2), 'k.');

set(gca, 'fontsize', 15)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop through the time steps

for i = 1:size(data.w, 3)
    % Update the image and alpha data in the first subplot
   
    set(img, 'CData', w(:, :, i)); % Update the image data
    %alphaData(:) = 1; % Reset alpha data
    %alphaData(w(:, :, i) == 0) = 0.9; % Make 0 values transparent
    %set(img, 'AlphaData', alphaData); % Apply the alpha data

    set(titleHandle, 'String', sprintf("time %0.1f s", i * mynet.sampling_rate * mynet.dt / 1000));

    % Update the second subplot only if i > 1
    if i > 1
        t = mynet.sampling_rate*mynet.dt/1000;
        for itr = 1:size(hlines222, 1)
            set(hlines222(itr), 'Xdata', t*(1:i),'YData', yData222(1:i, itr));      
        end
        for itr = 1:size(hlines223, 1)
            set(hlines223(itr), 'Xdata', t*(1:i),'YData', yData223(1:i, itr));             
        end
        ind = firings(1, :) <= i*t*1000;
        set(hline224, 'Xdata', firings(1, ind)/1000,'YData', firings(2, ind), 'MarkerFaceColor', 'k');
    end
    
    pause(0.0); % Optional: pause to view each frame for 0.01 seconds
end
%%
figure;

