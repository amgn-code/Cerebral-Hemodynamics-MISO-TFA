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

canRunTFA = ~preflightWelchInfo.isTooShort;
runStatus = initializeSubjectRunStatus( ...
    preflightWelchInfo, ...
    analysisSettings.runSISO);

tfaResults = [];
sisoResults = [];

fprintf("Subject %s: %.1f seconds, %d Welch windows.\n", ...
    string(subjectInfo.subjectID), ...
    preflightWelchInfo.signalDurationSeconds, ...
    preflightWelchInfo.numWindows);

if ~canRunTFA
    warning("Skipping TFA because signal is shorter than the Welch window.");
end

if canRunTFA && analysisSettings.figureMode ~= "none"
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
            analysisSettings.figureMode);
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

    if analysisSettings.runSISO
        try
            sisoResults = runSISOTFA( ...
                map, co2, cbv, fs, ...
                analysisSettings.frequencyBandEdgesHz, ...
                analysisSettings.frequencyBandNames, ...
                analysisSettings.windowLengthSeconds, ...
                analysisSettings.windowOverlap, ...
                analysisSettings.figureMode);
        catch errorInfo
            error('TFA:SISOFailed', ...
                'SISOFailed: %s', errorInfo.message);
        end

        runStatus.sisoUsedDefaultCoherenceThreshold = ...
            sisoResults.welchInfo.usesDefaultCoherenceThreshold;
        runStatus.sisoCoherenceThreshold = ...
            sisoResults.welchInfo.coherenceThreshold;
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

    try
        saveSubjectOutputs( ...
            filename, subjectInfo, runStatus, ...
            tfaResults, sisoResults, subjectOutputSettings);
    catch errorInfo
        error('TFA:ExcelSaveFailed', ...
            'ExcelSaveFailed: %s', errorInfo.message);
    end
end

if canRunTFA && outputSettings.saveFigures
    try
        saveSubjectFigures(outputFolder, analysisSettings.figureMode);
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
