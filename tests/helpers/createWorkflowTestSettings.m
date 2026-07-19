function [analysisSettings, outputSettings] = createWorkflowTestSettings( ...
    outputFolder, runMISO, runSISO)
% createWorkflowTestSettings Create non-exporting workflow test settings.

    analysisSettings.runMISO = runMISO;
    analysisSettings.runSISO = runSISO;
    analysisSettings.frequencyRangeHz = [0 0.35];
    analysisSettings.frequencyBandEdgesHz = ...
        [0.005; 0.024; 0.070; 0.200; 0.350];
    analysisSettings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];
    analysisSettings.fsTarget = 4;
    analysisSettings.preprocessing.normalizeCbv = true;
    analysisSettings.preprocessing.detrendEnabled = false;
    analysisSettings.preprocessing.detrendOrder = 1;
    analysisSettings.preprocessing.meanRemovalEnabled = true;
    analysisSettings.pwelch.windowLengthSeconds = 128;
    analysisSettings.pwelch.windowOverlap = 0.5;
    analysisSettings.pwelch.minimumWindows = 3;
    analysisSettings.phase = createTestPhaseSettings("standard");
    analysisSettings.plot = defaultPlotSettings();

    outputSettings.baseOutputFolder = outputFolder;
    outputSettings.singleSubjectExcelFileName = "subject.xlsx";
    outputSettings.saveSubjectExcel = false;
    outputSettings.saveSubjectFigures = false;
    outputSettings.saveFullFrequencyData = false;

end
