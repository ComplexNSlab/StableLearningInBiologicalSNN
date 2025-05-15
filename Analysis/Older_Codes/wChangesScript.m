function w_filtered = wChangesScript()      
    %% Parameters to be set
    clear; 
    clc;
    
    % Network Architecture Parameters
    N = 400; 
    g_ee = 0.5; 
    g_ei = 2; 
    g_ie = 2; 
    heterogeneity = true; 
    ExtoExDegree = 20; 
    InhtoExDegree = 5; 
    ExtoInhDegree = 5;
    
    % Noise Parameters
    noise = false; 
    sigma_ex = 5; 
    sigma_inh = 2; % Fixed typo in variable name
    
    % Plasticity Mechanisms
    STDP = true; 
    scaling = false;
    sampling_rate = 10000; % steps; every 1 s
    %% Create an instance of IzhikevichNetwork with specified parameters
    mynet = IzhikevichNetwork( ...
        N, ...
        'g_ee', g_ee, ...
        'g_ei', g_ei, ...
        'g_ie', g_ie, ...
        'heterogeneity', heterogeneity, ...
        'ExtoExDegree', ExtoExDegree, ...
        'InhtoExDegree', InhtoExDegree, ...
        'ExtoInhDegree', ExtoInhDegree ...
    );
    
    % Set additional properties
    mynet.STDP = STDP;
    mynet.scaling = scaling;
    mynet.noise = noise;
    mynet.sigma_ex = sigma_ex;
    mynet.sigma_inh = sigma_inh; % Fixed typo in variable name
    mynet.sampling = true;
    mynet.sampling_rate = sampling_rate;

    clearvars -except mynet
    %% Running the simulations
    interval = 100; duration = 2; amplitude = 30; Ncells = 50;
    N_trials = 1000; Nmems = 20;
    mynet.stimulation = true;
    for memNum = 1:Nmems
        stim = Stimulation(mynet, interval, duration, amplitude, Ncells, 5);
        mynet.run(N_trials*interval, false);
        mynet.stims = [];
    end
    
    %% Getting w traces
    data = mynet.getData();
    w = data.w(1:320, 1:320, :);
    adjMat = mynet.Adjacency_matrix(1:320, 1:320, :);
    
    w_flat = reshape(w, [], size(w, 3));  % Flatten w into 2D matrix
    adj_flat = adjMat(:);  % Flatten adjMat into a column vector
    w_filtered = w_flat(adj_flat, :);  % Filter w using the adjacency matrix
    w_filtered(isnan(w_filtered)) = 0;
    clearvars -except w_filtered
end