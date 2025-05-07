clear; clc;

N = 400;
net = IzhikevichNetwork(N);

net.noise = false;
stim = Stimulation(net, 100, 2, 30, 50, 5);
net.stims = [stim];
net.stimulation = true;
net.STDP = true;
% net.noise = true;

profile on;
net.run(100000);

profile viewer
profile off;
%%
figure; 
plot(net.firings(:,  1), net.firings(:, 2), 'k.')