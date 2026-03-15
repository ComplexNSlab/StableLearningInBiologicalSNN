function Step1_simulation(N, T_noise, T_learning, noise_strength)
    net = IzhikevichNetwork(N, 'g_ee', 0.5, 'g_ei', 2, 'g_ie', 2, 'BaseFolder', fullfile("Data", "N"+num2str(N), "noise" + num2str(round(100*noise_strength)) + "%")); 
    net.tau_A = 5;
    net.sigma_ex = noise_strength * 5 * sqrt(0.5);
    net.sigma_inh = noise_strength * 2 * sqrt(0.5);
    net.heterogeneity = true;

    % Noise driven activity before learning
    net.noise = true;
    net.run(T_noise * 1000); 
    net.noise = false;
    
    % learning window
    net.STDP = true; net.stimulation = true;
    stim = Stimulation(net, 100, 2, 30, 50, 5);
    net.run(T_learning * 1000); 
    net.STDP = false; net.stimulation = false;
    
    % Noise driven activity post learning
    net.noise = true;
    net.run(T_noise * 1000); 
    net.noise = false;
    
    data = net.getData();
    
    % Define the folder path
    folder = fullfile("Results");
    
    % Create the folder if it doesn't exist
    if ~exist(folder, 'dir')
        mkdir(folder);
    end
    
    t_min = 0; t_max = T_noise;
    idx = (data.firings(1, :) > t_min * 1000) & (data.firings(1, :) < t_max * 1000);
    firings = data.firings(:, idx);
    firings(1, :) = firings(1, :) - t_min * 1000;
    firings_pre = firings;
    
    t_min = T_learning + T_noise; t_max = T_learning + 2*T_noise;
    idx = (data.firings(1, :) > t_min * 1000) & (data.firings(1, :) < t_max * 1000);
    firings = data.firings(:, idx);
    firings(1, :) = firings(1, :) - t_min * 1000;
    firings_post = firings;
    
    meta.N = N;
    meta.T_noise = T_noise;
    meta.T_learning = T_learning;
    meta.sigma_ex = net.sigma_ex;
    meta.sigma_inh = net.sigma_inh;
    
    save(fullfile(net.RecordingDirectory, "InitialWorkSpace.mat"), ...
         'firings_pre', 'firings_post', 'meta');
end