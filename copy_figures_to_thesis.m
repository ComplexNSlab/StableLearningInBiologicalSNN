%% copy_figures_to_thesis.m
%  Run from the MATLAB repo root AFTER regenerating figures.
%  Copies MATLAB outputs → thesis Figures/ with correct names.

thesisRoot = fullfile('..', '64e3cd951c6d185e2d3ab4fa', 'Figures', 'Results');
matlabRoot = fullfile('Analysis');

% --- Configuration (must match config.json) ---
N_representative = 400;          % Network size used for single-example figures
scaleFolder      = 'Scaled50';
trialsSubfolder  = 'Trials1500';
paramTag         = 'frac010_smooth100_hold100';

%% ======== Section 1: Single Memory Encoding (Part1) ========
sec1 = fullfile(thesisRoot, 'Section1-SingleMemoryEncoding');
part1 = fullfile(matlabRoot, 'Part1(StabilizationOfSingleMemory)');

convergenceDir = fullfile(part1, 'Results', scaleFolder, trialsSubfolder, ...
    sprintf('N%d', N_representative), 'Convergence');
stabDir = fullfile(part1, 'Results', 'StabilizationResults', paramTag);

copies_sec1 = {
    % Source (MATLAB)                                         Destination (thesis)
    fullfile(convergenceDir, 'latency.pdf'),                  fullfile(sec1, 'Statistics', 'latency.pdf')
    fullfile(convergenceDir, 'latency.png'),                  fullfile(sec1, 'Statistics', 'latency.png')
    fullfile(convergenceDir, 'spikeCount.pdf'),               fullfile(sec1, 'Statistics', 'spikeCount.pdf')
    fullfile(convergenceDir, 'spikeCount.png'),               fullfile(sec1, 'Statistics', 'spikeCount.png')
    fullfile(part1, 'Results', 'SpikeOrderSeparate.png'),     fullfile(sec1, 'Statistics', 'SpikeOrderSeparate.png')
    fullfile(part1, 'Results', 'SpikeOrderTogether.png'),     fullfile(sec1, 'Statistics', 'SpikeOrderTogether.png')
    fullfile(stabDir, 'Step05_RepresentationalStabilization_Plateau.pdf'),   fullfile(sec1, 'DelaysVsSpikeCounts_Boxplot.pdf')
    fullfile(stabDir, 'Step05_RepresentationalStabilization_Plateau.png'),   fullfile(sec1, 'DelaysVsSpikeCounts_Boxplot.png')
    fullfile(stabDir, 'Step07_DeltaW_SingleRun.pdf'),         fullfile(sec1, 'SingleExample', 'Representative_DeltaW_Trajectory.pdf')
    fullfile(stabDir, 'Step07_StructuralStabilization.pdf'),   fullfile(sec1, 'Statistics', 'StructuralStabilization_Boxplot.pdf')
    fullfile(stabDir, 'Step07_StructuralStabilization.png'),   fullfile(sec1, 'Statistics', 'StructuralStabilization_Boxplot.png')
    fullfile(stabDir, 'Step08_StructuralVsRepresentational_Diff.pdf'),  fullfile(sec1, 'Statistics', 'StructuralMinusDelay_Boxplot.pdf')
    fullfile(stabDir, 'Step08_StructuralVsRepresentational_Diff.png'),  fullfile(sec1, 'Statistics', 'StructuralMinusDelay_Boxplot.png')
};

%% ======== Section 1: Frequency Analysis (Part7) ========
part7 = fullfile(matlabRoot, 'Part7(StructuredSpontaneousActivity)');

copies_sec1_freq = {
    fullfile(part7, 'Results', 'ISI_dist.png'),               fullfile(sec1, 'ISI_dist.png')
    fullfile(part7, 'Results', 'instantaneousFreq_dist.png'),  fullfile(sec1, 'instantaneousFreq_dist.png')
    fullfile(part7, 'Results', 'relativeGain.pdf'),            fullfile(sec1, 'relativeGain.pdf')
};

