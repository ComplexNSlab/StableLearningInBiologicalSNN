%% *Configuring the network* 
clear 
clc

mynet = IzhikevichNetwork(200);
mynet.STDP = true;
mynet.stimulation = true;
mynet.sampling = true;
mynet.sampling_rate = 5000;

%% Simulation
M_max = 3; % maximum number of memory to encode in the network
stims = []; 
interval = 100; %ms
N_trials = 2000;
noise_len = 100; %s

for m = 1:M_max
   if noise_len
       mynet.stimulation = false;
       mynet.noise = true;
       mynet.sigma_ex = 1.2*5;
       mynet.sigma_inh = 1.2*2;
       mynet.run(noise_len*1000);
       mynet.noise = false;
   end
    
   stims = [stims, Stimulation(mynet, interval, 2, 30, 50, 5)];
    
   mynet.stimulation = true;
   mynet.run(N_trials*interval);
   mynet.stims = []; % clear the stims list as it slows down the computaiton speed 
end


randorder = randperm(M_max); % reLearn the memories in a new random order
randorder = 1:M_max; % reLearn the memories in a new random order

for m = randorder
    if noise_len
       mynet.stimulation = false;
       mynet.noise = true;
       mynet.sigma_ex = 0.7*5;
       mynet.sigma_inh = 0.7*2;
       mynet.run(noise_len*1000);
       mynet.noise = false;
    end
    
    mynet.stims = [stims(m)];
    
    mynet.stimulation = true;
    mynet.run(N_trials*interval);
    mynet.stims = []; % clear the stims list as it slows down the computaiton speed 
end

playNotificationSound;
%% Collecting data by reading from file
data = mynet.getData();
playNotificationSound;
%% Computing EigenValues/Vectors in time
[Vseq,Dseq] = eigenshuffle(abs(data.w(1:mynet.Ne, 1:mynet.Ne, :)));
%[Vseq1,Dseq1] = eigenshuffle(abs(data.w(:, :, :)));
playNotificationSound();
%% Imaginary Eigenvalues in time
Dseqs = Dseq;
time_points = (1:size(Dseqs, 2))*mynet.sampling_rate*mynet.dt/1000;
Lrn_len = N_trials*interval/1000; win_len = Lrn_len+noise_len;

[max_lambdas, order] = max(abs(imag(Dseqs)), [], 2); 
[dummy, index] = sort(max_lambdas, 'descend');
eig_indices = index(1:M_max*2);
order = order(index); order = order(1:2:M_max*2);
[~, order] = sort(order, "ascend"); order = order(order);

max_lambdas = max(abs(real(Dseqs)), [], 2); 
[dummy, index] = sort(max_lambdas, 'descend');
eig_indices2 = index(1:4);

colors = jet(M_max);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure; hold on;

