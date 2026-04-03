% Step00.m
% =========================================================================
% Batch launcher for single-memory stabilisation simulations.
%
% Loops over network sizes N and repetitions, calling Step01_Simulation
% each time to run one full training simulation.
%
% PARAMETERS:
%   scale50Flag — if true, stimulus size scales as 50*(N/400); else fixed 50
%   nTrials     — number of training trials per simulation
%   trialLen    — duration of each trial (ms)
%
% OUTPUTS:
%   Data/Scaled50/N{N}/{simID}/MemoryRepresentations.mat  (per simulation)
% =========================================================================

cfg = jsondecode(fileread('config.json'));
scale50Flag = cfg.scale50Flag;
nTrials = cfg.nTrials;
trialLen = cfg.trialLen;
if isfield(cfg, 'trialsSubfolder') && ~isempty(cfg.trialsSubfolder)
    trialsSubfolder = cfg.trialsSubfolder;
else
    trialsSubfolder = '';
end

for N = cfg.networkSizes(:)'
    for iter = 1:cfg.iterationsPerN
        Step01_Simulation;
    end
end