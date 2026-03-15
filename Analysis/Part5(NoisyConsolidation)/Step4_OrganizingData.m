data = zeros(n_mems, sum(N_bursts_ord(2:2:end)));
for mem = 1:n_mems
    temp = memBurstSimMat((mem-1)*100 +1 :mem*100, :);
    data(mem, :) = mean(temp, 1);
end

noiseBurstLabels = repelem(1:n_mems,  N_bursts_ord(2:2:end));

index = [];
n = 0;
for num =  N_bursts_ord(2:2:end)
    index = [index; [n + 1, num + n]];
    n = num + n;
end

% Initialize data as a cell array
Data = cell(n_mems, n_mems);  
c_label = {};  % Category labels
g_label = {};  % Group labels

% Populate data and labels
for mem = 1:n_mems
    for i = 1:n_mems
        % Extract data for each (mem, i) combination
        temp = data(mem, index(i, 1):index(i, 2));
        temp = temp(:)';
        temp = temp(~isnan(temp));

        % Store data in the cell array
        Data{mem, i} = temp;  % Ensure each group data is a row vector

        % Define labels
        if mem == 1
            c_label{i} = ['noisy bursts ', num2str(i)];
        end
        g_label{mem} = ['mem', num2str(mem)];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_stats = zeros(n_mems, n_mems, 4);
for mem = 1:n_mems
    for noise = 1:n_mems
        tempArr = Data{mem, noise};
        M = mean(tempArr);
        CI_upper = prctile(tempArr, 95);
        CI_lower = prctile(tempArr, 5);
        sigma = std(tempArr);
        
        data_stats(mem, noise, :) = [M, CI_lower, CI_upper, sigma];
    end
end

save(fullfile(net.RecordingDirectory, "similarityMatrices.mat"), 'Data', 'data_stats', '-append');
