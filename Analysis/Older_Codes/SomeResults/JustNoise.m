% Define the ranges for the parameters
G_ee_range = 0.2 : 0.2 : 2; 
G_ei_range = 7 : 0.2 : 9; 
G_ie_range = 1.5 : 0.2 : 2.5; 
SigmaEx_range = 4 : 0.2 : 6; 
SigmaInh_range = 1.5: 0.2 :2.5; 

% Preallocate a matrix to store variables
firing_rates_ex = zeros(length(G_ee_range), length(G_ei_range), length(G_ie_range), length(SigmaEx_range), length(SigmaInh_range));
firing_rates_inh = zeros(length(G_ee_range), length(G_ei_range), length(G_ie_range), length(SigmaEx_range), length(SigmaInh_range));

f = waitbar(0, 'please wait ...');
% Iterate over the parameter ranges
for i = 1:length(G_ee_range)
    for j = 1:length(G_ei_range)
        for k = 1:length(G_ie_range)
            for m = 1:length(SigmaEx_range)
                for l = 1:length(SigmaInh_range)
                    g_ee = G_ee_range(i);
                    g_ei = G_ei_range(j);
                    g_ie = G_ie_range(k);
                    sigma_ex = SigmaEx_range(m);
                    sigma_inh = SigmaInh_range(l);
                    waitbar((i-1)/length(G_ee_range) + (j-1) /length(G_ei_range)/length(G_ee_range),f,sprintf('g_{ee} %0.1f g_{ei} %0.1f g_{ie} %0.1f sigma_{ex} %0.1f sigma_{inh} %0.1f', g_ee, g_ei, g_ie, sigma_ex, sigma_inh));

                    % Create and configure the network
                    mynet = IzhikevichNetwork(400);
                    mynet.noise = true;
                    mynet.sigma_ex = sigma_ex;
                    mynet.sigma_inh = sigma_inh;

                    mynet.SetInitialConnectivity(g_ee, g_ei, g_ie);

                    mynet.STDP = false;
                    mynet.input = false; 
                    mynet.scaling = false;
                    mynet.sampling = false; 

                    % Simulate the network and calculate firing rates
                    total_run = 2000; % ms
                    mynet.run(total_run)
                    
                    firings = mynet.firings(1:mynet.spike_counter, :);

                    firing_rates_ex(i, j, k, m) = 1000* length(find(firings(:, 2) <= mynet.Ne))/mynet.Ne/total_run;
                    firing_rates_inh(i, j, k, m) = 1000*length(find(firings(:, 2) > mynet.Ne))/mynet.Ni/total_run;

                    % Clear the network object to release memory
                    clear mynet
                end
            end
        end
    end
end

close(f)
