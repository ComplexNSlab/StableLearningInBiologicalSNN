%% *Configuring the network* 
clear 
clc

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
%mynet.noise = true;
%mynet.sigma_ex = 5;
%mynet.sigma_inh = 2;
mynet.stimulation = true;
mynet.sampling = true;
%mynet.AddHeterogeneity()

%% *Sequential Learning* 
% Feeding the stims to the network to learn (In series)
M_max = 2; % maximum number of memory to encode in the network
stims = []; 
interval = 100; %ms 
N_trials = 1000;

%f = waitbar(0, "Please Wait ...");
for m = 1:M_max
    stims = [stims, Stimulation(mynet, interval, 2, 30, 50, 0)];
    
 %   waitbar(m/M_max, f, sprintf("Memory %d/%d being encoded!", m, M_max))
    mynet.run(N_trials*interval, false);
    mynet.stims = []; % clear the stims list as it slows down the computaiton speed
end

%close(f)

%% Retrieval (At the end of Sequential Learning)
% Retrieval of memories by N_retreivals stimulations per stim (In series)
N_retrievals = 5; % number of retrieval per memory

mynet.STDP = false;
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
stims = zeros(2*M_max, 50); 
for patch_num = 1:2*M_max
    patch_address = mynet.RecordingDirectory + filesep + 'Patch' + num2str(patch_num);
    s = load(patch_address, 'obj'); 
    net = getfield(s, 'obj');
    stim = net.stims(1);
    stims(patch_num, :) = stim.pattern_indices; 
    waitbar(patch_num/(mynet.PatchNumber-1), f, sprintf("patch number %d/%d", patch_num, mynet.PatchNumber-1))
end
close(f)
%% Reading recorded data from patch files
data = mynet.getData();

%% Order of spikes analysis (In input mode!)
figure('Name', "Single Neuron Spike Order")
fsize = 15;
temp = check_flag_save(1:end, :);
temp(temp == 0) = nan;

%active_ex_cells = find(temp(end, :) ~= 0 & temp(end, :) <= mynet.Ne);
%active_inh_cells = find(temp(end, :) ~= 0 & temp(end, :) > mynet.Ne);

stable_order_ex = check_flag_save(end, 1:320);
stable_order_inh = check_flag_save(end, 321:end)-320;
stable_order_ex(stable_order_ex == 0) = 320;
stable_order_inh(stable_order_inh == -320) = 80;

colormap_ex = jet(320);
colormap_ex = colormap_ex(stable_order_ex, :);

colormap_inh = jet(80);
colormap_inh = colormap_inh(stable_order_inh, :);

hold on 
wsize = 1.5;
for cell_id =1:320
    
    plot(temp(1:end, cell_id), 'color', colormap_ex(cell_id, :), LineWidth= wsize)
end
for cell_id = 321:400
    
    plot(temp(1:end, cell_id), 'color', colormap_inh(cell_id-320, :), LineWidth= wsize)
end

xlabel("Trial")
ylabel("Single Neuron Spike Order")
title("First to Fire Order Vector")
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');
%% Raster plot in any time window (Poster Content)
patch_num = 1;
patch_address = mynet.RecordingDirectory + filesep + 'Patch' + num2str(patch_num);
variable_name = "data" + num2str(patch_num);
s = load(patch_address);
data = getfield(s, variable_name);

firings = data.firings;
clear s 

figure('Name', "Raster Plot", 'Renderer', 'painters', 'Position', [100 100 1000 1000]); 
ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
fsize = 20;
start_time =0; % in seconds
end_time = 5; % in seconds

%start_time = (patch_num-1)*100 + 99; % in seconds
%end_time = patch_num*100; % in seconds

ex_indices = ((firings(1, :)/1000 > start_time) & (firings(1, :)/1000 < end_time)) & (firings(2, :) <= 320);
inh_indices = ((firings(1, :)/1000 > start_time) & (firings(1, :)/1000 < end_time)) & (firings(2, :) > 320);

% stable_order = check_flag_save(1000, :);
% ex = stable_order(1:mynet.Ne) == 0;
% inh = stable_order(mynet.Ne+1:end) == 0;
% stable_order(logical([ex, zeros(1, mynet.Ni)])) = mynet.Ne-sum(ex)+1:mynet.Ne;
% stable_order(logical([zeros(1, mynet.Ne), inh])) = mynet.N - sum(inh)+1:mynet.N;
% 
% for i = 1:size(firings, 2)
%     firings(2, i) = stable_order(firings(2, i));
% end

