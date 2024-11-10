%% finding reference point
clc
clear 
%%
noise = [5, 2];
g_ie = 2;
simulation_time = 50000;
%%
ref_point = get_point(noise, [0, 0, 0], simulation_time);
%% Running for a 2D grid for g_ee and g_ei with feutures about ISI and frequency

g_ee_arr = 0.3:0.05:1; g_ei_arr = 5:1:20;
points = zeros(length(g_ee_arr), length(g_ei_arr),4 ,4);

f = waitbar(0, 'Wait');
for i = 1:length(g_ee_arr)
    for j = 1:length(g_ei_arr)
        waitbar(((i-1)*length(g_ei_arr) + j)/(length(g_ei_arr)*length(g_ee_arr)), f, sprintf("wait g_{ee} = %0.1f g_{ei} = %0.1f ", g_ee_arr(i), g_ei_arr(j)))
        point = get_point(noise, [g_ee_arr(i) , g_ei_arr(j), g_ie], simulation_time);
        points(i, j, :, :) = point;
    end
end
close(f)
clear f

%% Analyzing the outcomes
cp = 'cool';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'ISI Analysis');

feature_names = ["ISI_{Mean}", "ISI_{Peak}", "ISI_{Median}", "ISI_{IQR} (IQR=Q_3-Q_1)"];
feature_indices = [1, 2, 3, 4];

for i = 1 :length(feature_indices)
    nexttile()

    im = image([g_ee_arr(1) g_ee_arr(end)], [g_ei_arr(1) g_ei_arr(end)], transpose(points(:, :, 1, feature_indices(i))));
    im.CDataMapping = 'scaled';
    c = colorbar(); 
    xlabel('g_{ee}');
    ylabel('g_{ei}');
    set(gca,'YDir','normal')

    title(feature_names(i));
    c.Label.String = 'ms';
    
    colormap(cp)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Relative ISI Analysis');

feature_names = ["\Delta ISI_{Mean}", "\Delta ISI_{Peak}", "\Delta ISI_{Median}", "\Delta ISI_{IQR} (IQR=Q_3-Q_1)"];
feature_indices = [1, 2, 3, 4];

for i = 1 :length(feature_indices)
    nexttile()

    im = image([g_ee_arr(1) g_ee_arr(end)], [g_ei_arr(1) g_ei_arr(end)], transpose(points(:, :, 1, feature_indices(i))-ref_point(1, feature_indices(i))));
    im.CDataMapping = 'scaled';
    c = colorbar(); 
    xlabel('g_{ee}');
    ylabel('g_{ei}');
    set(gca,'YDir','normal')

    title(feature_names(i));
    c.Label.String = 'ms';
    
    colormap(cp)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Frequency Analysis');

feature_names = ["f_{Mean}", "f_{Peak}", "f_{Median}", "f_{IQR} (IQR=Q_3-Q_1)"];
feature_indices = [1, 2, 3, 4];

for i = 1 :length(feature_indices)
    nexttile()

    im = image([g_ee_arr(1) g_ee_arr(end)], [g_ei_arr(1) g_ei_arr(end)], transpose(points(:, :, 2, feature_indices(i))));
    im.CDataMapping = 'scaled';
    c = colorbar(); 
    xlabel('g_{ee}');
    ylabel('g_{ei}');
    set(gca,'YDir','normal')

    title(feature_names(i));
    c.Label.String = 'Hz';
    
    colormap(cp)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Relative Frequency Analysis');

feature_names = ["\Delta f_{Mean}", "\Delta f_{Peak}", "\Delta f_{Median}", "\Delta f_{IQR} (IQR=Q_3-Q_1)"];
feature_indices = [1, 2, 3, 4];

for i = 1 :length(feature_indices)
    nexttile()

    im = image([g_ee_arr(1) g_ee_arr(end)], [g_ei_arr(1) g_ei_arr(end)], transpose(points(:, :, 2, feature_indices(i)) - ref_point(2, feature_indices(i))));
    im.CDataMapping = 'scaled';
    c = colorbar(); 
    xlabel('g_{ee}');
    ylabel('g_{ei}');
    set(gca,'YDir','normal')

    title(feature_names(i));
    c.Label.String = 'Hz';
    
    colormap(cp) 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions

function data_point = get_point(noise, g, TotalTime)
    %% g must be a vector in  [g_ee, g_ei, g_ie] format and noise in [sigma_e, sigma_i] format
    %% format of output [mean, peak, median, first quantile, third quantile]

    net = IzhikevichNetwork(400);
    net.noise = true;
    net.sigma_ex = noise(1);
    net.sigma_inh = noise(2);
    net.SetInitialConnectivity(g(1), g(2), g(3))
    net.sampling = false; 
    
    net.run(TotalTime)

    Ex_firings = net.firings(net.firings(:, 2) <= net.Ne, :)';
    Inh_firings = net.firings(net.firings(:, 2) > net.Ne, :)';
    
    ISI_ex_point = nan(1, 4);
    frequency_ex_point = nan(1, 4);
    ISI_inh_point = nan(1, 4);
    frequency_inh_point = nan(1, 4);
   
    if size(Inh_firings, 2) >= 10
        ISI_inh = ISI_Calculator(Inh_firings);
        f_inh = 1000*ISI_inh.^-1; 

        [N, edges] = histcounts(ISI_inh);
        t_inh_peak = (edges(2) - edges(1))/2 + edges(N == max(N));

        [N, edges] = histcounts(f_inh);
        f_inh_peak = (edges(2) - edges(1))/2 + edges(N == max(N));

        ISI_inh_point = [mean(ISI_inh), t_inh_peak, prctile(ISI_inh, 50), prctile(ISI_inh, 75) - prctile(ISI_inh, 25)];
        frequency_inh_point = [mean(f_inh), f_inh_peak, prctile(f_inh, 50), prctile(f_inh, 75) - prctile(f_inh, 25)];

        if length(frequency_inh_point) ~= 4  || length(ISI_inh_point) ~= 4
            ISI_inh_point = nan(1, 4);
            frequency_inh_point = nan(1, 4);
        end
    end

    if size(Ex_firings, 2) >= 10
        ISI_ex = ISI_Calculator(Ex_firings);
        f_ex = 1000*ISI_ex.^-1; 
       

        %[kernel, edges] = ksdensity(ISI, 'Support','positive');
        %t_peak = edges(kernel == max(kernel));
        [N, edges] = histcounts(ISI_ex);
        t_ex_peak = (edges(2) - edges(1))/2 + edges(N == max(N));
        
        
        %[kernel, edges] = ksdensity(f, 'Support','positive');
        %f_peak = edges(kernel == max(kernel));
        [N, edges] = histcounts(f_ex);
        f_ex_peak = (edges(2) - edges(1))/2 + edges(N == max(N));
        
       
        ISI_ex_point = [mean(ISI_ex), t_ex_peak, prctile(ISI_ex, 50), prctile(ISI_ex, 75) - prctile(ISI_ex, 25)];
        frequency_ex_point = [mean(f_ex), f_ex_peak, prctile(f_ex, 50), prctile(f_ex, 75) - prctile(f_ex, 25)];
        
        
        if length(ISI_ex_point) ~= 4 || length(frequency_ex_point) ~= 4 
            ISI_ex_point = nan(1, 4); 
            frequency_ex_point = nan(1, 4);
        end
    end

    data_point = [ISI_ex_point; frequency_ex_point; ISI_inh_point; frequency_inh_point];
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