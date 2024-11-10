%% Checking repetitions of stimulation subsets between all stimulations

[x, y] = find(squareform(pdist(stims, 'euclidean'))==0);
figure; plot(x, y, 'k*');set(gca,'ydir', 'normal'); xlabel("Learning + Retrieval stims");ylabel("Learning + Retrieval stims")
title("Similarity of Stimulations")
%% Memory sequence Vs. Learning Trial Sequence
memnum = 2;
trial_num = 1000;

figure;

x = check_flag_save2(N_trials*memnum, 1:400); y = check_flag_save2(N_trials*(memnum-1) +trial_num, 1:400);
plot(x, y, 'ko'); axis equal;
hold on 
stim_cells = stims(memnum, :);
plot(x(stim_cells), y(stim_cells), Marker='o', LineStyle='none', MarkerFaceColor='r')

plot([0 400], [0 400],'k--')
xlabel(sprintf("Memory %d", memnum))
ylabel(sprintf("Trial %d", trial_num))
title(sprintf("Comparison of Order Vectors within Memory %d", memnum))
xlim([0 400])
ylim([0 400])
set(gca, 'fontsize', 15)
%% Memory sequence VS. Retrival Sequence
memnum = 1000;
retnum = 999;

indx = check_flag_save2(N_trials*memnum, 1:400) >= 0 & check_flag_save2(M_max*N_trials+(retnum-1)*N_retrievals+1, 1:400) >= 0;
x = check_flag_save2(N_trials*memnum, indx); y = check_flag_save2(M_max*N_trials+(retnum-1)*N_retrievals+1, indx);

figure;hold on; plot(x, y, 'ko'); axis equal;
stim_cells = stims(memnum, :);
plot(x(stim_cells), y(stim_cells), Marker='o', LineStyle='none', MarkerFaceColor='r')

plot([0 400], [0 400],'k--')
xlabel(sprintf("Memory %d", memnum))
ylabel(sprintf("Retrieval %d", retnum))
title(sprintf("Comparison of Order Vectors (Memory %d, Retrival %d)", memnum, retnum))
xlim([0 400])
ylim([0 400])
%% Retrieval sequence VS. Retrival Sequence
retnum1 = 1;
retnum2 = 5;

indx = check_flag_save2(M_max*N_trials+(retnum1-1)*N_retrievals+1, 1:400) >= 0 & check_flag_save2(M_max*N_trials+(retnum2-1)*N_retrievals+1, 1:400) >= 0;
x = check_flag_save2(M_max*N_trials+(retnum1-1)*N_retrievals+1, indx); y = check_flag_save2(M_max*N_trials+(retnum2-1)*N_retrievals+1, indx);

figure;hold on; plot(x, y, 'ko'); axis equal;
stim_cells1 = stims(retnum1, :);
stim_cells2 = stims(retnum2, :);
plot(x(stim_cells1), y(stim_cells1), Marker='o', LineStyle='none', MarkerFaceColor='r')
plot(x(stim_cells2), y(stim_cells2), Marker='o', LineStyle='none', MarkerFaceColor='b')

