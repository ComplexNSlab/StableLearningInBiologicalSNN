clc; clear;
% Set the root directory for N400
rootDir = fullfile('Data', 'N400');

% Get list of all files named ClassificationResultsInfinity.mat under N400
files = dir(fullfile(rootDir, '**', 'ClassificationResultsInfinity.mat'));

fprintf('Found %d files to delete:\n', numel(files));

% Loop through each file and delete it
for k = 1:numel(files)
    filePath = fullfile(files(k).folder, files(k).name);
    fprintf('Deleting: %s\n', filePath);
    delete(filePath);
end

fprintf('Done.\n');
