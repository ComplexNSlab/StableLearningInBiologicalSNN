%% *Configuring the network* 
clear 
clc

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
mynet.stimulation = true;
mynet.sampling = true;
mynet.sampling_rate = 5000;
mynet.AddHeterogeneity;
%%
M_max = 1; % maximum number of memory to encode in the network
stims = []; 
interval = 100; %ms
N_trials = 2000;

for m = 1:M_max
    %mynet.noise = true;
    %mynet.run(200000, false);
    %mynet.noise = false;

    stims = [stims, Stimulation(mynet, interval, 2, 30, 50, 0)];
    mynet.run(N_trials*interval, false);
    mynet.stims = []; % clear the stims list as it slows down the computaiton speed
end
%%
mynet.noise = true;
mynet.sigma_ex = 0.5*5;
mynet.sigma_inh = 0.5*2;
mynet.run(100000, false);

%mynet.stims = [stims(1)];
%mynet.run(N_trials*interval, false);

%mynet.stims = [stims(2)];
%mynet.run(N_trials*interval, false);

%mynet.noise = true;
%mynet.run(200000, false);
%mynet.noise = false;
%%
data = mynet.getData();
%%
%[Vseq,Dseq] = eigenshuffle(abs(data.w(1:320, 1:320, :)));
[Vseq1,Dseq1] = eigenshuffle(abs(data.w(:, :, :)));
%% 
Dseqs = Dseq1;
time_points = (1:size(Dseqs, 2))*mynet.sampling_rate*mynet.dt/1000;
noise_len = 0; Lrn_len = N_trials*interval/1000; win_len = Lrn_len+noise_len;

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

for i=0:M_max-1
    area(noise_len + [i*win_len i*win_len+Lrn_len], [10 10], 'FaceColor', colors(i+1, :), 'FaceAlpha', 0.3, HandleVisibility='off')
    area(noise_len + [i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', colors(i+1, :), 'FaceAlpha', 0.3, DisplayName="Mem" + num2str(i+1))
    area([i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
    area([i*win_len i*win_len+Lrn_len], [10 10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
end
i=M_max;
area([i*win_len i*win_len+Lrn_len], [-10 -10], 'FaceColor', 'k', FaceAlpha=0.1, HandleVisibility='off')
area([i*win_len i*win_len+Lrn_len], [10 10], 'FaceColor', 'k', FaceAlpha=0.1, DisplayName="Noise")

plot(time_points,imag(Dseqs(:, :))', LineStyle="-", Color=[0 0 0 0.5], LineWidth=1, HandleVisibility='off')
plot(time_points,imag(Dseqs(eig_indices, :))', LineStyle="-", LineWidth=3, HandleVisibility='off')
colororder(repelem(colors(order, :), 2,1))
%plot(time_points,imag(Dseq(eig_indices2, :))', LineStyle="-", Color=[1 0 0 1], LineWidth=3)
xlabel("time (s)")
ylabel("Imag part Eigenvalue")

ylim([-15 15])
xlim([0 max(time_points)])
set(gca, 'FontName', 'Arial', 'FontSize', 25, 'FontWeight', 'bold'); 

lgd = legend(Location="best");

% Optional: Remove the box around the legend
lgd.Box = 'off';
lgd.FontSize = 20;
%%
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
set(gca, 'FontName', 'Arial', 'FontSize', 25, 'FontWeight', 'bold'); 

lgd = legend(Location="northeast");

% Optional: Remove the box around the legend
lgd.Box = 'off';
lgd.FontSize = 20;
%%
overlap_mat = zeros(M_max, M_max);
for i=1:M_max
    for j = 1:M_max
        overlap_mat(i, j) = length(intersect(stims(i).pattern_indices, stims(j).pattern_indices));
    end
end

overlap_mat
%%
% Perform PCA
[coeff, score, latent, tsquared, explained, mu] = pca(Dseqs(:, :)');

scatter3(score(:, 1), score(:, 2), score(:, 3), 10, repmat(jet(400), M_max, 1))
colormap(jet)
colorbar
%%
figure;
biplot(coeff(:,1:2), 'Scores', score(:,1:2), 'VarLabels', string((1:size(Dseqs,1)')));
xlabel("Principal Component 1 (" + num2str(explained(1)) + "%)");
ylabel("Principal Component 2 (" + num2str(explained(2)) + "%)");
title('Biplot of Principal Components');
%%
figure; hold on;
c = parula(400);
[sorted_seq, indices] = sort(abs(imag(Dseqs(:, end))), 'ascend');
temp = 1:400; indices(indices) = temp;
c = c(indices, :);
for i = 1:400
    plot(imag(Dseqs(i, :)), color = c(i, :))
end
%%

%%

distances = pdist(squeeze(Vseq1(:, 5, :))', @complexdot);
squareform_distances = squareform(distansces);
imagesc(squareform_distances)
colorbar
colormap(hot)

function D2 = complexdot(ZI, ZJ)
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