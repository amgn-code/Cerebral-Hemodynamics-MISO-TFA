%% Clean Start

clearvars; clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectRoot, "src")));

%% 1. Run Mode

runType = "batch";    % Use "single", "batch", or "synthetic"

%% 2. Input Data

% Single-subject input
subjectInfo.subjectID = "105";
subjectInfo.group = "MCI";
subjectInfo.sourceFile = ...
    "/Users/amoghn/Downloads/ieem_data/MCI/105_baseline.xlsx";

% Batch input
batchSettings.dataFolder = "/Users/amoghn/Downloads/ieem_data";
batchSettings.groupsToRun = ["NC"; "MCI"];   % Example: ["MCI"; "NC"; "LC"]
batchSettings.targetSuccessfulSubjectsPerGroup = Inf;
batchSettings.previewOnly = false;

%% 3. Models

analysisSettings.runMISO = true;
analysisSettings.runSISO = true;

%% 4. Frequency Configuration

% Results and figures are limited to this frequency range.
analysisSettings.frequencyRangeHz = [0 0.35];

% Frequency bands are the intervals between consecutive edges.
% The final band includes its upper edge.
analysisSettings.frequencyBandEdgesHz = ...
    [0.005; 0.024; 0.070; 0.200; 0.350];
analysisSettings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

%% 5. Preprocessing

analysisSettings.fsTarget = 4;
analysisSettings.preprocessing.normalizeCbv = true;
analysisSettings.preprocessing.detrendEnabled = false;
analysisSettings.preprocessing.detrendOrder = 1;
analysisSettings.preprocessing.meanRemovalEnabled = true;

%% 6. Welch Spectral Analysis

analysisSettings.pwelch.windowLengthSeconds = 128;
analysisSettings.pwelch.windowOverlap = 0.5;
analysisSettings.pwelch.minimumWindows = 3;
% Apply the same frequency-domain smoothing to every auto- and cross-spectrum.
analysisSettings.pwelch.smoothingEnabled = true;
analysisSettings.pwelch.smoothingKernel = [0.25 0.50 0.25];

%% 7. Phase

analysisSettings.phase.unwrapMethod = "standard";    % "standard" or "custom"
analysisSettings.phase.custom.windowSize = 11;
analysisSettings.phase.custom.numPasses = 3;
analysisSettings.phase.custom.useCoherenceWeights = true;
analysisSettings.phase.custom.weightMode = "power";
analysisSettings.phase.custom.weightPower = 4;
analysisSettings.phase.custom.expAlpha = 4;
analysisSettings.phase.custom.minWeight = 0.01;

%% 8. Figures

analysisSettings.plot = defaultPlotSettings();
analysisSettings.plot.transferFunctionStyle = "stem";    % "stem" or "line"
analysisSettings.plot.colors.co2Coherence = [0.9290 0.4940 0.1250];
analysisSettings.plot.showSisoCoherenceReference = true;

% Each Boolean controls one complete figure.
analysisSettings.plot.show.overview = true;
analysisSettings.plot.show.miso.map = true;
analysisSettings.plot.show.miso.co2 = true;
analysisSettings.plot.show.siso.map = true;
analysisSettings.plot.show.siso.co2 = true;
analysisSettings.plot.show.misoPartitioned.map = true;
analysisSettings.plot.show.misoPartitioned.co2 = true;
analysisSettings.plot.show.sisoPartitioned.map = true;
analysisSettings.plot.show.sisoPartitioned.co2 = true;

outputSettings.saveSubjectFigures = true;
batchSettings.numSubjectFiguresPerGroup = "all";    % Number, "none", or "all"
outputSettings.saveBatchFigures = true;

%% 9. Excel Export

outputSettings.baseOutputFolder = ...
    "/Users/amoghn/Desktop/TFA Results New Latest";
outputSettings.saveExcel = true;
outputSettings.excelFileName = "tfa_results.xlsx";

% Signal and input metrics shared by MISO and SISO
outputSettings.excelMetrics.signals.mapPower = true;
outputSettings.excelMetrics.signals.co2Power = true;
outputSettings.excelMetrics.signals.cbvPower = true;
outputSettings.excelMetrics.inputs.coherence = true;
outputSettings.excelMetrics.inputs.phaseWrapped = true;
outputSettings.excelMetrics.inputs.phaseUnwrapped = true;

% MISO metrics
outputSettings.excelMetrics.miso.mapGain = true;
outputSettings.excelMetrics.miso.mapPhaseWrapped = true;
outputSettings.excelMetrics.miso.mapPhaseUnwrapped = true;
outputSettings.excelMetrics.miso.co2Gain = true;
outputSettings.excelMetrics.miso.co2PhaseWrapped = true;
outputSettings.excelMetrics.miso.co2PhaseUnwrapped = true;
outputSettings.excelMetrics.miso.multipleCoherence = true;
outputSettings.excelMetrics.miso.mapPartialCoherence = true;
outputSettings.excelMetrics.miso.co2PartialCoherence = true;
outputSettings.excelMetrics.miso.unexplainedFraction = true;
outputSettings.excelMetrics.miso.residualPower = true;
outputSettings.excelMetrics.miso.conditionNumber = true;

% SISO metrics
outputSettings.excelMetrics.siso.mapGain = true;
outputSettings.excelMetrics.siso.mapPhaseWrapped = true;
outputSettings.excelMetrics.siso.mapPhaseUnwrapped = true;
outputSettings.excelMetrics.siso.mapCoherence = true;
outputSettings.excelMetrics.siso.mapUnexplainedFraction = true;
outputSettings.excelMetrics.siso.mapResidualPower = true;
outputSettings.excelMetrics.siso.co2Gain = true;
outputSettings.excelMetrics.siso.co2PhaseWrapped = true;
outputSettings.excelMetrics.siso.co2PhaseUnwrapped = true;
outputSettings.excelMetrics.siso.co2Coherence = true;
outputSettings.excelMetrics.siso.co2UnexplainedFraction = true;
outputSettings.excelMetrics.siso.co2ResidualPower = true;

%% Run TFA

fprintf("\nRun type: %s | MISO: %s | SISO: %s\n", ...
    runType, string(analysisSettings.runMISO), ...
    string(analysisSettings.runSISO));
fprintf("Frequency range: %.3f-%.3f Hz | Welch window: %.1f s\n\n", ...
    analysisSettings.frequencyRangeHz(1), ...
    analysisSettings.frequencyRangeHz(2), ...
    analysisSettings.pwelch.windowLengthSeconds);

runResults = runTFA( ...
    runType, subjectInfo, batchSettings, analysisSettings, outputSettings);

if isfield(runResults, "previewTable")
    disp(runResults.previewTable)
end
