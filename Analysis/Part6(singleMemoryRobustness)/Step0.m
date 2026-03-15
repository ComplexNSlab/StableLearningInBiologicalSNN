clear; clc;
N = 400; nTrials = 1500; trialLen = 100; scale50Flag = true;
%% Initializing the Network properties

if scale50Flag
    scaleFolder = "Scaled50";
else
    scaleFolder = "constant50";
end
baseFolder = fullfile(pwd, 'Data', scaleFolder, "N" + num2str(N));
net = IzhikevichNetwork(N, 'heterogeneity', true, 'g_ee', 0.5, 'g_ei', 2, 'g_ie', 2, 'ExtoExDegree', 20, 'InhtoExDegree', 5, 'ExtoInhDegree', 5, 'baseFolder', baseFolder);

net.STDP = true;
net.noise = false;

net.sampling_rate = 5000;
%% Simulating 

if scale50Flag
    N_stim = round(50*N/400);
else
    N_stim = 50;
end

stim = Stimulation(net, trialLen, 2, 30, N_stim, 5);
net.stimulation = true;

net.run(nTrials*trialLen);
stim = Stimulation(net, trialLen, 2, 30, N_stim, 5);

save(fullfile(net.RecordingDirectory, "config.mat"), 'net', 'stim')