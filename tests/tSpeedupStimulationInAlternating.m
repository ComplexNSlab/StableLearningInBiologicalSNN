clear; clc

net = IzhikevichNetwork(400);
net.STDP = true;
net.sampling = false;
net.stimulation = true;

stim1 = Stimulation(net, 200, 2, 30, 50, 5);
stim2 = Stimulation(net, 200, 2, 30, 50, 105);

net.run(100*1000);
data = net.getData();
%%

firings = data.firings;

figure;
scatter(firings(1, :), firings(2, :), 'k', '.')