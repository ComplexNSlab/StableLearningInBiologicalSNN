

f_mem = f('mem1');
f_noise = f('noise1');

[bursts_mem, ~] = utils.BurstDetector(f_mem, [], false, 'all', windSize, timebinSize);
[bursts_noise, ~] = utils.BurstDetector(f_noise, [], false, 'all', windSize, timebinSize);

[F_mem, ~] = utils.ExtractBurstFeatures(f_mem, bursts_mem, N);
[F_noise, ~] = utils.ExtractBurstFeatures(f_noise, bursts_noise, N);

burstID = randi(size(F_noise, 1));

%%%%%%%%%%%%%%%%%%%% RAW Bursts
figure(Position=[200 200 1600 1000]); 
ax1 = subplot(3, 2, 1);
scatter(F_mem(end, :), 1:N); title("Memory Seq Raw"); xlabel("time, ms");
ax2 = subplot(3, 2, 2);
scatter(F_noise(burstID, :), 1:N); title("Noise Burst Raw"); xlabel("time, ms");
linkaxes([ax1, ax2], 'x');

F_mem = F_mem - nanmean(F_mem, 2);
F_noise = F_noise - nanmean(F_noise, 2);

%%%%%%%%%%%%%%%%%%%% Centered Bursts
ax3 = subplot(3, 2, 3);
scatter(F_mem(end, :), 1:N); title("Memory Seq centered"); xlabel("time, ms");
ax4 = subplot(3, 2, 4);
scatter(F_noise(burstID, :), 1:N);title("Noise Burst centered"); xlabel("time, ms");
linkaxes([ax3, ax4], 'x');

F_mem = F_mem./ nanstd(F_mem, 0, 2);
F_noise =F_noise./ nanstd(F_noise, 0, 2);

%%%%%%%%%%%%%%%%%%%% Scaled Bursts
ax5 = subplot(3, 2, 5);
scatter(F_mem(end, :), 1:N); title("Memory Seq Scaled"); xlabel("T, normalized unit")
ax6 = subplot(3, 2, 6);
scatter(F_noise(burstID, :), 1:N);title("Noise Burst Scaled"); xlabel("T, normalized unit")
linkaxes([ax5, ax6], 'x')



%%
dist  = utils.ComputePearsonSimilarity(F_mem, F_noise, 50, 100);

figure;histogram(dist)