plot(ax, firings(1, ex_indices)/1000, firings(2, ex_indices), 'b.', 'MarkerSize', 6)
hold on
plot(ax, firings(1, inh_indices)/1000, firings(2, inh_indices), 'r.', 'MarkerSize', 6)

xlabel("time (s)")
ylabel("neuron index")
% title("After Learning (Just Noise Phase)")

y_starts = [0.2, 0.685];
y_ends = [0.675, 0.8];
phases = ["Excitatory", "Inhibitory"];
for i = 1:length(phases)
    annotation('line',[0.81 0.81], [y_starts(i), y_ends(i)], 'Color', 'Black', 'LineWidth', 3, LineStyle='-'); % Stimulation
    annotation('textbox', [0.83,  y_starts(i)/2 + y_ends(i)/2 - 0.05, 0.1, 0.01], 'String', phases(i), 'FontName', 'Arial', 'FontSize', 15, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'EdgeColor', 'none', Rotation=90)
end

ylim([0, mynet.N])
yticks([1, 50:50:300, 321, 360,400])
yticklabels([1, 50:50:300, 1, 40,80])
xlim([start_time end_time])
set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold');

%% Engagement of Cells Analysis


%%%%%%%%%%%%%%%%%%%%%
figure('Name', 'Population Analysis')

subplot(3, 1, 1)
hold on
plot(100* ex_neurons_engagement_count(200000:1:end)/mynet.Ne)
%plot(100* ex_neurons_engagement_count(2:2:end)/mynet.Ne, DisplayName= 'memory 2')
%legend()

title("Excitatory Population Engagement")
xlabel('Trial')
ylabel('Engagement %')
%%%%%%%%%%%%%%%%%%%%%
subplot(3, 1, 2)
hold on
plot(100* inh_neurons_engagement_count(200000:1:end)/mynet.Ni)
%plot(100* inh_neurons_engagement_count(2:2:end)/mynet.Ni, DisplayName= 'memory 2')
%legend()

title("Inhibitory Population Engagement")
xlabel('Trial')
ylabel('Engagement %')

%%%%%%%%%%%%%%%%%%%%%

subplot(3, 1, 3)
hold on
plot(total_spike_count(200000:1:end))
%plot(total_spike_count(2:2:end), DisplayName= 'memory 2')
%legend()
title("Total Spike Count per Trial")
xlabel('Trial')
ylabel('Spike Count')
%%%%%%%%%%%%%%%%%%%%%



%% PCA on order vectors (For Sequential Learning)

% Perform PCA
[coeff, score, latent, tsquared, explained, mu] = pca(check_flag_save(:, 1:320));
% coeff    - Principal component coefficients (eigenvectors)
% score    - Principal component scores (projected data)
% latent   - Principal component variances (eigenvalues)
% tsquared - Hotelling's T-squared statistic for each observation
% explained- Percentage of total variance explained by each principal component
% mu       - Estimated mean of each variable

x = score(:, 1);
y = score(:, 2);
z = score(:, 3);

mem_colors = hsv(M_max);
colors = zeros(N_trials*M_max, 3);
for m = 1:M_max
    colors((m-1)*N_trials+1:m*N_trials, :) = [flip(gray(N_trials-1)); mem_colors(m, :)];
end

