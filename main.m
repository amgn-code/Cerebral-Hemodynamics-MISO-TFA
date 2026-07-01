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

analysisSettings.figureMode = "summary";    % Use "none", "summary", or "all"
analysisSettings.runSISO = true;

if ~any(analysisSettings.figureMode == ["none", "summary", "all"])
    error('figureMode must be "none", "summary", or "all".');
end

%% Output Settings

outputSettings.baseOutputFolder = "/Users/amoghn/Desktop/TFA Results";
outputSettings.singleSubjectExcelFileName = "subject_tfa_results.xlsx";
outputSettings.batchSummaryExcelFileName = "batch_tfa_summary.xlsx";

outputSettings.saveSingleSubjectExcel = true;
outputSettings.saveBatchSummaryExcel = true;
outputSettings.saveFigures = true;
outputSettings.saveFullFrequencyData = false;

%% Batch Subject Selection

batchSettings.dataFolder = "/Users/amoghn/Downloads/ieem_data";
batchSettings.groupsToRun = ["MCI"; "NC"];    % Use "MCI", "NC", or both
batchSettings.batchRunMode = "firstN";        % Use "single", "firstN", or "all"
batchSettings.singleSubjectID = "528";
batchSettings.numSubjectsPerGroup = 5;
batchSettings.previewOnly = false;

%% Single Subject Settings

subjectInfo.subjectID = "547";
subjectInfo.group = "MCI";       % Use "MCI" or "NC"
subjectInfo.session = "baseline_1";
subjectInfo.sourceFile = "/Users/amoghn/Downloads/547_baseline_1.xlsx";

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
