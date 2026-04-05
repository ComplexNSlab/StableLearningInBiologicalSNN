% RunAllPlots.m
% =========================================================================
% Runs all plotting scripts in sequence. Assumes the .mat results files
% already exist (from Step04, Step06, Step09).
%
% Sets show_figs = 'off' so figures are created but not displayed.
% Exported PDFs and PNGs are saved to the results folder.
%
% Usage:  Just hit Run, or call:  run('RunAllPlots.m')
% =========================================================================

close all; clc;

% Ensure we're in the right directory
scriptDir = fileparts(which('RunAllPlots'));
cd(scriptDir);

runAllPlots__scripts = {
    'Step05_PlateauBoxplot'
    'Step05_SlopeBoxplot'
    'Step07_WeightStabilizationPlots'
    'Step08_WeightVsRepresentationComparison'
    'Step10_RadialStabilizationPlots'
    'Step11_RadialVsRepresentationComparison'
};

% Suppress figure display in child scripts
show_figs = 'off';

for runAllPlots__i = 1:numel(runAllPlots__scripts)
    fprintf('\n========== Running %s ==========\n', runAllPlots__scripts{runAllPlots__i});
    try
        evalc(runAllPlots__scripts{runAllPlots__i});
        fprintf('  Done.\n');
    catch ME
        fprintf(2, '  ERROR in %s: %s\n', runAllPlots__scripts{runAllPlots__i}, ME.message);
    end
end

fprintf('\n========== All plots complete ==========\n');
close all;