%% ======== Section 2: Alternating Learning (Part2) ========
sec2 = fullfile(thesisRoot, 'Section2-AlternatingLearning');
part2 = fullfile(matlabRoot, 'Part2(ClassificationAlternating)');

copies_sec2 = {
    fullfile(part2, 'Results', 'SVMResults', 'Precision_Curve_30_Mems.pdf'),   fullfile(sec2, 'Precision_Curve_30_Mems.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'Recall_Curve_30_Mems.pdf'),      fullfile(sec2, 'Recall_Curve_30_Mems.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'F1Score_Curve_30_Mems.pdf'),     fullfile(sec2, 'F1Score_Curve_30_Mems.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'AUC_Curve_30_Mems.pdf'),         fullfile(sec2, 'AUC_Curve_30_Mems.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'Precision_Heatmap_Memories.pdf'), fullfile(sec2, 'Precision_Heatmap_Memories.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'Precision_Heatmap_Randoms.pdf'),  fullfile(sec2, 'Precision_Heatmap_Randoms.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'Recall_Heatmap_Memories.pdf'),    fullfile(sec2, 'Recall_Heatmap_Memories.pdf')
    fullfile(part2, 'Results', 'SVMResults', 'Recall_Heatmap_Randoms.pdf'),     fullfile(sec2, 'Recall_Heatmap_Randoms.pdf')
    fullfile(part2, 'Results', 'capacity', 'Capacity_vs_N_multiThresh_alpha_0.10.pdf'), fullfile(sec2, 'Capacity_vs_N_multiThresh_alpha_0.10.pdf')
};

%% ======== Section 3: Sequential Learning (Part4) ========
sec3 = fullfile(thesisRoot, 'Section3-SequentialLearning');
part4 = fullfile(matlabRoot, 'Part4(TrackingSequentialLearning)');
part4res = fullfile(part4, 'Results', scaleFolder, sprintf('N%d', N_representative));
part4fit = fullfile(part4, 'Results', 'Scaled50');

copies_sec3 = {
    fullfile(part4res, 'norm_A.pdf'),        fullfile(sec3, sprintf('norm_A_N%dtrials1000.pdf', N_representative))
    fullfile(part4res, 'assembly.pdf'),       fullfile(sec3, sprintf('assembly_N%dtrials1000.pdf', N_representative))
    fullfile(part4fit, 'delays_drop.pdf'),    fullfile(sec3, 'delays_drop.pdf')
    fullfile(part4fit, 'assembly_jump.pdf'),  fullfile(sec3, 'assembly_jump.pdf')
    fullfile(part4fit, 'decay_time_scale.pdf'), fullfile(sec3, 'decay_time_scale.pdf')
};

%% ======== Section 4: Memory Replay (Part5) ========
sec4 = fullfile(thesisRoot, 'Section4-MemoryReplay');
part5 = fullfile(matlabRoot, 'Part5(NoisyConsolidation)');

copies_sec4 = {
    fullfile(part5, 'Results', 'ReplayDecay_PowerLaw.pdf'),   fullfile(sec4, '7_ReplayDecayPowerLaw.pdf')
};

%% ======== Execute all copies ========
allCopies = [copies_sec1; copies_sec1_freq; copies_sec2; copies_sec3; copies_sec4];

nOK = 0;  nSkip = 0;  nFail = 0;
for i = 1:size(allCopies, 1)
    src = allCopies{i, 1};
    dst = allCopies{i, 2};

    if ~isfile(src)
        fprintf('SKIP  (not found): %s\n', src);
        nSkip = nSkip + 1;
        continue
    end

    dstDir = fileparts(dst);
    if ~isfolder(dstDir), mkdir(dstDir); end

    try
        copyfile(src, dst);
        fprintf('OK    %s\n      -> %s\n', src, dst);
        nOK = nOK + 1;
    catch ME
        fprintf('FAIL  %s\n      %s\n', src, ME.message);
        nFail = nFail + 1;
    end
end

fprintf('\n--- Done: %d copied, %d skipped, %d failed ---\n', nOK, nSkip, nFail);
