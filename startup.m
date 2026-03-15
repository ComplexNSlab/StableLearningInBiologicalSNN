% Automatically add src and its subfolders to the MATLAB path
addpath(genpath(fullfile(pwd, 'src')));
disp('StableLearningInBiologicalSNN Added src and subfolders to path.');

% adjusting the font for figure generation 
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 12);
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultTextFontSize', 12);
set(0, 'DefaultLegendFontSize', 10);
disp('Font settings are set!');
