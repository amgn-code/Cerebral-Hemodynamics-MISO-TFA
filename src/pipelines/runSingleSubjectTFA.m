function subjectResults = runSingleSubjectTFA(subjectInfo, analysisSettings, outputSettings)
% runSingleSubjectTFA
%
% Runs the full TFA workflow for one subject:
% load data, preprocess, check Welch length, run MISO/SISO, save outputs.

analysisSettings = normalizeAnalysisFrequencyRange(analysisSettings);

try
    signalData = loadData(subjectInfo.sourceFile);
catch errorInfo
    error('TFA:LoadDataFailed', ...
        'LoadDataFailed: %s', errorInfo.message);
end

try
    if ~isfield(analysisSettings, 'preprocessing')
        analysisSettings.preprocessing = defaultPreprocessingSettings();
    else
        analysisSettings.preprocessing = normalizePreprocessingSettings( ...
            analysisSettings.preprocessing);
    end

    preprocessedSignalData = btbPreProcessing( ...
        signalData, analysisSettings.preprocessing);
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

if ~isfield(analysisSettings, 'plot')
    analysisSettings.plot = defaultPlotSettings();
end

if ~isfield(analysisSettings, 'misoRegularization')
    analysisSettings.misoRegularization = defaultMisoRegularizationSettings();
else
    analysisSettings.misoRegularization = normalizeMisoRegularizationSettings( ...
        analysisSettings.misoRegularization);
end

makeSubjectFigures = shouldMakeSubjectFigures(outputSettings);
subjectFigureMode = "none";

if makeSubjectFigures
    subjectFigureMode = "summary";
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
    if isfield(preprocessedSignalData, 'mapPlot')
        visualizeTimeSeries( ...
            t, ...
            preprocessedSignalData.mapPlot, ...
            preprocessedSignalData.co2Plot, ...
            preprocessedSignalData.cbvPlot, ...
            preprocessedSignalData.cbvPlotUnits, ...
            analysisSettings.plot)
    else
        visualizeTimeSeries(t, map, co2, cbv, cbvUnits, analysisSettings.plot)
    end

    visualizeProcessedTimeSeries( ...
        t, map, co2, cbv, cbvUnits, analysisSettings.plot)
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
            analysisSettings.phase, ...
            analysisSettings.plot, ...
            analysisSettings.misoRegularization);
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
    runStatus.misoCoherenceThresholdSource = ...
        string(tfaResults.welchInfo.coherenceThresholdSource);
    tfaResults.welchInfo.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
    tfaResults.welchInfo.cbvUnits = cbvUnits;

    if subjectFigureMode ~= "none"
        visualizePowerSpectra( ...
            tfaResults.f, ...
            tfaResults.mapPowerSmooth, ...
            tfaResults.co2PowerSmooth, ...
            tfaResults.cbvPowerSmooth, ...
            analysisSettings.plot);
    end

    if analysisSettings.runSISO
        try
            sisoResults = runSISOTFA( ...
                map, co2, cbv, fs, ...
                analysisSettings.frequencyBandEdgesHz, ...
                analysisSettings.frequencyBandNames, ...
                analysisSettings.windowLengthSeconds, ...
                analysisSettings.windowOverlap, ...
                subjectFigureMode, ...
                analysisSettings.phase, ...
                analysisSettings.plot);
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
    subjectOutputSettings.preprocessing = analysisSettings.preprocessing;

    try
        saveSubjectOutputs( ...
            filename, subjectInfo, runStatus, ...
            tfaResults, sisoResults, subjectOutputSettings);
    catch errorInfo
        error('TFA:ExcelSaveFailed', ...
            'ExcelSaveFailed: %s', errorInfo.message);
    end
end

if canRunTFA && makeSubjectFigures
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


function makeFigures = shouldMakeSubjectFigures(outputSettings)

if isfield(outputSettings, 'saveIndividualSubjectFigures')
    makeFigures = logical(outputSettings.saveIndividualSubjectFigures);
    return
end

if ~isfield(outputSettings, 'numIndividualPlotsPerGroup')
    makeFigures = false;
    return
end

plotCount = outputSettings.numIndividualPlotsPerGroup;

if isnumeric(plotCount)
    makeFigures = plotCount > 0;
else
    plotCount = lower(string(plotCount));
    makeFigures = plotCount == "all" || ...
        (plotCount ~= "none" && str2double(plotCount) > 0);
end

end