plot([0 400], [0 400],'k--')
xlabel(sprintf("Retrieval %d", retnum1))
ylabel(sprintf("Retrieval %d", retnum2))
title(sprintf("Comparison of Order Vectors (Retrieval %d, Retrival %d)", retnum1, retnum2))
xlim([0 400])
ylim([0 400])

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
        non_stimulated_cells = true(1, 400);
        non_stimulated_cells(stim_cells) = 0;

        indx = check_flag_save2(N_trials*memnum, 1:400) ~= 0 & check_flag_save2(M_max*N_trials+retnum, 1:400) ~= 0 & non_stimulated_cells;
        x = check_flag_save2(N_trials*memnum, indx); y = check_flag_save2(M_max*N_trials+retnum, indx);
    
        corr_mat1(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  All cells included 50

        indx = check_flag_save2(N_trials*memnum, 1:400) ~= 0 & check_flag_save2(M_max*N_trials+retnum, 1:400) ~= 0;
        x = check_flag_save2(N_trials*memnum, indx); y = check_flag_save2(M_max*N_trials+retnum, indx);
    
        corr_mat2(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  Excitatory cells included 50 

        indx = check_flag_save(N_trials*memnum, 1:320) ~= 0 & check_flag_save(M_max*N_trials+retnum, 1:320) ~= 0;
        x = check_flag_save(N_trials*memnum, [indx, false(1,80)]); y = check_flag_save(M_max*N_trials+retnum, [indx, false(1,80)]);
    
        corr_mat3(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  Excitatory cells excluded 50 
        non_stimulated_cells = true(1, 320);
        non_stimulated_cells(stim_cells) = 0;

        indx = check_flag_save(N_trials*memnum, 1:320) ~= 0 & check_flag_save(M_max*N_trials+retnum, 1:320) ~= 0 & non_stimulated_cells;
        x = check_flag_save(N_trials*memnum, [indx, false(1,80)]); y = check_flag_save(M_max*N_trials+retnum, [indx, false(1,80)]);
    
        corr_mat4(memnum, retnum) = corr(x', y', "type", 'Spearman');
        %%%%%%%%%%%%%%%%%%%%%  Inhibitory cells 

        indx = check_flag_save(N_trials*memnum, 321:end) ~= 0 & check_flag_save(M_max*N_trials+retnum, 321:end) ~= 0;
        x = check_flag_save(N_trials*memnum, [false(1,320), indx]); y = check_flag_save(M_max*N_trials+retnum, [false(1,320), indx]);
    
        corr_mat5(memnum, retnum) = corr(x', y', "type", 'Spearman');
    end
end
close(f)
%% Visualizing previous computation's results
for i = 1:5
    ScreenSize = get(0, 'ScreenSize');
    screenWidth = ScreenSize(3);
    screenHeight = ScreenSize(4);
    relativeWidth = 0.3 * screenWidth;           
    relativeHeight = 0.3 * screenHeight;  
    relativeLeft = rand * (screenWidth - relativeWidth);  
    relativeBottom = rand * (screenHeight - relativeHeight); 
    figure('Position', [relativeLeft, relativeBottom, relativeWidth, relativeHeight]);
    
    corr_mat = eval("corr_mat" + num2str(i));
    imagesc(corr_mat')
 
    cb = colorbar;
    cb.Label.String = "Spearman Correlation";
    clim([-0.2 1]);

    cap = eval("cap" + num2str(i));
    title(cap)
    xlabel("Memory")
    ylabel("Retrieval")
    set(gca, 'ydir', 'normal', 'fontsize', 15)
end
%% Visualization
memnum = 2;
figure; plot(repelem(1:M_max, N_retrievals), corr_mat(memnum, :), 'k*')
xlabel("Retrival Number")
title(sprintf("Corr of Memory %d with retrievals", memnum))
ylabel("Spearman Correlation")
ylim([-0.4 1])
set(gca, 'fontsize', 15)

%% Visualization
for i = 1:5
    submat = eval("corr_mat" + num2str(i));
    cap = eval("cap" + num2str(i));

    y1 = zeros(N_retrievals, M_max);
    y1_err = zeros(1, M_max);
    y2 = zeros(N_retrievals*M_max-N_retrievals, M_max);
    y2_CI95 = zeros(1, M_max);
    y2_CI5 = zeros(1, M_max);
    for memnum = 1:M_max
        idx = false(1, M_max*N_retrievals);
        idx((memnum-1)*N_retrievals + (1:N_retrievals)) = 1;
        y1(:, memnum) = submat(memnum, idx);
        y1_err(1, memnum) = std(submat(memnum, idx));
    
        y2(:, memnum) = submat(memnum, ~idx); 
        y2_CI95(1, memnum) = quantile(submat(memnum, ~idx), 0.995);
        y2_CI5(1, memnum) = quantile(submat(memnum, ~idx)', 0.005);
    end
    
    figure('Position', [randi([0, 1920-600]), randi([0, 1080-400]), 600, 400]);hold on;
    
    plot(y2', 'r.')
    plot(y1', 'ko', MarkerFaceColor=0.7*[1 1 1])
    %errorbar(mean(y1, 1), y1_err, LineStyle='none', Marker='o', CapSize=5, MarkerFaceColor=[1 1 1], Color='k')
    %plot(y1', Color='k', Marker='x', LineStyle='none')
    
    %plot(y2_CI5, 'b')
    %plot(y2_CI95, 'b')
    %plot(mean(y2, 1), 'bo')
    %errorbar(1:1000, mean(y2, 1), -y2_CI5+mean(y2, 1), y2_CI95-mean(y2, 1), LineStyle='none', Marker='o', CapSize=5, MarkerFaceColor=[1 1 1], Color='b')
    
    %xlim([0 1000])
    ylim([-0.4 1.01])
    title_str = sprintf('Correlation between retrievals and memories\n%s', cap);
    title(title_str);
    ylabel("Correlation")
    xlabel("Memory")
    set(gca, 'fontsize', 15)
    %set(gca, 'fontsize', 15, 'XScale', 'log', 'YScale', 'log')
end
%%
save(mynet.RecordingDirectory + filesep + "Everything.mat", '-v7.3')
