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
    analysisSettings.pwelch = createTestWelchSettings();
    analysisSettings.phase = createTestPhaseSettings("standard");
    analysisSettings.plot = defaultPlotSettings();

    outputSettings.baseOutputFolder = outputFolder;
    outputSettings.saveSubjectFigures = false;
    outputSettings.saveBatchFigures = false;
    outputSettings.saveExcel = false;
    outputSettings.excelFileName = "tfa_results.xlsx";

    outputSettings.excelMetrics.signals.mapPower = false;
    outputSettings.excelMetrics.signals.co2Power = false;
    outputSettings.excelMetrics.signals.cbvPower = false;
    outputSettings.excelMetrics.inputs.coherence = false;
    outputSettings.excelMetrics.inputs.phaseWrapped = false;
    outputSettings.excelMetrics.inputs.phaseUnwrapped = false;

    outputSettings.excelMetrics.miso.mapGain = false;
    outputSettings.excelMetrics.miso.mapPhaseWrapped = false;
    outputSettings.excelMetrics.miso.mapPhaseUnwrapped = false;
    outputSettings.excelMetrics.miso.co2Gain = false;
    outputSettings.excelMetrics.miso.co2PhaseWrapped = false;
    outputSettings.excelMetrics.miso.co2PhaseUnwrapped = false;
    outputSettings.excelMetrics.miso.multipleCoherence = false;
    outputSettings.excelMetrics.miso.mapPartialCoherence = false;
    outputSettings.excelMetrics.miso.co2PartialCoherence = false;
    outputSettings.excelMetrics.miso.unexplainedFraction = false;
    outputSettings.excelMetrics.miso.residualPower = false;
    outputSettings.excelMetrics.miso.conditionNumber = false;

    outputSettings.excelMetrics.siso.mapGain = false;
    outputSettings.excelMetrics.siso.mapPhaseWrapped = false;
    outputSettings.excelMetrics.siso.mapPhaseUnwrapped = false;
    outputSettings.excelMetrics.siso.mapCoherence = false;
    outputSettings.excelMetrics.siso.mapUnexplainedFraction = false;
    outputSettings.excelMetrics.siso.mapResidualPower = false;
    outputSettings.excelMetrics.siso.co2Gain = false;
    outputSettings.excelMetrics.siso.co2PhaseWrapped = false;
    outputSettings.excelMetrics.siso.co2PhaseUnwrapped = false;
    outputSettings.excelMetrics.siso.co2Coherence = false;
    outputSettings.excelMetrics.siso.co2UnexplainedFraction = false;
    outputSettings.excelMetrics.siso.co2ResidualPower = false;

end