figure;
ax1 = axes;
ax2 = axes;
ax2.Position = ax1.Position; % Align the second axes with the first
ax2.Color = 'none'; % Make the background of the second axes transparent
linkprop([ax1, ax2], {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'});


for m = 1:M_max
    indices = m:M_max:M_max*N_trials;
    scatter3(x(indices), y(indices), z(indices),10, colors(indices, :), Marker="o", MarkerFaceColor="flat", HandleVisibility='off');
    hold on
end

hold on


indices = N_trials:N_trials:M_max*N_trials; % for in series mode

scatter3(ax2, x(indices), y(indices), z(indices), 200, colors(indices, :), Marker="o", MarkerFaceColor="flat", DisplayName= "Learnt M", HandleVisibility='on'); 

%%%%%%%%%%%%%%%%% Plotting retrieved sequences
temp = check_flag_save(M_max*N_trials+1:end, 1:320);
test_data_centered = bsxfun(@minus, temp, mu);
score = test_data_centered * coeff;
x = score(:, 1);
y = score(:, 2);
z = score(:, 3);

c = [];
for m = 1:M_max
    c = [c;repmat(mem_colors(m, :), N_retrievals, 1)];
end

scatter3(ax2, x, y, z, 150, c, marker="pentagram", MarkerFaceColor="flat", DisplayName='Retrieved M')


colormap(ax1, flipud(gray))
clim(ax1,[0 1000]);
cb1 = colorbar(ax1,'Position',[.05 .11 .0675 .810]);
ylabel(cb1, 'Trial Number');

colormap(ax2, mem_colors)
clim(ax2, [0 M_max]);
cb2 = colorbar(ax2,'Position',[.88 .11 .0675 .810]);
cb2.Ticks = 0.5:1:M_max-0.5;
cb2.TickLabels = 1:M_max ;
ylabel(cb2, 'Memories');

%%Then add colorbars and get everything lined up
set([ax1,ax2],'Position',[.17 .11 .685 .815]);


xlabel('PC 1');
ylabel('PC 2');
zlabel('PC 3')
title('Order Vector Evolution in PCA Space');
legend(Location='best')

%% Kmean Clustering (Sequential Learning)

% Perform PCA

[coeff, score, latent, tsquared, explained, mu] = pca(check_flag_save(end-2000+1:end, :));
X = score;
colors = hsv(M_max);
%colors = colors(randperm(M_max),:);

groupID = repelem(1:M_max,1,N_retrievals)';   % known group ID for each point

% plot raw retrieved memories
figure()
gscatter(X(:,1), X(:,2), groupID, colors, '.', 20, "filled")
xlabel('PC 1')
ylabel('PC 2')
title('Raw data')

% Clustering!
k = M_max;
opts = statset('Display','final');
[idx,C] = kmeans(X,k, "Replicates",100, 'Options',opts, Distance='sqeuclidean');

T = array2table(zeros(k,5),'VariableName',{'cluster','numGroups', 'dominantGroup','secondGroup', 'clusteredpoints'}); 
for i = 1:k
    counts = histcounts(groupID(idx==i),'BinMethod','integers','BinLimits',[1,k]);
    [counts_new,groupIds] = sort(counts, 'descend');
    T.cluster(i) = i; 
    T.clusteredpoints(i) = sum(counts_new);
    if counts_new(1) ~= 0
        T.dominantGroup(i) = groupIds(1);
    else
        T.dominantGroup(i) = none;
    end
    T.numGroups(i) = length(nonzeros(counts_new));
    if counts_new(2) ~= 0 
        T.secondGroup(i) = groupIds(2);
    else
        T.secondGroup(i) = -1;
    end
end
disp(T)

temp = zeros(1, M_max*N_retrievals);
for i = 1:M_max
    temp(idx == i) = T.dominantGroup(i);
end

% Plot clusters
figure(); hold on;
gscatter(X(:,1), X(:,2), idx, colors, '.', 20, "filled")
xlabel('PC 1')
ylabel('PC 2')
title('Clustered data')


% Plot cluster Id vs. group Id
figure(); hold on;
plot(idx-0.5, Marker='o', MarkerFaceColor='k', MarkerSize=5, LineStyle='none', Color='k', LineWidth=0.05)

for i = 1:M_max
    area([0.5, N_retrievals+0.5]+N_retrievals*(i-1), [M_max, M_max], FaceColor = colors(i, :),FaceAlpha=0.2)
    yline(i-0.5, LineStyle='--', Alpha=0.1)
end
xlabel('Known Group ID')
ylabel('Cluster ID')
xticks((1:M_max)*N_retrievals - N_retrievals/2)
xticklabels(1:M_max)
xlim([0 N_retrievals*M_max])
yticks((1:M_max)-0.5)
yticklabels(1:M_max)
title('Kmean Clustering of Retrieved Memories(Sequential Learning)')

figure();
plot(groupID, temp, 'ko-')
xlabel('known group ID')
ylabel('Sorted Cluster ID')
title('Kmean Clustering of Retrieved Memories(Sequential Learning)')
%% Kmean Clustering (Alternating Learning)

% Perform PCA
num_trials = 800;

dat = check_flag_save(end-num_trials*M_max+1:end, :);
test_data_centered = bsxfun(@minus, dat, mu);
score = test_data_centered * coeff;

X = score;
colors = hsv(M_max);
%colors = colors(randperm(M_max),:);

groupID = repmat(1:M_max,1,num_trials)';   % known group ID for each point

% plot raw retrieved memories
figure()
gscatter(X(:,1), X(:,2), groupID, colors, '.', 20, "filled")
xlabel('PC 1')
ylabel('PC 2')
title('Raw data')

% Clustering!
k = M_max;
opts = statset('Display','final');
[idx,C] = kmeans(X,k, "Replicates",100, 'Options',opts, Distance='sqeuclidean');

T = array2table(zeros(k,5),'VariableName',{'cluster','numGroups', 'dominantGroup','secondGroup', 'clusteredpoints'}); 
for i = 1:k
    counts = histcounts(groupID(idx==i),'BinMethod','integers','BinLimits',[1,k]);
    [counts_new,groupIds] = sort(counts, 'descend');
    T.cluster(i) = i; 
    T.clusteredpoints(i) = sum(counts_new);
    if counts_new(1) ~= 0
        T.dominantGroup(i) = groupIds(1);
    else
        T.dominantGroup(i) = none;
    end
    T.numGroups(i) = length(nonzeros(counts_new));
    if counts_new(2) ~= 0 
        T.secondGroup(i) = groupIds(2);
    else
        T.secondGroup(i) = -1;
    end
end
disp(T)

temp = zeros(1, M_max*num_trials);
for i = 1:M_max
    temp(idx == i) = T.dominantGroup(i);
end

% Plot clusters
figure(); hold on;
gscatter(X(:,1), X(:,2), temp, colors, '.', 20, "filled")
xlabel('PC 1')
ylabel('PC 2')
title('Clustered data')

%%
% Plot cluster Id vs. group Id
figure(); hold on;

temp2 = zeros(1, length(groupID));
for i = 1:M_max
    temp2(i:M_max:end) = (i-1)*num_trials+1:i*num_trials;
end
plot(temp2, idx-0.5, Marker='o', MarkerFaceColor='k', MarkerSize=5, LineStyle='none', Color='k', LineWidth=0.05)


for i = 1:M_max
    area([0.5, num_trials+0.5]+num_trials*(i-1), [M_max, M_max], FaceColor = colors(i, :),FaceAlpha=0.2)
    yline(i-0.5, LineStyle='--', Alpha=0.1)
end
xlabel('Known Group ID')
ylabel('Cluster ID')
xticks((1:M_max)*num_trials  - num_trials/2)
xticklabels(1:M_max)
xlim([0 num_trials*M_max])
yticks((1:M_max)-0.5)
yticklabels(1:M_max)
title('Kmean Clustering of Retrieved Memories(Alternating Learning)')

figure();
plot(groupID, temp, 'ko-')
xlabel('known group ID')
ylabel('Sorted Cluster ID')
title('Kmean Clustering of Retrieved Memories(Alternating Learning)')
%% Memory sequence Vs. Learning Trial Sequence
memnum = 1;
trial_num = 1000;

figure;

x = check_flag_save2(N_trials*memnum, 1:mynet.N); y = check_flag_save2(N_trials*memnum-N_trials+trial_num, 1:mynet.N);
plot(x, y, 'ko'); axis equal;
hold on 
stim_cells = stims(memnum, :);
plot(x(stim_cells), y(stim_cells), Marker='o', LineStyle='none', MarkerFaceColor='r')

plot([0 mynet.N], [0 mynet.N],'k--')
xlabel("Learnt Order Vector")
ylabel(sprintf("Trial %d Order Vector", trial_num))
title(sprintf("Learnt memory %d Vs shaping memory in trial %d", memnum, trial_num))
xlim([0 mynet.N])
ylim([0 mynet.N])

%% Memory sequence VS. Retrival Sequence
memnum = 2;
retnum = 2;

indx = check_flag_save2(N_trials*memnum, 1:mynet.N) >= 0 & check_flag_save2(M_max*N_trials+(retnum-1)*N_retrievals+1, 1:mynet.N) >= 0;
x = check_flag_save2(N_trials*memnum, indx); y = check_flag_save2(M_max*N_trials+(retnum-1)*N_retrievals+1, indx);

figure;hold on; plot(x, y, 'ko'); axis equal;
stim_cells = stims(memnum, :);
plot(x(stim_cells), y(stim_cells), Marker='o', LineStyle='none', MarkerFaceColor='r')

plot([0 mynet.N], [0 mynet.N],'k--')
xlabel("Learnt Order Vector")
ylabel("Retrieved Order Vector")
title(sprintf("Learnt memory %d Vs Retrieved memory %d", memnum, retnum))
xlim([0 mynet.N])
ylim([0 mynet.N])

%% Computing Spearman Correlation between Retrievals and final Learnt memories
%sim_mat = zeros(1000, 5000);
corr_mat = zeros(1000, 5000);
f = waitbar(0, "Please Wait ...");
for memnum = 1:1000
    waitbar(memnum/1000, f, "Please Wait ...")
    for retnum = 1:5000
        stim_cells = stims(memnum, :);
        non_stimulated_cells = true(1, 400);
        %non_stimulated_cells(stim_cells) = 0;

        indx = check_flag_save2(1000*memnum, 1:400) ~= 0 & check_flag_save2(M_max*1000+retnum, 1:400) ~= 0 & non_stimulated_cells;
        x = check_flag_save2(1000*memnum, indx); y = check_flag_save2(M_max*1000+retnum, indx);
    
        %corrmat = cov(x + y, x - y);
        %similarity = corrmat(1, 1)/(corrmat(2, 2)+corrmat(1,1));
        
        %sim_mat(memnum, retnum) = similarity;
        corr_mat(memnum, retnum) = corr(x', y', "type", 'Spearman');
    end
end
close(f)
%% Computing Spearman Correlation between Retrievals and Retrievals
corr_mat = zeros(5000, 5000);
f = waitbar(0, "Please Wait ...");
for retnum1 = 1:5000
    waitbar(retnum1/5000, f, sprintf("Retrieval %d", retnum1))
    for retnum2 = retnum1:5000
        %stim_cells = stims(retnum1, :);
        %non_stimulated_cells = true(1, 400);
        %non_stimulated_cells(stim_cells) = 0;

        indx = check_flag_save2(M_max*N_trials+retnum1, 1:400) ~= 0 & check_flag_save2(M_max*N_trials+retnum2, 1:400) ~= 0;
        x = check_flag_save2(M_max*N_trials+retnum1, indx); y = check_flag_save2(M_max*N_trials+retnum2, indx);
        
        corr_mat(retnum1, retnum2) = corr(x', y', "type", 'Spearman');
        corr_mat(retnum2, retnum1) = corr(x', y', "type", 'Spearman');

    end
end
close(f)
%%
figure;
imagesc(corr_mat')
cb = colorbar;
cb.Label.String = "Spearman Correlation";


title("Spearman without zeros in order vector")
xlabel("Learnt order")
ylabel("Retrieved Order")
set(gca, 'ydir', 'normal')

xlim([0.5 20.5])
ylim([0.5 100.5]) 

%%
memnum = 500;
figure; plot(repelem(1:5000, 1), corr_mat(memnum, :), 'k*')
xlabel("Retrival Number")
title(sprintf("Corr of Memory %d with retrievals", memnum))
ylabel("Spearman Correlation")
ylim([0 1])
set(gca, 'fontsize', 15)

%%
submat = corr_mat;

y1 = zeros(5, 1000);
y1_err = zeros(1, 1000);
y2 = zeros(4995, 1000);
y2_CI95 = zeros(1, 1000);
y2_CI5 = zeros(1, 1000);
for memnum = 1:1000
    idx = false(1, 5000);
    idx((memnum-1)*5 + (1:5)) = 1;
    y1(:, memnum) = submat(memnum, idx);
    y1_err(1, memnum) = std(submat(memnum, idx));

    y2(:, memnum) = submat(memnum, ~idx); 
    y2_CI95(1, memnum) = quantile(submat(memnum, ~idx), 0.995);
    y2_CI5(1, memnum) = quantile(submat(memnum, ~idx)', 0.005);
end

figure;hold on;

plot(y2', 'r.')
%plot(y1', 'ko', MarkerFaceColor=0.7*[1 1 1])
errorbar(mean(y1, 1), y1_err, LineStyle='none', Marker='o', CapSize=5, MarkerFaceColor=[1 1 1], Color='k')
%plot(y1', Color='k', Marker='x', LineStyle='none')

%plot(y2_CI5, 'b')
%plot(y2_CI95, 'b')
%plot(mean(y2, 1), 'bo')
%errorbar(1:1000, mean(y2, 1), -y2_CI5+mean(y2, 1), y2_CI95-mean(y2, 1), LineStyle='none', Marker='o', CapSize=5, MarkerFaceColor=[1 1 1], Color='b')

%xlim([0 1000])
%ylim([0 1])
title("Correlation between retrievals and memories")
ylabel("Correlation")
xlabel("Memory number")
set(gca, 'fontsize', 15)
%set(gca, 'fontsize', 15, 'XScale', 'log', 'YScale', 'log')
%%
figure; hold on;
plot(corr_mat(1, 1:end), 'k.')

%% Checking repetitions of stimulation subsets between all stimulations

[x, y] = find(squareform(pdist(stims, 'euclidean'))==0);
figure; plot(x, y, 'k.');set(gca,'ydir', 'normal'); xlabel("Learning + Retrieval stims");ylabel("Learning + Retrieval stims")
title("Similarity of Stimulations")