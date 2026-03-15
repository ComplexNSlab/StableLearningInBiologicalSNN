clc; clear; 

folders = dir("Data\N1600\nMems20\noise100%\");
isSubfolder = [folders.isdir] & ~ismember({folders.name}, {'.', '..'});
folderPaths = fullfile({folders(isSubfolder).folder}, {folders(isSubfolder).name});

for i = 1:numel(folderPaths)
    clearvars -except i folderPaths
    load(fullfile(folderPaths{i}, 'simInitialWorkSpace.mat'));
    Step3_ExtractBurstsFeatures;
    Step4_OrganizingData;
end
