%% Configuring the network 
clear 
clc
rng(2,"twister");

mynet = IzhikevichNetwork(400);
mynet.SetInitialConnectivity(0.5, 2, 2);
mynet.STDP = true;
mynet.AddHeterogeneity;
mynet.stimulation = true;
mynet.sampling = true;

%% Run network

mynet.run(10000)
data = mynet.getData;