for i=0:2*M_max-1
    area(noise_len + [i*win_len i*win_len+Lrn_len], [10 10], 'FaceColor', colors(mod(i, M_max)+1, :), 'FaceAlpha', 0.3, HandleVisibility='off')
    area(noise_len + [i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', colors(mod(i, M_max)+1, :), 'FaceAlpha', 0.3, DisplayName="Mem" + num2str(i+1))
    area([i*win_len i*win_len+noise_len], [-10 -10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
    area([i*win_len i*win_len+noise_len], [10 10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
end
i=M_max;
% area([i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
% area([i*win_len i*win_len+Lrn_len], [10 10], 'FaceColor', 'k', FaceAlpha=0.1, DisplayName="Noise")

plot(time_points,imag(Dseqs(:, :))', LineStyle="-", Color=[0 0 0 0.5], LineWidth=1, HandleVisibility='off')
plot(time_points,imag(Dseqs(eig_indices, :))', LineStyle="-", LineWidth=3, HandleVisibility='off')
colororder(repelem(colors(order, :), 2,1))
%plot(time_points,imag(Dseq(eig_indices2, :))', LineStyle="-", Color=[1 0 0 1], LineWidth=3)
xlabel("time (s)")
ylabel("Imag part Eigenvalue")

ylim([-15 15])
xlim([0 max(time_points)])
set(gca, 'FontName', 'Arial', 'FontSize', 25); 

lgd = legend(Location="best");

% Optional: Remove the box around the legend
lgd.Box = 'off';
lgd.FontSize = 20;
%% Real Eigenvalues in time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure; hold on;

for i=0:M_max-1
    area(noise_len + [i*win_len i*win_len+Lrn_len], [15 15], 'FaceColor', colors(i+1, :), 'FaceAlpha', 0.2, HandleVisibility='off')
    area(noise_len + [i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', colors(i+1, :), 'FaceAlpha', 0.2, DisplayName="Mem" + num2str(i+1))
    area([i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
    area([i*win_len i*win_len+Lrn_len], [15 15], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
end
i=M_max;
area([i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
area([i*win_len i*win_len+Lrn_len], [15 15], 'FaceColor', 'k', FaceAlpha=0.1,  DisplayName="Noise")

plot(time_points,real(Dseqs(:, :))', LineStyle="-", Color=[0 0 0 0.5], LineWidth=1, HandleVisibility='off')
plot(time_points,real(Dseqs(eig_indices, :))', LineStyle="-", LineWidth=3, HandleVisibility='off')
colororder(repelem(colors(order, :), 2,1))
%plot(time_points,real(Dseq(eig_indices2, :))', LineStyle="-", Color=[1 0 0 1], LineWidth=3)
xlabel("time (s)")
ylabel("Real part Eigenvalue")

ylim([-10 15])
xlim([0 max(time_points)])
set(gca, 'FontName', 'Arial', 'FontSize', 25); 

lgd = legend(Location="northeast");

% Optional: Remove the box around the legend
lgd.Box = 'off';
lgd.FontSize = 20;

%% PCA for eigenvalues or weigths in time
% Selecting nonzero weights
w = data.w(1:320, 1:320, :);
[rows, cols] = find(w(:, :, 1) ~= 0);
temp = zeros(length(rows), size(w, 3));
for i = 1:length(rows)
    temp(i, :) = w(rows(i), cols(i), :);
end
w = temp(1:end, :);
w(isnan(w)) = 0;

% Perform PCA
t_filter = [200, 400, 600];
[coeff, score, latent, tsquared, explained, mu] = pca(w(:, :)');

figure;
c = zeros(size(score, 1), 3);
known_colormaps = ["spring", "summer", "autumn", "winter", "bone", "cool", "hot", ...
        "hsv", "jet", "parula", "pink", "sky", "turbo"];

c = [];
for m = 1:M_max
    colorfunc = str2func(known_colormaps(m));
    c = [c; 0.5*ones(2*noise_len, 3); colorfunc(2*Lrn_len)];
end
for m = randorder
    colorfunc = str2func(known_colormaps(m));
    c = [c; 0.5*ones(2*noise_len, 3); colorfunc(2*Lrn_len)];
end

scatter3(score(:, 1), score(:, 2), score(:, 3), 10, c, 'filled')
colormap(jet)
cb = colorbar;
cb.Label.String = "Time (s)";
clim([0 Lrn_len]);

xlabel("PC1")
ylabel("PC2")
zlabel("PC3")
title("Weights Vector")
%% PCA for Sequential learning separately 
pc_vectors = zeros(size(w, 1), 3,2*M_max);

for m = 1:2*M_max
    t_filter = (m-1)*win_len + noise_len + (1:Lrn_len);
    [coeff, score, latent, tsquared, explained, mu] = pca(w(:, t_filter)');
    pc_vectors(:, :, m) = coeff(:, 1:3);
end

known_colormaps = ["" + ...
    "spring", "summer", "autumn", "winter", "bone", "cool", "hot", ...
        "hsv", "jet", "parula", "pink", "sky", "turbo"];

c = [];
for m = 1:M_max
    colorfunc = str2func(known_colormaps(m));
    c = [c; 0.5*ones(2*noise_len, 3); colorfunc(2*Lrn_len)];
end

for m = 1:M_max
    % now project data points into one of the memories PC space 
    projection = pc_vectors(:, :, m)'*w;
    
    
    f = figure;
    scatter(projection(1, :), projection(2, :), 10, c)
    xlabel("PC1")
    ylabel("PC2")
    zlabel("PC3")
    title(sprintf("W trajectory in PC space of memory %d", m))
    %saveas(f, "M" + num2str(m) + ".png")
    %close(f)
end

c = [];
for m = 1:M_max
    colorfunc = str2func(known_colormaps(m));
    c = [c; 0.5*ones(2*noise_len, 3); colorfunc(2*Lrn_len)];
end

for m = 1:M_max
    % now project data points into one of the memories PC space 
    projection = pc_vectors(:, :, M_max + m)'*w;
    
    
    f = figure;
    scatter(projection(1, :), projection(2, :), 10, c)
    xlabel("PC1")
    ylabel("PC2")
    zlabel("PC3")
    title(sprintf("W trajectory in PC space of memory %d", randorder(m)))
    %saveas(f, "M" + num2str(m) + ".png")
    %close(f)
end
%%
dist_mat = squareform(pdist(squeeze(pc_vectors(:, :, :))', "cosine"));
figure; 
imagesc(dist_mat)

colorbar

set(gca, 'ydir', 'normal')

%% Biplot of principal components
figure;
n1 =1 ; n2 = 2 ; 
biplot(coeff(:,[n1 n2]), 'Scores', score(:,[n1 n2]), 'VarLabels', string((1:size(score,2)')));
xlabel("PC " + num2str(n1) +"(" + num2str(explained(n1)) + "%)");
ylabel("PC " + num2str(n2) +"(" + num2str(explained(n2)) + "%)");
title('Biplot of Principal Components');
%% Color coded Eigvalues in time
figure; hold on;
c = hot(size(Dseqs, 1));
selected_time = round(2400/(mynet.sampling_rate*mynet.dt)*1000);
[~, indices] = sort((imag(Dseqs(:, selected_time))), 'ascend');
temp = 1:size(Dseqs, 1); indices(indices) = temp;
c = c(indices, :);
for i = 1:size(Dseqs, 1)
    plot(time_points, imag(Dseqs(i, :)), color = c(i, :))
end
xlabel("time (s)")
ylabel("Imaginary EigenValues")
%% Eigenvalues Distance Matrix
distances = pdist(imag(Dseqs)', 'euclidean');
squared_distances = squareform(distances);

imagesc(squared_distances)
cb = colorbar;
cb.Label.String = "Distance";
colormap(parula)

L = size(squared_distances,1);
steps = 300;
xticks(1:steps:L+1)
xticklabels((0:steps:L+1)*mynet.sampling_rate*mynet.dt/1000)
yticks(1:steps:L+1)
yticklabels((0:steps:L+1)*mynet.sampling_rate*mynet.dt/1000)

%xticks(time_points(1:steps:end))
xlabel("time (s)")
ylabel("time (s)")
title("Eigenvalues Distance Matrix")
set(gca, 'YDir', 'normal', 'Fontsize', 15,'FontWeight', 'bold');
%xticklabels(time_points)
%% Visualizing weights in time 
time_points = (1:size(w, 2))*mynet.sampling_rate*mynet.dt/1000;

% Coloring them based on a selected time point
c = hsv(size(w, 1));
selected_time = round(600/(mynet.sampling_rate*mynet.dt)*1000);
[sorted_seq, indices] = sort(w(:, selected_time), 'ascend');
temp = 1:size(w, 1); indices(indices) = temp;
c = c(indices, :);

% plotting each w_ij
figure; hold on;
for i = 1:size(w, 1)
    plot(time_points, w(i, :), color = c(i, :))
end

xlabel("time (s)")
ylabel("Weights")
title("Weigths (t)")
set(gca, 'Fontsize', 15,'FontWeight', 'bold');
%% Weights Distance Matrix
distance_type = "cosine";

distances = pdist(w(:, :)', distance_type);
squared_distances = squareform(distances);
playNotificationSound;

t1_filter = [];     
t2_filter = [];
for m = 1:2*M_max
    t1_filter = [t1_filter, (m-1)*2*win_len + 2*noise_len + (1:2*Lrn_len)];
    t2_filter = [t2_filter, (m-1)*2*win_len + (1:2*noise_len)];
end
%%

screenSize = get(0, 'ScreenSize');
%figure('Position', [screenSize(3)/4 screenSize(4)/4 screenSize(4)*0.5 screenSize(4)*0.5]);
figure;
imagesc(squared_distances(:, :))
%axis equal
%set(gca, 'DataAspectRatio', [1 1 1]); % Sets the data aspect ratio to be equal
cb = colorbar;
cb.Label.String = distance_type + " Distance";
colormap(parula)

L = size(squared_distances,1);
steps = 400;
xticks(1:steps:L+1)
xticklabels((0:steps:L+1)*mynet.sampling_rate*mynet.dt/1000)
yticks(1:steps:L+1)
yticklabels((0:steps:L+1)*mynet.sampling_rate*mynet.dt/1000)

title("Weights Distance Matrix")
xlabel("time (s)")
ylabel("time (s)")
set(gca, 'Ydir', 'Normal','Fontsize', 15,'FontWeight', 'bold');
%set(gca, 'LooseInset', get(gca, 'TightInset'));
%% Robust Vs non Robust Weigths in Learning
thrld1 = 0.05;thrld2 = 0.6;
% Coloring them based on a selected time point
c = hsv(size(w, 1));
selected_time = round(800/(mynet.sampling_rate*mynet.dt)*1000);
[sorted_seq, indices] = sort(w(:, selected_time), 'ascend');
temp = 1:size(w, 1); indices(indices) = temp;
c = c(indices, :);

% finding the robust weights 
t1 = 200; t1 = round(t1/(mynet.sampling_rate*mynet.dt)*1000);
t2 = 400; t2 = round(t2/(mynet.sampling_rate*mynet.dt)*1000);
t3 = 600; t3 = round(t3/(mynet.sampling_rate*mynet.dt)*1000);
t4 = 800; t4 = round(t4/(mynet.sampling_rate*mynet.dt)*1000);
%t5 = 2000; t5 = round(t5/(mynet.sampling_rate*mynet.dt)*1000);

diff_w1 = abs(w(:, t1) - w(:, t2));
diff_w2 = abs(w(:, t1) - w(:, t3));
diff_w3 = abs(w(:, t1) - w(:, t4));
%diff_w4 = abs(w(:, t1) - w(:, t5));
not_changed1 = diff_w1 < thrld1;
not_changed2 = diff_w2 < thrld1;
not_changed3 = diff_w3 < thrld1;
%not_changed4 = diff_w4 < 0.1;
changed1 = diff_w1 > thrld2;
changed2 = diff_w2 > thrld2;
changed3 = diff_w3 > thrld2;

% plotting not changed w_ij
figure; hold on
counter = 0;

for i = 1:size(w, 1)
    if not_changed1(i) && not_changed2(i) && not_changed3(i) 
        plot(time_points, w(i, :), color = c(i, :))
        counter = counter + 1;
    end
end
counter

xlabel("time (s)")
ylabel("Robust Weigths")
title("Robust Weigths in Learning")
set(gca, 'FontSize', 15)

% plotting changed w_ij
figure; hold on
counter = 0;

for i = 1:size(w, 1)
    if changed1(i) || changed2(i) || changed3(i) 
        plot(time_points, w(i, :), color = c(i, :))
        counter = counter + 1;
    end
end
counter

xlabel("time (s)")
ylabel("Non Robust Weigths")
title("Non robust Weigths in Learning")
set(gca, 'FontSize', 15)
%% Computing angles between two eigvectors in all times
i = 2; j = 3;
angles = zeros(size(Vseq,3), size(Vseq, 3));

f = waitbar(0, "Wait ...");

for t1 = 1:size(angles,1)
    angles(t1, t1:size(angles, 1)) = complexdot(Vseq(:, i, t1)', squeeze(Vseq(:, j, t1:size(angles, 1)))');
    waitbar((t1-1)/size(angles, 1), f, sprintf("t = %d", t1))
end

close(f)
% distances = pdist(squeeze(Vseq(:, 1, :))', @complexdot);
playNotificationSound;
%% Computing in another way 
i = 26; j = 189;
angles = pdist2(squeeze(Vseq(:, i, :))', squeeze(Vseq(:, j, :))', @complexdot);
playNotificationSound;

%% Visualizing previous part result
submat = squeeze(angles);
upperTri = triu(submat);
%submat = submat + upperTri' - diag(diag(submat));
submat = 1-submat;
submat(submat>1) = 1;
submat = acos(submat)*180/pi;
submat(submat > 90) = 180 - submat(submat>90);

figure;
imagesc(submat)
cb = colorbar;
cb.Label.String = "Degree";
clim([0 90])
cb.Ticks = [0:15:90];
colormap hot

steps = 300;
indices = [0 steps:steps:size(angles,1)];

xticks(indices)
xticklabels(indices*mynet.sampling_rate*mynet.dt/1000)
yticks(indices)
yticklabels(indices*mynet.sampling_rate*mynet.dt/1000)

xlabel("time (s)")
ylabel("time (s)")
title(sprintf("EigVecs (V%d.V%d) Angle", i, j))
set(gca, 'Ydir', 'normal', 'FontSize', 15)
%% Finding the highest index of eigenvalue in time
n = 1;
highest_index = zeros(n, size(Dseqs, 2));
for i = 1:size(Dseqs, 2)
     [~, ord] = sort(imag(Dseqs(:, i)), 'ascend'); 
     highest_index(:, i) =  ord(1:n) + (0:n-1)'*320;
end
figure;
plot((1:size(highest_index, 2))*mynet.dt/mynet.sampling_rate*1000, highest_index')
xlabel("Time")
ylabel("Index")
set(gca, 'FontSize', 15)
%% Analyzing A (low pass filters) in time!
time_points = (1:size(data.A, 2))*mynet.sampling_rate*mynet.dt/1000;

% Coloring them based on a selected time point
c = hsv(size(data.A, 1));
selected_time = round(100/(mynet.sampling_rate*mynet.dt)*1000);
[sorted_seq, indices] = sort(data.A(:, selected_time), 'ascend');
temp = 1:size(data.A, 1); indices(indices) = temp;
c = c(indices, :);

figure; hold on;
for i = 1:size(data.A, 1)
    plot(time_points, data.A(i, :), color = c(i, :))
end

xlabel("time (s)")
ylabel("A (1/s)")
title("A (low pass fiter) Vs. Time")

set(gca, 'FontSize', 15)
%% A distance matrix

distance_type = "cosine";

distances = pdist(data.A(:, 800:800:end)', distance_type);
squared_distances = squareform(distances);
playNotificationSound;

t1_filter = [];
t2_filter = [];
for m = 1:2*M_max
    t1_filter = [t1_filter, (m-1)*2*win_len + 2*noise_len + (1:2*Lrn_len)];
    t2_filter = [t2_filter, (m-1)*2*win_len + (1:2*noise_len)];
end

screenSize = get(0, 'ScreenSize');

figure;
imagesc(squared_distances(:, :))

cb = colorbar;
cb.Label.String = distance_type + " Distance";
colormap(parula)

L = size(squared_distances,1);
steps = 400;
xticks(1:steps:L+1)
xticklabels((0:steps:L+1)*mynet.sampling_rate*mynet.dt/1000)
yticks(1:steps:L+1)
yticklabels((0:steps:L+1)*mynet.sampling_rate*mynet.dt/1000)

title("A (low pass) Distance Matrix")
xlabel("time (s)")
ylabel("time (s)")
set(gca, 'Ydir', 'Normal','Fontsize', 15);
%% PCA for A vector in time!
% Perform PCA
[coeff, score, latent, tsquared, explained, mu] = pca(data.A(:, :)');

figure;
c = zeros(size(score, 1), 3);
for m = 1:M_max
    if noise_len
        c(win_len*(m-1) + (1:noise_len),:) = copper(noise_len);
    end
    c(win_len*(m-1) + noise_len + (1:Lrn_len),:) = jet(Lrn_len);
end

scatter3(score(:, 1), score(:, 2), score(:, 3), 10, c, 'filled')
%scatter3(score(:, 1), score(:, 2), score(:, 3), 10, jet(size(score, 1)))
colormap(jet)
cb = colorbar;
cb.Label.String = "Time (s)";
clim([0 Lrn_len]);

xlabel("PC1")
ylabel("PC2")
zlabel("PC3")
title("A (low pass) Vector")
%% Spike Orders
time_points = (1:size(check_flag_save, 1))*interval/1000;

selected_time = round(200/(interval)*1000);
stable_order_ex = check_flag_save(selected_time, 1:320);
stable_order_inh = check_flag_save(selected_time, 321:end)-320;
stable_order_ex(stable_order_ex == 0) = mynet.Ne-sum(stable_order_ex == 0)+1:mynet.Ne;
stable_order_inh(stable_order_inh == -320) = mynet.Ni-sum(stable_order_inh == -320)+1:mynet.Ni;

colormap_ex = jet(mynet.Ne);
colormap_ex = colormap_ex(stable_order_ex, :);
colormap_inh = jet(mynet.Ni);
colormap_inh = colormap_inh(stable_order_inh, :);

figure; hold on;
for i = 1 :mynet.Ne
    plot(time_points, check_flag_save(:, i), Color=colormap_ex(i, :))
end

xlim([0 time_points(end)])
ylim([0 mynet.Ne])
xlabel("Time (s)")
ylabel("Spike Order Vector")
%% PCA for Spike order vector in time 
% Perform PCA
[coeff, score, latent, tsquared, explained, mu] = pca(check_flag_save(:, :));

figure;

known_colormaps = ["spring", "summer", "autumn", "winter", "bone", "cool", "hot", ...
        "hsv", "jet", "parula", "pink", "sky", "turbo"];

c = [];
for m = 1:M_max
    colorfunc = str2func(known_colormaps(m));
    c = [c; 0.5*ones(10*noise_len, 3); colorfunc(10*Lrn_len)];
end

for m = 1:M_max
    colorfunc = str2func(known_colormaps(M_max + randorder(m)));
    c = [c; 0.5*ones(10*noise_len, 3); colorfunc(10*Lrn_len)];
end
%%
c = [];
colorfunc = str2func(known_colormaps(2));
c = [c; colorfunc(10*200)];
for i = 1:500
    c = [c; 0.5*ones(10*1, 3); ((1000-i)/1000)*[1 0 0]];
end

scatter3(score(:, 1), score(:, 2), score(:, 3), 20, c, 'filled')
%scatter3(score(:, 1), score(:, 2), score(:, 3), 10, jet(size(score, 1)))
colormap(jet)
cb = colorbar;
cb.Label.String = "Time (s)";
clim([0 Lrn_len]);

xlabel("PC1")
ylabel("PC2")
zlabel("PC3")
title("Spike Order Vector in time")
%% Spike orders distance matrix
distance_type = "spearman";
mat = 1- squareform(pdist(check_flag_save([1:2000, 2011:11:7500], 1:320), distance_type));
figure;
imagesc(mat)

cb = colorbar;
cb.Label.String = distance_type + " Distance";
set(gca, 'ydir', 'normal', 'FontSize', 15)

title("Spike Order Vector Distance Matrix")
xlabel("time (s)")
ylabel("time (s)")

L = size(mat,1);
steps = 1000;
xticks(1:steps:L+1)
xticklabels((0:steps:L+1)*interval/1000)
yticks(1:steps:L+1)
yticklabels((0:steps:L+1)*interval/1000)

set(gca, 'Ydir', 'Normal','Fontsize', 15);


%% Function for Complex dot product
function D2 = complexdot(ZI, ZJ)
    % ZI is a 1-by-n vector containing a single observation.
    % ZJ is an m2-by-n matrix containing multiple observations. distfun must accept a matrix ZJ with an arbitrary number of observations.
    % D2 is an m2-by-1 vector of distances, and D2(k) is the distance between observations ZI and ZJ(k,:).

    % Calculate the dot product with conjugate
    [m2, ~] = size(ZJ);
    dot_product = sum(repmat(ZI, m2, 1) .* conj(ZJ), 2);
    
    % Calculate the norms
    norm_ZI = sqrt(sum(ZI .* conj(ZI)));
    norm_ZJ = sqrt(sum(ZJ.* conj(ZJ), 2));
    
    % Calculate the cosine of the angle
    cos_theta = real(dot_product) ./ (norm_ZI * norm_ZJ);
    
    % Return the cosine of the angle as the distance
    D2 = 1 - cos_theta; % 1 - cos(theta) to convert to a "distance"
end