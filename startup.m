% Automatically add src and its subfolders to the MATLAB path
addpath(genpath(fullfile(pwd, 'Src')));
disp('StableLearningInBiologicalSNN: added Src/ to path.');

%% ---- Thesis-wide figure defaults ----
% All scripts inherit these unless explicitly overridden.
% To keep figures consistent, avoid per-script set(groot,...) or
% set(gca,'FontName',...) calls — let these defaults do the work.

% Font
set(0, 'DefaultAxesFontName',       'Times New Roman');
set(0, 'DefaultTextFontName',       'Times New Roman');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultTextInterpreter',    'latex');
set(0, 'DefaultLegendInterpreter',  'latex');

% Size
set(0, 'DefaultAxesFontSize',       13);
set(0, 'DefaultTextFontSize',       13);
set(0, 'DefaultLegendFontSize',     11);

% Lines
set(0, 'DefaultLineLineWidth',      1.5);
set(0, 'DefaultAxesLineWidth',      0.8);

% Figure
set(0, 'DefaultFigureColor',        'w');

disp('Thesis figure defaults loaded.');
