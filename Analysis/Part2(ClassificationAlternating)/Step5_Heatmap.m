clear; clc;

N = 400; % Network Size
alpha_range = 5:5:95;
nMems_range = [3 5 10 15 20 25 30 50];

% Get list of all items in the current directory
N_mems = 3;

items = dir(fullfile("Data",  "N"+num2str(N),num2str(N_mems) + "memories/"));
folders = items([items.isdir]); % Keep only directories
folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'

