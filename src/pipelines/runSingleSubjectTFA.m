function subjectResults = runSingleSubjectTFA(subjectInfo, analysisSettings, outputSettings)
% runSingleSubjectTFA
%
% Runs the full TFA workflow for one subject:
% load data, preprocess, check Welch length, run MISO/SISO, save outputs.

try
    signalData = loadData(subjectInfo.sourceFile);
catch errorInfo
    error('TFA:LoadDataFailed', ...
        'LoadDataFailed: %s', errorInfo.message);
end

try
    preprocessedSignalData = btbPreProcessing(signalData);
catch errorInfo
    error('TFA:PreprocessingFailed', ...
        'PreprocessingFailed: %s', errorInfo.message);
end

map = preprocessedSignalData.map;
co2 = preprocessedSignalData.co2;
cbv = preprocessedSignalData.cbv;
fs = preprocessedSignalData.fs;
t = preprocessedSignalData.t;
cbvBaselineCmPerSec = preprocessedSignalData.cbvBaselineCmPerSec;
cbvUnits = preprocessedSignalData.cbvUnits;

outputFolder = fullfile( ...
    outputSettings.baseOutputFolder, ...
    string(subjectInfo.subjectID));

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

[~, preflightWelchInfo] = windowSettings( ...
    analysisSettings.windowLengthSeconds, ...
    analysisSettings.windowOverlap, ...
    fs, ...
    length(map));

if ~isfield(analysisSettings, 'minimumWelchWindows')
    analysisSettings.minimumWelchWindows = 1;
end

if ~isfield(analysisSettings, 'phaseUnwrapMethod')
    analysisSettings.phaseUnwrapMethod = "standard";
end

if ~isfield(analysisSettings, 'phase')
    analysisSettings.phase = normalizePhaseSettings(analysisSettings.phaseUnwrapMethod);
else
    analysisSettings.phase = normalizePhaseSettings(analysisSettings.phase);
end

subjectFigureMode = analysisSettings.figureMode;

if subjectFigureMode == "batchSummary"
    subjectFigureMode = "none";
end

canRunTFA = ~preflightWelchInfo.isTooShort && ...
    preflightWelchInfo.numWindows >= analysisSettings.minimumWelchWindows;
runStatus = initializeSubjectRunStatus( ...
    preflightWelchInfo, ...
    analysisSettings.runSISO, ...
    analysisSettings.minimumWelchWindows);
runStatus.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
runStatus.cbvUnits = cbvUnits;

tfaResults = [];
sisoResults = [];

fprintf("Subject %s: %.1f seconds, %d Welch windows.\n", ...
    string(subjectInfo.subjectID), ...
    preflightWelchInfo.signalDurationSeconds, ...
    preflightWelchInfo.numWindows);

if ~canRunTFA
    warning("Skipping TFA: %s", runStatus.statusMessage);
end

if canRunTFA && subjectFigureMode ~= "none"
    visualizeTimeSeries(t, map, co2, cbv)
end

if canRunTFA
    try
        tfaResults = runMISOTFA( ...
            map, co2, cbv, fs, ...
            analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, ...
            analysisSettings.windowLengthSeconds, ...
            analysisSettings.windowOverlap, ...
            subjectFigureMode, ...
            analysisSettings.phase);
    catch errorInfo
        error('TFA:MISOFailed', ...
            'MISOFailed: %s', errorInfo.message);
    end

    runStatus.analysisSucceeded = true;
    runStatus.runStage = "Completed";
    runStatus.statusMessage = "Completed";
    runStatus.misoUsedDefaultCoherenceThreshold = ...
        tfaResults.welchInfo.usesDefaultCoherenceThreshold;
    runStatus.misoCoherenceThreshold = ...
        tfaResults.welchInfo.coherenceThreshold;
    tfaResults.welchInfo.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
    tfaResults.welchInfo.cbvUnits = cbvUnits;

    if analysisSettings.runSISO
        try
            sisoResults = runSISOTFA( ...
                map, co2, cbv, fs, ...
                analysisSettings.frequencyBandEdgesHz, ...
                analysisSettings.frequencyBandNames, ...
                analysisSettings.windowLengthSeconds, ...
                analysisSettings.windowOverlap, ...
                subjectFigureMode, ...
                analysisSettings.phase);
        catch errorInfo
            error('TFA:SISOFailed', ...
                'SISOFailed: %s', errorInfo.message);
        end

        runStatus.sisoUsedDefaultCoherenceThreshold = ...
            sisoResults.welchInfo.usesDefaultCoherenceThreshold;
        runStatus.sisoCoherenceThreshold = ...
            sisoResults.welchInfo.coherenceThreshold;
        sisoResults.welchInfo.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
        sisoResults.welchInfo.cbvUnits = cbvUnits;
    end
end

if outputSettings.saveSingleSubjectExcel
    filename = fullfile(outputFolder, outputSettings.singleSubjectExcelFileName);

    subjectOutputSettings.frequencyBandEdgesHz = ...
        analysisSettings.frequencyBandEdgesHz;
    subjectOutputSettings.frequencyBandNames = ...
        analysisSettings.frequencyBandNames;
    subjectOutputSettings.runSISO = analysisSettings.runSISO;
    subjectOutputSettings.saveFullFrequencyData = ...
        outputSettings.saveFullFrequencyData;
    subjectOutputSettings.phaseUnwrapMethod = ...
        analysisSettings.phase.unwrapMethod;

    try
        saveSubjectOutputs( ...
            filename, subjectInfo, runStatus, ...
            tfaResults, sisoResults, subjectOutputSettings);
    catch errorInfo
        error('TFA:ExcelSaveFailed', ...
            'ExcelSaveFailed: %s', errorInfo.message);
    end
end

if canRunTFA && outputSettings.saveFigures && subjectFigureMode ~= "none"
    try
        saveSubjectFigures(outputFolder, subjectFigureMode);
    catch errorInfo
        error('TFA:FigureSaveFailed', ...
            'FigureSaveFailed: %s', errorInfo.message);
    end
end

subjectResults.subjectInfo = subjectInfo;
subjectResults.runStatus = runStatus;
subjectResults.tfaResults = tfaResults;
subjectResults.sisoResults = sisoResults;
subjectResults.outputFolder = outputFolder;

end
