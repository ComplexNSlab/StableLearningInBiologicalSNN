%% Computing the order vectors :)

interval = 100; % ms 
off_set_time = 0;

check_flag_save = zeros(round(mynet.t/interval), mynet.N);

f = waitbar(0, "Computing First to Spike Orders ...");
trial_counter = 0;
time_keeper = 0;
for patch_num = 1:mynet.PatchNumber-1
    patch_address = mynet.RecordingDirectory + filesep + "Patch" + num2str(patch_num) + ".mat";
    pathParts = strsplit(patch_address, {'\', '/'});
    patch_address = fullfile(pathParts{:});

    variable_name = "data" + num2str(patch_num);
    s = load(patch_address);
    data = getfield(s, variable_name);
    net = getfield(s, 'obj');
    firings = transpose(data.firings);
    firings(:, 1) = firings(:, 1) - time_keeper;
    
    for trial_number = 1:round((net.t-time_keeper)/interval)
        % Computing the orders
        
        start_time = (firings(:, 1) > (trial_number-1) * interval + off_set_time);
        end_time = (firings(:, 1) <= trial_number * interval + off_set_time);
        indices = start_time & end_time;
        spike_times = firings(indices, 1);
        neuron_indices = firings(indices, 2);    
    
        order = TimeToFirstSpikeSort(spike_times, neuron_indices);
        trial_counter = trial_counter + 1;
        check_flag_save(trial_counter, :) = order;
  
        waitbar(patch_num/(mynet.PatchNumber-1), f, sprintf("Computing First to Spike Orders ... \n trial %d, patch %d/%d", trial_counter, patch_num, mynet.PatchNumber-1))
    end

    time_keeper = net.t;
end

close(f)