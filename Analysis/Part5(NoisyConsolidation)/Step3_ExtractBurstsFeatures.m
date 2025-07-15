%% Detecting the burst give the hyper parameters (windSize, timebinSize, Threshold)
windSize = 3; timebinSize = 3; subset = 'ex'; thresh = 10;

data = net.getData();
firings = data.firings;

lerning_win = trialLen * nTrials / 1000;
step = (lerning_win + noise_window)*1000;

f = containers.Map();
for i = 1:n_mems    
    index1 = (firings(1, :) > step*(i-1)+ 90000 ) & (firings(1, :) < step*(i-1)+100000);
    index2 = (firings(1, :) > step*(i-1)+100000 ) & (firings(1, :) < step*(i-1) + step);
    f(['mem', num2str(i)]) = firings(:, index1);
    f(['noise', num2str(i)]) = firings(:, index2);
end

clear data firings;

%% ---------- build ordered key_list first ----------------------------
key_list = {};
for k = 1:n_mems
    mKey = sprintf('mem%d',  k);
    nKey = sprintf('noise%d',k);
    if isKey(f,mKey),   key_list{end+1} = mKey;  end
    if isKey(f,nKey),   key_list{end+1} = nKey;  end
end
% key_list = {'mem1','noise1','mem2','noise2', …}

%% ---------- extract values in that same order -----------------------
val_list = cellfun(@(k) f(k), key_list, 'UniformOutput', false);

%% ---------- make a NEW map in the desired order ---------------------
fOrdered = containers.Map( key_list , val_list );

% From here on, iterate over key_list and use fOrdered
bursts    = [];
num_burst = containers.Map();               % empty map

for k = 1:numel(key_list)
    
    key         = key_list{k};
    data        = fOrdered(key);            % value in correct sequence
    [bt, fig]   = utils.BurstDetector(data, thresh, false, subset, windSize, timebinSize);

    bursts      = [bursts; bt];
    num_burst(key) = size(bt,1);
end

[features, f_names] = utils.ExtractBurstFeatures(cell2mat(val_list), bursts, N);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Computing the pearson distances  

%% ------------------------------------------------------------
%  CONFIGURATION  (tune as needed)

%% ------------------------------------------------------------
%  INPUTS
%  assemblies : [R × D] double  (rows = bursts / assemblies)
%  num_burst  : containers.Map with #bursts per memory
% -------------------------------------------------------------
assemblies = features(:, 1:net.Ne);                     % your variable

%% 1.  Row-wise z-score  ---------------------------------------------
X_mean     = nanmean(assemblies,2);
X_std      = nanstd (assemblies,0,2);
assemblies = (assemblies - X_mean) ./ X_std;    % rows now mean-0, sd-1
% assemblies = (assemblies - X_mean);    % rows now mean-0, sd-1

%% ----------------------------------------------------------
% key_list   : {'mem1','noise1','mem2','noise2', …}
% num_burst  : containers.Map  (key → #rows in assemblies)
% ----------------------------------------------------------
N_bursts_ord = cellfun(@(k) num_burst(k), key_list);   % 1×(2N) counts
cum          = cumsum([0, N_bursts_ord]);              % prefix-sum edges

rowsMem   = [];          % indices for mem bursts  → A
rowsNoise = [];          % indices for noise bursts → B

for k = 1:2:numel(key_list)        % step through mem / noise pairs
    % ---- mem k ------------------------------------------------------
    a1 = cum(k)   + 1;             % first row of mem-k
    a2 = cum(k+1);                 % last  row of mem-k
    rowsMem   = [rowsMem , a1:a2];

    % ---- noise k ----------------------------------------------------
    b1 = cum(k+1) + 1;             % first row of noise-k
    b2 = cum(k+2);                 % last  row of noise-k
    rowsNoise = [rowsNoise , b1:b2];
end

%% -------------- slice the big matrix -------------------------------
A = assemblies(rowsNoise  , :);      % all memory bursts
B = assemblies(rowsMem, :);      % all noise  bursts
% clear assemblies                   % free RAM

memBurstSimMat = utils.ComputePearsonSimilarity(A, B, 50); memBurstSimMat = memBurstSimMat';
memMemSimMat = utils.ComputePearsonSimilarity(B, B, 50);

save(fullfile(net.RecordingDirectory, "similarityMatrices.mat"), 'memBurstSimMat', 'memMemSimMat', 'N_bursts_ord');

