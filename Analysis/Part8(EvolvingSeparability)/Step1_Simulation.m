%% Step1_Simulation.m — Part 8: Evolving Separability with Partial Cues
%
% Sequential learning of 100 memories with MULTI-ALPHA partial-cue probing.
% After learning each memory m, probes memories 40-60 with MULTIPLE cue
% fractions alpha. Learning uses full patterns; probing uses partial cues.
%
% Also probes n_null_patterns NEVER-LEARNED patterns at each episode as a
% concurrent null baseline — same weight state, same alphas, but patterns
% the network has never seen. This separates genuine recall from generic
% pattern completion by the current weight matrix.
%
% Since learning is alpha-independent, all alphas are probed in a single
% simulation run — no need to re-run for each alpha.
%
% Output per simulation folder:
%   ttfs_alpha{round(100*alpha)}_mem{m}.mat  — TTFS(N, 21+n_null, nTrialsProbe)
%       columns 1-21 = tracked memories, 22-(21+n_null) = null patterns
%       one file per alpha per episode
%   Stims.mat — full stimulation objects
%   NullStims.mat — never-learned stimulation objects
%
% Cost estimate (default params):
%   Learning:  100 episodes × 1000 trials                = 100K runs
%   Probing:   100 episodes × 5 alphas × 100 trials × 26 = 1,300K runs
%   Total:     ~1,400K net.run(100) calls

clear; clc;

%%%%%%%%%% User-Defined Parameters %%%%%%%%%%
N              = 400;
n_mems         = 100;        % total memories to learn
n_trials       = 1000;       % learning trials per memory
n_trials_probe = 100;        % probe trials per memory per alpha (matches Part 3)
alphas         = [0.1, 0.3, 0.5, 0.7, 0.9];  % cue fractions to probe
n_null_patterns = 5;         % never-learned patterns for null baseline
scale50        = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if scale50
    scaleFolder = 'Scaled50';
    nCells = round(50 * N / 400);
else
    scaleFolder = 'Constant50';
    nCells = 50;
end

baseFolder = fullfile("Data", scaleFolder, "N" + num2str(N));

% Initialize network
net = IzhikevichNetwork(N, ...
    'heterogeneity', true, ...
    'g_ee', 0.5, ...
    'g_ei', 2, ...
    'g_ie', 2, ...
    'ExtoExDegree', 20, ...
    'InhtoExDegree', 5, ...
    'ExtoInhDegree', 5, ...
    'baseFolder', baseFolder);

net.STDP = true;
net.stimulation = true;
net.sampling = false;
net.saveSimulation = false;
net.showProgress = false;   % no waitbar — we print progress via fprintf

%% Generate full stimulation patterns for all memories
stims = [];
for m = 1:n_mems
    stims = [stims, Stimulation(net, 100, 2, 30, nCells, 5)];
end
save(net.RecordingDirectory + filesep + "Stims.mat", "stims", '-mat');

%% Generate NEVER-LEARNED null patterns (same statistics, never used for learning)
null_stims = [];
for ni = 1:n_null_patterns
    null_stims = [null_stims, Stimulation(net, 100, 2, 30, nCells, 5)];
end
save(net.RecordingDirectory + filesep + "NullStims.mat", "null_stims", '-mat');

%% Helper: create partial-cue version of a Stimulation object
% Keeps only alpha fraction of pattern cells, matching the Part3 protocol.
function partial = make_partial_cue(stim_obj, alpha)
    partial = stim_obj.copy();
    partial.Ncells = max(1, ceil(alpha * stim_obj.Ncells));
    sub_set = randperm(stim_obj.Ncells, partial.Ncells);
    partial.pattern_indices = stim_obj.pattern_indices(sub_set);
    partial.pattern_timings = mod(stim_obj.pattern_timings(sub_set), 100);
    partial.interval = 100;
    partial.start_time = 5;
    partial.ConstructStimCurrent();
end

%% Main simulation loop
t_total = tic;
for m = 1:n_mems
    t_episode = tic;
    % ===== Learning phase: full pattern, STDP on =====
    % Single long run — stim repeats every 100ms via mod(t, interval).
    % w_save allocation is skipped when sampling=false (see IzhikevichNetwork.m).
    net.STDP = true;
    net.stims = stims(m);
    net.run(n_trials * 100);
    
    % ===== Probing phase: partial cues, STDP off =====
    net.STDP = false;
    n_probe_total = 21 + n_null_patterns;  % tracked + null
    for ai = 1:numel(alphas)
        alpha = alphas(ai);
        alphaTag = sprintf("alpha%d", round(100 * alpha));
        ttfs = NaN(N, n_probe_total, n_trials_probe);

        for trial = 1:n_trials_probe
            % --- Probe tracked memories (columns 1-21) ---
            for mem = 40:60
                partial_stim = make_partial_cue(stims(mem), alpha);
                net.stims = partial_stim;
                t_start = net.t;  % absolute time before probe
                net.run(100);
                
                if ~isempty(net.firings)
                    % Relative TTFS: subtract probe start time
                    % Non-firing neurons stay as NaN
                    raw = accumarray( ...
                        net.firings(:,2), net.firings(:,1), [N,1], @min, NaN);
                    raw = raw - t_start;  % relative to probe onset
                    ttfs(:, mem-39, trial) = raw;
                end
            end
            
            % --- Probe null patterns (columns 22 onwards) ---
            for ni = 1:n_null_patterns
                partial_stim = make_partial_cue(null_stims(ni), alpha);
                net.stims = partial_stim;
                t_start = net.t;
                net.run(100);
                
                if ~isempty(net.firings)
                    raw = accumarray( ...
                        net.firings(:,2), net.firings(:,1), [N,1], @min, NaN);
                    raw = raw - t_start;
                    ttfs(:, 21 + ni, trial) = raw;
                end
            end
        end

        % Save per-alpha per-episode
        save(fullfile(net.RecordingDirectory, ...
            sprintf("ttfs_%s_mem%d.mat", alphaTag, m)), ...
            "ttfs", '-mat');
    end
    
    elapsed = toc(t_episode);
    avg_time = toc(t_total) / m;
    fprintf("Episode %d/%d complete. (%.1f sec, ETA %.0f min)\n", ...
        m, n_mems, elapsed, avg_time * (n_mems - m) / 60);
end

fprintf("Simulation complete: alphas=[%s], N=%d\n", ...
    strjoin(string(alphas), ', '), N);
