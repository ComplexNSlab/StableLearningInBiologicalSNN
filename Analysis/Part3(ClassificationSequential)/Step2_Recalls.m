%% Parameters
N_retrievals = 100;
N_rands = 100;

%% Partial Memory Recall 

net.sampling = false;
net.STDP = false;
net.saveSimulation = false;

bar = waitbar(0, "Please wait...");
for alpha = 0.05:0.05:0.95
    
    ff_partial = nan(N_mems, N_retrievals, N);
    ff_partial_null = nan(N_rands, N);
    
    bar.Position(1:2) = [500, 500];
    
    % Memory Recalls
    for iter = 1:N_retrievals
        if mod(iter, 10) == 0
            waitbar(iter/(N_retrievals+N_rands), bar, sprintf("Alpha: %.2f\n Partial Recalling: %d/%d", alpha, iter, N_retrievals));
        end
        
        net.PatchNumber = 11;
        for m = 1:N_mems
            stim = stims(m).copy();
            stim.Ncells = ceil(alpha * stims(m).Ncells);
            sub_set = randperm(stims(m).Ncells, stim.Ncells);
            stim.pattern_indices = stim.pattern_indices(sub_set);
            stim.pattern_timings = mod(stim.pattern_timings(sub_set), 100);
            stim.interval = 100;
            stim.start_time = 10;
            stim.ConstructStimCurrent();
            
            net.stims = stim;
            net.run(100);
            
            f = net.firings';
            f(1, :) = mod(f(1, :), 100);
            ff_partial(m, iter, f(2, :)) = f(1, :);
        end
    end
    
    % Random Recalls
    for iter = 1:N_rands
        if mod(iter, 10) == 0
            waitbar((iter+N_retrievals)/(N_retrievals+N_rands), bar, sprintf("Alpha: %.2f\n Random Recall: %d/%d", alpha, iter, N_rands));
        end
        
        stim_rand = Stimulation(net, 100, 2, 30, ceil(alpha * stims(1).Ncells), 10);
        net.stims = stim_rand;
        net.run(100);
        
        f = net.firings';
        f(1, :) = mod(f(1, :), 100);
        ff_partial_null(iter, f(2, :)) = f(1, :);
    end

    f = reshape(ff_partial, [], N);

    trueLabels = repmat(1:N_mems, 1, N_retrievals)';
    trueLabels = [trueLabels; repmat(N_mems+1, size(ff_partial_null, 1), 1)];

    X_responseActivity = [f ; ff_partial_null]; 
    Y_memoryClass = trueLabels;

    % Define the path
    recallsPath = fullfile(net.RecordingDirectory, 'recallsResponses');
    
    % Create the directory if it doesn't exist
    if ~exist(recallsPath, 'dir')
        mkdir(recallsPath);
    end
    
    % Save the data
    save(fullfile(recallsPath, sprintf('alpha_%d.mat', round(100*alpha))), 'X_responseActivity', 'Y_memoryClass', '-mat');
end
close(bar); 