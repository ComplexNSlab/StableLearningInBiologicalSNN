%% Simulation Protocol 

nTrials = 1000; trialLen = 100;

% Initializing the Network properties
noise_window = 100; % in seconds
baseFolder = fullfile(pwd, 'Data', "N" + num2str(N), "nMems" + num2str(n_mems), "noise" + num2str(round(noise_strength*100))+ "%");
net = IzhikevichNetwork(N, 'heterogeneity', true, 'g_ee', 0.5, 'g_ei', 2, 'g_ie', 2, 'ExtoExDegree', 20, 'InhtoExDegree', 5, 'ExtoInhDegree', 5, 'baseFolder', baseFolder);

net.STDP = true;
net.noise = false;
net.sampling_rate = 5000;
net.sampling = false;
net.sigma_ex = noise_strength*5;
net.sigma_inh = noise_strength*2;

for i = 1:n_mems
    stim = Stimulation(net, trialLen, 2, 30, 50, 5);
    net.stimulation = true;
    net.stims = [stim];
    net.run(100000);

    net.stimulation = false;
    net.STDP = false;
    net.noise = true;
    net.run(noise_window*1000);
    net.STDP = true;
    net.noise = false;
end
save(fullfile(net.RecordingDirectory, "simInitialWorkSpace.mat"))