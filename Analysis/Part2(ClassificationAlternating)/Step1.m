%% Initialize Network Properties

baseFolder = fullfile("./Data", "N"+num2str(N) , num2str(N_mems) + "memories");
net = IzhikevichNetwork(N, 'heterogeneity', true, 'g_ee', 0.5, 'g_ei', 2, ...
    'g_ie', 2, 'ExtoExDegree', 20, 'InhtoExDegree', 5, 'ExtoInhDegree', 5, 'baseFolder', baseFolder);
net.STDP = true;
net.noise = false;
net.sampling_rate = 5000;
net.stimulation = true;
net.saveSimulation = false;

%% Simulating to Learn N Memories Sequentially
stims = [];
for i = 1:N_mems
    stims = [stims, Stimulation(net, 100 * N_mems, 2, 30, round(50*N/400), 5 + (i-1) * 100)];
end
for i = 1:N_mems
    net.run(100000);
    if i == N_mems-1
        net.saveSimulation = true;
    end
end


