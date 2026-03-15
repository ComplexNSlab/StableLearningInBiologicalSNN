%% Reading a particular memory learning phase
clear; clc;
RecordingDirectory = "Data\Aug_16_2024_18_58";

memnum = 1;
file = RecordingDirectory + filesep + "patch" + num2str(memnum);
data = load(file);
data = getfield(data, "data"+num2str(memnum));
firings = data.firings;
firings(1, :) = firings(1, :)/1000;

tau = 2;
f = waitbar(0, "Please Wait ...");
trials = 1:100:1000;
d = zeros(length(trials), length(trials));

for i = 1:length(trials)
    idx1 = ((memnum-1)*100 + 0.1*(trials(i)-1) <= firings(1, :)) & (firings(1, :) <= (memnum-1)*100 + 0.1*trials(i));
    firings1 = firings(:, idx1);
    firings1(1, :) = mod(firings1(1, :), 0.1)*1000;
    A1 = LowPass(firings1, tau);
    clear firings1 
    
    for j = i:length(trials)
        idx2 = ((memnum-1)*100 + 0.1*(trials(j)-1) <= firings(1, :)) & (firings(1, :) <= (memnum-1)*100 + 0.1*trials(j));
        firings2 = firings(:, idx2);
        firings2(1, :) = mod(firings2(1, :), 0.1)*1000;
        
        A2 = LowPass(firings2, tau);
       
        distances = diag(pdist2(A1, A2, 'euclidean')) * 0.1 / tau;
        d(i, j) = norm(distances);
        d(j, i) = norm(distances);

        waitbar(i/length(trials), f, sprintf("trial1 %d trial2 %d", trials(i), trials(j)))
    end
end
close(f)
%clearvars -except d
%% Visualizing the inter memory evolution distance matrix
for i = 1:size(d, 1)
    d(i,i) = 0.5*(min(d(i, setxor(1:size(d, 1), i))) + min(d(setxor(1:size(d, 1), i), i)));
end
figure;
imagesc(d)
cb = colorbar; cb.Label.String = "Spike Distance";
xlabel("Trial")
ylabel("Tiral")
ticks = 1:5:length(trials);
xticks(ticks)
xticklabels(trials(ticks)-1)
yticks(ticks)
yticklabels(trials(ticks)-1)
title(sprintf("Multicell distance across trials for memory %d", memnum))
set(gca, 'ydir', 'normal', 'fontsize', 15)


%% Functions 

function A = LowPass(firings_, tau)
    A = zeros(400, 1000);
    
    for i = 1:size(firings_, 2)
        A(firings_(2, i), :) = A(firings_(2, i), :) + (((1:1000)*0.1 - firings_(1, i)) >= -0.001) .* exp(-((1:1000)*0.1 - firings_(1, i))/tau);
    end
end
