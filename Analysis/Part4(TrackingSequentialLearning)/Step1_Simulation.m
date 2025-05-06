%% Tracking 21 Memories before and after Learning while learning 100 Memories in Total

% InstanciateIzhikevichNet;
% Initialize Network Properties
N = 800;
n_mems = 100;
n_trials = 1000;
baseFolder = fullfile("Data", "Scaled50", "N" + num2str(N));
net = IzhikevichNetwork(N, 'heterogeneity', true, 'g_ee', 0.5, 'g_ei', 2, ...
    'g_ie', 2, 'ExtoExDegree', 20, 'InhtoExDegree', 5, 'ExtoInhDegree', 5, 'baseFolder', baseFolder);

net.STDP = true;
net.stimulation = true;
net.sampling = false;
net.sampling_rate = 1000;
net.saveSimulation = false;

% Simulating to Learn N Memories Sequentially
stims = [];
for m = 1:n_mems
    stims = [stims, Stimulation(net, 100, 2, 30, 50, 5)];   
end
save(net.RecordingDirectory + filesep + "Stims.mat", "stims", '-mat');

f = waitbar(0, "Please wait ...");
f.Position(1:2) = [100, 100];

for m = 1:n_mems
    ttfs = zeros(N, 21, n_trials);
    for trial = 1:n_trials
        waitbar((m-1)/n_mems, f, sprintf("Learning memory %d/%d Trial %d/%d", m, n_mems, trial, n_trials));
        
        net.STDP = true;
        net.stims = stims(m);
        net.run(100);
                
        net.STDP = false;
        for mem = 40:60
            net.stims = stims(mem);
            net.run(100);

            for cell = unique(net.firings(:, 2))'
                index = find(net.firings(:, 2) == cell, 1);
                if ~isempty(index)
                    ttfs(cell, mem-39, trial) = net.firings(index, 1);
                end
            end
        end

    end
    save(net.RecordingDirectory + filesep + sprintf("ttfs_mem%d.mat", m), '-mat', "net", "ttfs");
end
close(f)


