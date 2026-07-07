%% Clean Start

clear; clc; close all;

projectRoot = pwd;
addpath(genpath(projectRoot));
rehash

%% Run Settings

runType = "batch";    % Use "single" or "batch"

%% Analysis Settings

% Frequency bands are the intervals between consecutive edges.
% Example: VVLF is 0.005 <= f < 0.024 Hz.
% The final band includes its upper edge.
analysisSettings.frequencyBandEdgesHz = [0.005; 0.024; 0.070; 0.200; 0.500];
analysisSettings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

% Subjects shorter than this window are skipped and written to the status
% sheet instead of being analyzed with too little data.
analysisSettings.windowLengthSeconds = 128;
analysisSettings.windowOverlap = 0.5;
analysisSettings.minimumWelchWindows = 3;

analysisSettings.figureMode = "batchSummary";    % Use "none", "summary", "all", or "batchSummary"
analysisSettings.runSISO = true;

analysisSettings.phase = defaultPhaseSettings();
analysisSettings.phase.unwrapMethod = "localWeighted";    % Use "standard" or "localWeighted"
analysisSettings.phase.localWeighted.windowSize = 11;     % Total local window; fit uses 10 neighbors after excluding target.
analysisSettings.phase.localWeighted.weightMode = "power"; % Use "linear", "power", or "exponential" coherence weighting.
analysisSettings.phase.localWeighted.weightPower = 4;     % For "power": coherence^weightPower; larger values favor high coherence more strongly.
analysisSettings.phase.localWeighted.expAlpha = 4;        % For "exponential": exp(expAlpha*(coherence-1)); larger values sharpen high-coherence dominance.
analysisSettings.phase.localWeighted.minWeight = 0.01;    % Minimum transformed weight so low-coherence points cannot become exactly zero.
analysisSettings.phase.anchor.enabled = false;
analysisSettings.phase.anchor.map.bandHz = [0.05 0.10];
analysisSettings.phase.anchor.map.targetRangeRad = [0 pi/2];
analysisSettings.phase.anchor.co2.bandHz = [0.01 0.05];
analysisSettings.phase.anchor.co2.targetRangeRad = [-pi/2 0];

if ~any(analysisSettings.figureMode == ["none", "summary", "all", "batchSummary"])
    error('figureMode must be "none", "summary", "all", or "batchSummary".');
end

if ~any(analysisSettings.phase.unwrapMethod == ["standard", "localWeighted"])
    error('phase.unwrapMethod must be "standard" or "localWeighted".');
end

%% Output Settings

outputSettings.baseOutputFolder = "/Users/amoghn/Desktop/TFA Results test Updated algo";
outputSettings.singleSubjectExcelFileName = "subject_tfa_results.xlsx";
outputSettings.batchSummaryExcelFileName = "batch_tfa_summary.xlsx";

outputSettings.saveSingleSubjectExcel = true;
outputSettings.saveBatchSummaryExcel = true;
outputSettings.saveFigures = true;
outputSettings.saveFullFrequencyData = true;

%% Batch Subject Selection

batchSettings.dataFolder = "/Users/amoghn/Downloads/ieem_data";
batchSettings.groupsToRun = ["MCI"; "NC"];    % Use "MCI", "NC", or both
batchSettings.batchRunMode = "firstN";        % Use "single", "firstN", or "all"
batchSettings.singleSubjectID = "101";
batchSettings.numSubjectsPerGroup = 3;
batchSettings.previewOnly = false;

%% Single Subject Settings

subjectInfo.subjectID = "503";
subjectInfo.group = "MCI";       % Use "MCI" or "NC"
subjectInfo.session = "baseline";
subjectInfo.sourceFile = "/Users/amoghn/Downloads/ieem_data/NC/503_baseline.xlsx";

%% Run TFA

if runType == "single"

    subjectResults = runSingleSubjectTFA( ...
        subjectInfo, analysisSettings, outputSettings);

elseif runType == "batch"

    subjectList = findIEEMSubjects( ...
        batchSettings.dataFolder, ...
        batchSettings.groupsToRun, ...
        batchSettings.batchRunMode, ...
        batchSettings.singleSubjectID, ...
        batchSettings.numSubjectsPerGroup);

    if batchSettings.previewOnly
        disp(subjectList)
        return
    end

    batchResults = runBatchTFA( ...
        subjectList, analysisSettings, outputSettings, batchSettings);

else

    error('runType must be "single" or "batch".');

end
