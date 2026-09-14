function [analysisSettings, outputSettings] = createWorkflowTestSettings( ...
    outputFolder, runMISO, runSISO)
% createWorkflowTestSettings Create non-exporting workflow test settings.

    analysisSettings = defaultTfaAnalysisSettings(["NC"; "MCI"]);
    analysisSettings.runMISO = runMISO;
    analysisSettings.runSISO = runSISO;
    analysisSettings.pwelch = createTestWelchSettings();
    analysisSettings.phase = createTestPhaseSettings("standard");
    analysisSettings.statistics.enabled = false;
    analysisSettings.statistics.numPhasePermutations = 100;
    analysisSettings.statistics.randomSeed = 1;
    analysisSettings.statistics.primaryBandNames = ["VLF"; "LF"];
    analysisSettings.plot = defaultPlotSettings("none");

    % The independent project has no legacy batch/export workflow. Keep the
    % second return value for older test call sites, but do not reach back
    % into the parent project's output settings.
    outputSettings = struct();
    outputSettings.baseOutputFolder = string(outputFolder);
    outputSettings.saveSubjectFigures = false;
    outputSettings.saveBatchFigures = false;
    outputSettings.saveExcel = false;
    outputSettings.excelStatistics = false;

end
