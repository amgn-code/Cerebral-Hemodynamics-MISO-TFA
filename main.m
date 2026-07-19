%% Clean Start

clear; clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectRoot, "src")));

%% 1. Run Mode

runType = "test";    % Use "single", "batch", or "test"

%% 2. Input Data

% Single-subject input
subjectInfo.subjectID = "105";
subjectInfo.group = "MCI";
subjectInfo.session = "baseline";
subjectInfo.sourceFile = ...
    "/Users/amoghn/Downloads/ieem_data/MCI/105_baseline.xlsx";

% Batch input
batchSettings.dataFolder = "/Users/amoghn/Downloads/ieem_data";
batchSettings.groupsToRun = ["MCI"; "NC"; "LC"];
batchSettings.numSubjectsPerGroup = Inf;
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
outputSettings.saveBatchFigures = true;
batchSettings.numSubjectFiguresPerGroup = 1;    % Number, "none", or "all"

%% 9. Excel Export

outputSettings.baseOutputFolder = ...
    "/Users/amoghn/Desktop/TFA Results test Updated plotting excel11";
outputSettings.singleSubjectExcelFileName = "subject_tfa_results.xlsx";
outputSettings.batchSummaryExcelFileName = "batch_tfa_summary.xlsx";
outputSettings.saveSubjectExcel = true;
outputSettings.saveBatchExcel = true;
outputSettings.saveFullFrequencyData = true;

%% Run TFA

if ~analysisSettings.runMISO && ~analysisSettings.runSISO
    error("Select at least one model by enabling runMISO or runSISO.");
end

if ~any(analysisSettings.phase.unwrapMethod == ["standard", "custom"])
    error('phase.unwrapMethod must be "standard" or "custom".');
end

if ~any(analysisSettings.plot.transferFunctionStyle == ["stem", "line"])
    error('plot.transferFunctionStyle must be "stem" or "line".');
end

analysisSettings = normalizeAnalysisFrequencyRange(analysisSettings);

fprintf("\nRun type: %s | MISO: %s | SISO: %s\n", ...
    runType, string(analysisSettings.runMISO), ...
    string(analysisSettings.runSISO));
fprintf("Frequency range: %.3f-%.3f Hz | Welch window: %.1f s\n\n", ...
    analysisSettings.frequencyRangeHz(1), ...
    analysisSettings.frequencyRangeHz(2), ...
    analysisSettings.pwelch.windowLengthSeconds);

if runType == "single"
    subjectResults = runSingleSubjectTFA( ...
        subjectInfo, analysisSettings, outputSettings);

elseif runType == "batch"
    subjectList = findIEEMSubjects( ...
        batchSettings.dataFolder, ...
        batchSettings.groupsToRun);

    if batchSettings.previewOnly
        previewTable = previewBatchTFA(subjectList, analysisSettings);
        disp(previewTable)
        return
    end

    batchResults = runBatchTFA( ...
        subjectList, analysisSettings, outputSettings, batchSettings);

elseif runType == "test"
    testResults = runTestTFA(analysisSettings, outputSettings);

else
    error('runType must be "single", "batch", or "test".');
end
