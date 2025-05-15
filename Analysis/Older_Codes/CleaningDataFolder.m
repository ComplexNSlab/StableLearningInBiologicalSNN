% This script deletes all folders in the "Data" directory 
% that contain less than three files.

% Define the directory to check
mainDir = 'Data';

% Get a list of all folders in the main directory
folderList = dir(mainDir);

% Loop through each folder
for i = 1:length(folderList)
    % Skip if it's not a folder or it's a system folder like '.' or '..'
    if ~folderList(i).isdir || strcmp(folderList(i).name, '.') || strcmp(folderList(i).name, '..')
        continue;
    end
    
    % Get the path of the current folder
    folderPath = fullfile(mainDir, folderList(i).name);
    
    % Get a list of all files in the current folder
    fileList = dir(folderPath);
    
    % Filter out directories ('.', '..', and subfolders)
    fileList = fileList(~[fileList.isdir]);
    
    % Check if the number of files is less than 3
    if length(fileList) < 3
        % If true, delete the folder and its contents
        fprintf('Deleting folder: %s\n', folderPath);
        rmdir(folderPath, 's');
    end
end

fprintf('Folder cleanup complete.\n');
