%% This Code Creates and Configures a Network with Specified Properties %% 

%% Parameters to be set
clear; 
clc;

% Network Architecture Parameters
N = 400; 
g_ee = 0.5; 
g_ei = 2; 
g_ie = 2; 
heterogeneity = true; 
ExtoExDegree = 20; 
InhtoExDegree = 5; 
ExtoInhDegree = 5;

% Noise Parameters
noise = false; 
sigma_ex = 5; 
sigma_inh = 2; % Fixed typo in variable name

% Plasticity Mechanisms
STDP = true; 
scaling = false;
sampling_rate = 500; % steps; every 10 s

% base folder to save simulation 
baseFolder = "." + filesep + "AssemblyExperiments" + filesep + "Data"; 
%% Create an instance of IzhikevichNetwork with specified parameters
mynet = IzhikevichNetwork( ...
    N, ...
    'g_ee', g_ee, ...
    'g_ei', g_ei, ...
    'g_ie', g_ie, ...
    'heterogeneity', heterogeneity, ...
    'ExtoExDegree', ExtoExDegree, ...
    'InhtoExDegree', InhtoExDegree, ...
    'ExtoInhDegree', ExtoInhDegree ...
);

% Set additional properties
mynet.STDP = STDP;
mynet.scaling = scaling;
mynet.noise = noise;
mynet.sigma_ex = sigma_ex;
mynet.sigma_inh = sigma_inh; % Fixed typo in variable name
mynet.sampling = true;

clearvars -except mynet