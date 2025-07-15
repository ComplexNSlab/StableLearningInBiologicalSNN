clc; clear; 

folders = dir("Data\N400\nMems20\noise100%\");
isSubfolder = [folders.isdir] & ~ismember({folders.name}, {'.', '..'});
folderPaths = fullfile({folders(isSubfolder).folder}, {folders(isSubfolder).name});

for i = 1:numel(folderPaths)-1
    clearvars -except i folderPaths
    load(fullfile(folderPaths{i}, 'simInitialWorkSpace.mat'));
    Step3_ExtractBurstsFeatures;
    Step4_OrganizingData;
end
