%% *Configuring the network* 
clear 
clc

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
mynet.stimulation = true;
mynet.sampling = false;

%% *Sequential Learning* 
% Feeding the stims to the network to learn (In series)
M_max = 10; % maximum number of memory to encode in the network
interval = 100; %ms
N_trials = 1000;

for m = 1:M_max 
    Stimulation(mynet, interval, 2, 30, 50, 0);
    mynet.run(N_trials*interval, false);
    mynet.stims = []; % clear the stims list as it slows down the computaiton speed
end

%% Retrieval (At the end of Sequential Learning)
% Retrieval of memories by N_retreivals stimulations per stim (In series)
N_retrievals = 2000; % number of retrieval per memory

mynet.STDP = true;
f = waitbar(0, "Please Wait ...");
counter = 0;
for m = 1:M_max
    waitbar(counter/M_max, f, sprintf("Retrieval %d/%d", counter, M_max))
    patch_address = mynet.RecordingDirectory + filesep + 'Patch' + num2str(m);
    s = load(patch_address, 'obj'); 
    net = getfield(s, 'obj');
    stim = net.stims(1);
    stim.on = true;
    mynet.stims = [stim];
    mynet.run(interval*N_retrievals, false)
    mynet.stims = [];
    counter = counter + 1;
end
close(f)
mynet.STDP = true;
%% reading stimulations pattern indices from files
f = waitbar(0, "Please Wait ...");
stims = zeros(mynet.PatchNumber-1, 10); 
for patch_num = 1:mynet.PatchNumber-1
    patch_address = mynet.RecordingDirectory + filesep + 'Patch' + num2str(patch_num);
    s = load(patch_address, 'obj'); 
    net = getfield(s, 'obj');
    stim = net.stims(1);
    stims(patch_num, :) = stim.pattern_indices; 
    waitbar(patch_num/(mynet.PatchNumber-1), f, sprintf("patch number %d/%d", patch_num, mynet.PatchNumber-1))
end
close(f)
%% Computing order vectors from ComputeOrders.m script
ComputeOrders;
%% Computing Spearman Correlation between Retrievals and final Learnt memories

corr_mat1 = zeros(M_max, M_max*N_retrievals); cap1 = "All cells excluded 50"; % All cells excluded 50
corr_mat2 = zeros(M_max, M_max*N_retrievals); cap2 = "All cells included 50";% All cells included 50
corr_mat3 = zeros(M_max, M_max*N_retrievals); cap3 = "Excitatory cells included 50 ";% Excitatory cells included 50 
corr_mat4 = zeros(M_max, M_max*N_retrievals); cap4 = "Excitatory cells excluded 50 ";% Excitatory cells excluded 50 
corr_mat5 = zeros(M_max, M_max*N_retrievals); cap5 = "Inhibitory cells";% Inhibitory cells

f = waitbar(0, "Please Wait ...");
for memnum = 1:M_max
    waitbar(memnum/M_max, f, "Please Wait ...")
    for retnum = 1:M_max*N_retrievals
        stim_cells = stims(memnum, :);
        
        %%%%%%%%%%%%%%%%%%%%% All cells excluded 50
        non_stimulated_cells = true(1, mynet.N);
        non_stimulated_cells(stim_cells) = 0;

        indx = check_flag_save2(N_trials*memnum, 1:mynet.N) ~= 0 & check_flag_save2(M_max*N_trials+retnum, 1:mynet.N) ~= 0 & non_stimulated_cells;
        x = check_flag_save2(N_trials*memnum, indx); y = check_flag_save2(M_max*N_trials+retnum, indx);
    
        corr_mat1(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  All cells included 50

        indx = check_flag_save2(N_trials*memnum, 1:mynet.N) ~= 0 & check_flag_save2(M_max*N_trials+retnum, 1:mynet.N) ~= 0;
        x = check_flag_save2(N_trials*memnum, indx); y = check_flag_save2(M_max*N_trials+retnum, indx);
    
        corr_mat2(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  Excitatory cells included 50 

        indx = check_flag_save(N_trials*memnum, 1:mynet.Ne) ~= 0 & check_flag_save(M_max*N_trials+retnum, 1:mynet.Ne) ~= 0;
        x = check_flag_save(N_trials*memnum, [indx, false(1,mynet.Ni)]); y = check_flag_save(M_max*N_trials+retnum, [indx, false(1,mynet.Ni)]);
    
        corr_mat3(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  Excitatory cells excluded 50 
        non_stimulated_cells = true(1, mynet.Ne);
        non_stimulated_cells(stim_cells) = 0;

        indx = check_flag_save(N_trials*memnum, 1:mynet.Ne) ~= 0 & check_flag_save(M_max*N_trials+retnum, 1:mynet.Ne) ~= 0 & non_stimulated_cells;
        x = check_flag_save(N_trials*memnum, [indx, false(1,mynet.Ni)]); y = check_flag_save(M_max*N_trials+retnum, [indx, false(1,mynet.Ni)]);
    
        corr_mat4(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  Inhibitory cells 

        indx = check_flag_save(N_trials*memnum, mynet.Ne+1:end) ~= 0 & check_flag_save(M_max*N_trials+retnum, mynet.Ne+1:end) ~= 0;
        x = check_flag_save(N_trials*memnum, [false(1,mynet.Ne), indx]); y = check_flag_save(M_max*N_trials+retnum, [false(1,mynet.Ne), indx]);
    
        corr_mat5(memnum, retnum) = corr(x', y', "type", 'Spearman');
    end
end
close(f)

%% Saving generated data
save(mynet.RecordingDirectory + file_sep + "GeneratedData.mat", '-v7.3')
