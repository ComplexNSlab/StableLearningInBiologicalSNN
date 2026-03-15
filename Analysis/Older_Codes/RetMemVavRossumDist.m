%% Reading last trials of each memory rasters and convert them to A signals
clear; clc;

RecordingDirectory = "Data\Aug_20_2024_15_41";
M_max = 100;
tau = 3;

trialnum = 1000;
A_lrnt = zeros(M_max, 400, 1000);
f = waitbar(0, "Please Wait ....");
for memnum = 1:M_max
    waitbar(memnum/M_max, f, sprintf("Memory num %d/%d", memnum, M_max));
    file = RecordingDirectory + filesep + "patch" + num2str(memnum);
    data = load(file);
    data = getfield(data, "data"+num2str(memnum));
    firings = data.firings;
    firings(1, :) = firings(1, :)/1000;
    idx = ((memnum-1)*100 + 0.1*(trialnum-1) <= firings(1, :)) & (firings(1, :) <= (memnum-1)*100 + 0.1*trialnum);
    firings = firings(:, idx);
    firings(1, :) = mod(firings(1, :), 0.1)*1000;
    A_lrnt(memnum, :, :) = LowPass(firings, tau); 
end
close(f)

trialnum = 5;
A_retrieval = zeros(M_max, 400, 1000);
f = waitbar(0, "Please Wait ....");
for retnum = 1:M_max
    waitbar(retnum/M_max, f, sprintf("Retrieval num %d/%d", retnum, M_max));
    file = RecordingDirectory + filesep + "patch" + num2str(M_max+retnum);
    data = load(file);
    data = getfield(data, "data"+num2str(M_max+retnum));
    firings = data.firings;
    firings(1, :) = firings(1, :)/1000;
    idx = (M_max*100 + (retnum-1)*0.5 + 0.1*(trialnum-1) <= firings(1, :)) & (firings(1, :) <= M_max*100 + (retnum-1)*0.5 + 0.1*trialnum);
    firings = firings(:, idx);
    firings(1, :) = mod(firings(1, :), 0.1)*1000;
    A_retrieval(retnum, :, :) = LowPass(firings, tau); 
end

waitbar(1, f, "Saving Low pass signals");
save(RecordingDirectory + filesep + sprintf("A_lowpass_%d.mat", tau), "A_retrieval", "A_lrnt", "tau", '-v7.3')

close(f)

%% Checking pair of retirval and memory 
 
memnum = 100;
retnum = 100;
figure('Units', 'inches', 'Position', [1, 1, 10, 10]);

cbmax1 = max(max(A_lrnt(memnum, :, :)));
cbmax2 = max(max(A_retrieval(retnum, :, :)));
cbmax = max(cbmax1, cbmax2);

subplot(3, 1, 1)
imagesc(squeeze(A_lrnt(memnum, :, :))); cb = colorbar(); cb.Label.String = "Hz"; clim([0 cbmax]);
title(sprintf("Memory %d", memnum))
ylabel("Neuron ID")
set(gca,'ydir', 'normal', 'fontsize', 15)
ticks = 1:100:1000;
xticks(ticks)
xticklabels((ticks-1)/10)

subplot(3, 1, 2)
imagesc(squeeze(A_retrieval(retnum, :, :))); cb = colorbar(); cb.Label.String = "Hz"; clim([0 cbmax]);
title(sprintf("Retrival %d", retnum))
xlabel("Time (ms)")
ylabel("Neuron ID")
xticks(ticks)
xticklabels((ticks-1)/10)
set(gca,'ydir', 'normal', 'fontsize', 15)

dA = A_lrnt(memnum, :, :) - A_retrieval(retnum, :, :);
dA = squeeze(dA .* dA); 
dA = squeeze(sqrt(sum(dA, 2) * 0.1 / tau));

subplot(3, 1, 3)

plot(dA)
xlabel("Neuron ID")
ylabel("Spike Distance")
text('Units', 'normalized', 'Position', [0.4, 0.9], 'String', sprintf("Distance = %0.1f", norm(dA)));
set(gca,'ydir', 'normal', 'fontsize', 15)

saveas(gcf, RecordingDirectory + filesep + sprintf("M%d_R%d.png", memnum, retnum))
%% Computing Distance between spike rasters of retrievals and memories
d = zeros(100, 100);

f = waitbar(0, "please wait");
for memnum = 1:size(d, 1)
    for retnum = 1:size(d, 2)
        waitbar(((memnum-1)*size(d,2) + retnum)/size(d,1)/size(d,2), f, sprintf("memnum %d retnum %d", memnum, retnum));
        dA = A_lrnt(M_max+1-memnum, :, :) - A_retrieval(M_max+1-retnum, :, :);
        dA = squeeze(dA .* dA); dA = sqrt(sum(dA, 2) * 0.1 / tau);
       
        d(memnum, retnum) = norm(squeeze(dA));
    end
end
close(f);
%% Plotting retrieval Vs. Memories Distance
figure;
subplot(2, 1, 1)
imagesc(d'); cb = colorbar; cb.Label.String = "Spike Distance";
xlabel("Memory")
ylabel("Rerieval")
xticks(1 :10 : size(d, 1)+1)
xticklabels(M_max+1 - (1 :10 : size(d, 1)+1))
yticks(1 :10 : size(d, 2)+1)
yticklabels(M_max+1 - (1 :10 : size(d, 2)+1))

set(gca, 'ydir', 'normal', 'fontsize', 15)

subplot(2, 1, 2); hold on;
plot(d(:, 1:end-1), 'k.', HandleVisibility='off')
plot(d(:, end), 'k.', DisplayName='Other Memories Retrieval')
plot(diag(d), 'ro', DisplayName='Same Memory Retrieval')

legend('Location', 'best');
xlabel("Memory")
ylabel("Distance")
xticks(1 :10 : size(d, 1))
xticklabels(M_max+1 - (1 :10 : size(d, 1)))
set(gca, 'FontSize', 15)
%% Functions 
function A = LowPass(firings_, tau)
    A = zeros(400, 1000);
    
    for i = 1:size(firings_, 2)
        A(firings_(2, i), :) = A(firings_(2, i), :) + (((1:1000)*0.1 - firings_(1, i)) >= -0.05) .* exp(-((1:1000)*0.1 - firings_(1, i))/tau);
    end
end