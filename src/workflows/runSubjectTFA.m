function subjectResults = runSubjectTFA( ...
    signalData, subjectInfo, analysisSettings, outputSettings)
% runSubjectTFA Analyze one subject's loaded time-series data.
%
% Runs the full TFA workflow for one subject:
% preprocess, check Welch length, run MISO/SISO, and save outputs.

analysisSettings = normalizeAnalysisFrequencyRange(analysisSettings);

try
    preprocessedSignalData = btbPreProcessing( ...
        signalData, analysisSettings.fsTarget, analysisSettings.preprocessing);
catch errorInfo
    error('TFA:PreprocessingFailed', ...
        'PreprocessingFailed: %s', errorInfo.message);
end

map = preprocessedSignalData.map;
co2 = preprocessedSignalData.co2;
cbv = preprocessedSignalData.cbv;
fs = preprocessedSignalData.fs;
cbvBaselineCmPerSec = preprocessedSignalData.cbvBaselineCmPerSec;
cbvUnits = preprocessedSignalData.cbvUnits;

outputFolder = fullfile( ...
    outputSettings.baseOutputFolder, ...
    string(subjectInfo.subjectID));

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

[~, preflightWelchInfo] = windowSettings( ...
    analysisSettings.pwelch.windowLengthSeconds, ...
    analysisSettings.pwelch.windowOverlap, ...
    fs, ...
    length(map));

makeSubjectFigures = outputSettings.saveSubjectFigures;

subjectFigureNames = strings(0, 1);

canRunTFA = ~preflightWelchInfo.isTooShort && ...
    preflightWelchInfo.numWindows >= analysisSettings.pwelch.minimumWindows;
runStatus = initializeSubjectRunStatus( ...
    preflightWelchInfo, ...
    analysisSettings.runMISO, ...
    analysisSettings.runSISO, ...
    analysisSettings.pwelch.minimumWindows);
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

if canRunTFA
    if analysisSettings.runMISO
        try
            fullMisoResults = runMISOTFA( ...
                map, co2, cbv, fs, ...
                analysisSettings.pwelch.windowLengthSeconds, ...
                analysisSettings.pwelch.windowOverlap, ...
                analysisSettings.phase);

            misoBandAverages = computeMISOBandAverages( ...
                fullMisoResults, ...
                analysisSettings.frequencyBandEdgesHz, ...
                analysisSettings.frequencyBandNames);

            tfaResults = limitMisoResultsToFrequencyRange( ...
                fullMisoResults, analysisSettings.frequencyRangeHz);
            tfaResults.bandAverages = misoBandAverages;
        catch errorInfo
            error('TFA:MISOFailed', ...
                'MISOFailed: %s', errorInfo.message);
        end

        runStatus.misoUsedDefaultCoherenceThreshold = ...
            tfaResults.welchInfo.usesDefaultCoherenceThreshold;
        runStatus.misoCoherenceThreshold = ...
            tfaResults.welchInfo.coherenceThreshold;
        runStatus.misoCoherenceThresholdSource = ...
            string(tfaResults.welchInfo.coherenceThresholdSource);
        tfaResults.welchInfo.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
        tfaResults.welchInfo.cbvUnits = cbvUnits;
    end

    if analysisSettings.runSISO
        try
            fullSisoResults = runSISOTFA( ...
                map, co2, cbv, fs, ...
                analysisSettings.pwelch.windowLengthSeconds, ...
                analysisSettings.pwelch.windowOverlap, ...
                analysisSettings.phase);

            sisoBandAverages = computeSISOBandAverages( ...
                fullSisoResults, ...
                analysisSettings.frequencyBandEdgesHz, ...
                analysisSettings.frequencyBandNames);

            sisoResults = limitSisoResultsToFrequencyRange( ...
                fullSisoResults, analysisSettings.frequencyRangeHz);
            sisoResults.bandAverages = sisoBandAverages;
        catch errorInfo
            error('TFA:SISOFailed', ...
                'SISOFailed: %s', errorInfo.message);
        end

        runStatus.sisoUsedDefaultCoherenceThreshold = ...
            sisoResults.welchInfo.usesDefaultCoherenceThreshold;
        runStatus.sisoCoherenceThreshold = ...
            sisoResults.welchInfo.coherenceThreshold;
        runStatus.sisoCoherenceThresholdSource = ...
            string(sisoResults.welchInfo.coherenceThresholdSource);
        sisoResults.welchInfo.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
        sisoResults.welchInfo.cbvUnits = cbvUnits;

    end

    runStatus.analysisSucceeded = true;
    runStatus.runStage = "Completed";
    runStatus.statusMessage = "Completed";

    if makeSubjectFigures
        subjectFigureNames = plotSubjectResults( ...
            signalData, tfaResults, sisoResults, analysisSettings);
    end
end

if outputSettings.saveSubjectExcel
    filename = fullfile(outputFolder, outputSettings.singleSubjectExcelFileName);

    subjectOutputSettings.frequencyBandEdgesHz = ...
        analysisSettings.frequencyBandEdgesHz;
    subjectOutputSettings.frequencyBandNames = ...
        analysisSettings.frequencyBandNames;
    subjectOutputSettings.runMISO = analysisSettings.runMISO;
    subjectOutputSettings.runSISO = analysisSettings.runSISO;
    subjectOutputSettings.saveFullFrequencyData = ...
        outputSettings.saveFullFrequencyData;
    try
        saveSubjectResultsToExcel( ...
            filename, subjectInfo, runStatus, ...
            tfaResults, sisoResults, subjectOutputSettings);
    catch errorInfo
        error('TFA:ExcelSaveFailed', ...
            'ExcelSaveFailed: %s', errorInfo.message);
    end
end

if canRunTFA && makeSubjectFigures
    try
        saveSubjectFigures(outputFolder, subjectFigureNames);
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
