function subjectResults = analyzeSubjectTFA( ...
    signalData, subjectInfo, analysisSettings, outputSettings)
% analyzeSubjectTFA Analyze one subject's loaded time-series data.
%
% Preprocesses the signals, estimates their shared spectra, runs the
% enabled models, and creates the requested subject outputs.

    runStatus = initializeSubjectRunStatus(analysisSettings);

    %% Preprocess the Loaded Signals

    try
        preprocessedSignalData = preprocessTfaSignals( ...
            signalData, analysisSettings.fsTarget, ...
            analysisSettings.preprocessing);
    catch errorInfo
        error( ...
            'TFA:PreprocessingFailed', ...
            'PreprocessingFailed: %s', errorInfo.message);
    end

    map = preprocessedSignalData.map;
    co2 = preprocessedSignalData.co2;
    cbv = preprocessedSignalData.cbv;
    samplingFrequencyHz = preprocessedSignalData.fs;
    cbvBaselineCmPerSec = ...
        preprocessedSignalData.cbvBaselineCmPerSec;
    cbvUnits = preprocessedSignalData.cbvUnits;

    subjectFolderName = upper(string(subjectInfo.group)) + "_" + ...
        string(subjectInfo.subjectID);
    outputFolder = fullfile( ...
        outputSettings.baseOutputFolder, subjectFolderName);

    %% Check Whether the Recording Has Enough Welch Windows

    [~, preflightWelchInfo] = getWelchWindowSettings( ...
        analysisSettings.pwelch, samplingFrequencyHz, length(map));

    runStatus.isTooShortForWelch = preflightWelchInfo.isTooShort;
    runStatus.numWelchWindows = preflightWelchInfo.numWindows;
    runStatus.signalDurationSeconds = ...
        preflightWelchInfo.signalDurationSeconds;

    if preflightWelchInfo.isTooShort
        runStatus.runStage = "TooShortForWelch";
        runStatus.statusMessage = ...
            "Skipped: signal shorter than Welch window";
    elseif ~preflightWelchInfo.isReadyForTFA
        runStatus.runStage = "InsufficientWelchWindows";
        runStatus.statusMessage = ...
            "Skipped: fewer than minimum Welch windows";
    end

    misoResults = [];
    sisoResults = [];
    subjectFigureNames = strings(0, 1);
    subjectFigureFiles = strings(0, 1);

    fprintf("Subject %s: %.1f seconds, %d Welch windows.\n", ...
        string(subjectInfo.subjectID), ...
        preflightWelchInfo.signalDurationSeconds, ...
        preflightWelchInfo.numWindows);

    if ~preflightWelchInfo.isReadyForTFA
        warning("Skipping TFA: %s", runStatus.statusMessage);
    end

    %% Estimate the Shared Spectra and Run the Enabled Models

    if preflightWelchInfo.isReadyForTFA
        try
            spectra = estimateWelchSpectra( ...
                map, co2, cbv, samplingFrequencyHz, ...
                analysisSettings.pwelch);
        catch errorInfo
            error( ...
                'TFA:WelchFailed', ...
                'WelchFailed: %s', errorInfo.message);
        end

        if analysisSettings.runMISO
            try
                fullMisoResults = runMISOTFA( ...
                    spectra, analysisSettings.phase);
                misoResults = limitResultsToFrequencyRange( ...
                    fullMisoResults, "miso", ...
                    analysisSettings.frequencyRangeHz);
            catch errorInfo
                error( ...
                    'TFA:MISOFailed', ...
                    'MISOFailed: %s', errorInfo.message);
            end

            misoResults.welchInfo.cbvBaselineCmPerSec = ...
                cbvBaselineCmPerSec;
            misoResults.welchInfo.cbvUnits = cbvUnits;
        end

        if analysisSettings.runSISO
            try
                fullSisoResults = runSISOTFA( ...
                    spectra, analysisSettings.phase);
                sisoResults = limitResultsToFrequencyRange( ...
                    fullSisoResults, "siso", ...
                    analysisSettings.frequencyRangeHz);
            catch errorInfo
                error( ...
                    'TFA:SISOFailed', ...
                    'SISOFailed: %s', errorInfo.message);
            end

            sisoResults.welchInfo.cbvBaselineCmPerSec = ...
                cbvBaselineCmPerSec;
            sisoResults.welchInfo.cbvUnits = cbvUnits;
        end

        runStatus.analysisSucceeded = true;
        runStatus.runStage = "Completed";
        runStatus.statusMessage = "Completed";
    end

    %% Create Subject Figures Without Invalidating the Analysis

    if runStatus.analysisSucceeded && outputSettings.saveSubjectFigures
        try
            subjectFigureNames = plotSubjectResults( ...
                signalData, misoResults, sisoResults, analysisSettings);

            if isempty(subjectFigureNames)
                runStatus.figureStatusMessage = "No figures selected";
            else
                if ~exist(outputFolder, "dir")
                    mkdir(outputFolder);
                end

                subjectFigureFiles = saveSubjectFigures( ...
                    outputFolder, subjectFigureNames);
                runStatus.subjectFiguresSaved = true;
                runStatus.figureStatusMessage = "Saved";
            end
        catch errorInfo
            runStatus.subjectFiguresSaved = false;
            runStatus.figureStatusMessage = ...
                "Figure output failed: " + string(errorInfo.message);
            warning( ...
                'TFA:SubjectFigureOutputFailed', ...
                'Subject %s figures were not saved: %s', ...
                string(subjectInfo.subjectID), errorInfo.message);
        end
    end

    %% Store the Subject Results

    subjectResults.subjectInfo = subjectInfo;
    subjectResults.runStatus = runStatus;
    subjectResults.misoResults = misoResults;
    subjectResults.sisoResults = sisoResults;
    subjectResults.outputFolder = outputFolder;
    subjectResults.subjectFigureNames = subjectFigureNames;
    subjectResults.subjectFigureFiles = subjectFigureFiles;

end
