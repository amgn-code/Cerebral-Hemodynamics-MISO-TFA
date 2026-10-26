function analysisResults = analyzeTfaSignals(signalData, analysisSettings)
% analyzeTfaSignals Run the shared numerical TFA workflow for one recording.
%
% This function preprocesses MAP, CO2, and CBFV, checks recording length,
% estimates one shared set of Welch spectra, and runs the requested models.
% It does not create figures, choose output folders, or write files.

    analysisSettings = validateTfaSettings(analysisSettings);
    runStatus = initializeSubjectRunStatus(analysisSettings);

    %% Preprocess the Recording

    try
        processed = preprocessTfaSignals( ...
            signalData, analysisSettings.fsTarget, ...
            analysisSettings.preprocessing);
    catch errorInfo
        error( ...
            "TFA:PreprocessingFailed", ...
            "PreprocessingFailed: %s", errorInfo.message);
    end

    map = processed.map;
    co2 = processed.co2;
    cbv = processed.cbv;
    samplingFrequencyHz = processed.fs;

    %% Check Recording Length

    [~, welchInfo] = getWelchWindowSettings( ...
        analysisSettings.pwelch, samplingFrequencyHz, numel(map));

    originalSignalLength = floor( ...
        (processed.co2Startup.originalEndTimeSeconds - ...
         processed.co2Startup.originalStartTimeSeconds) * ...
        samplingFrequencyHz) + 1;
    [~, originalWelchInfo] = getWelchWindowSettings( ...
        analysisSettings.pwelch, samplingFrequencyHz, ...
        originalSignalLength);
    [~, beforeAlignmentWelchInfo] = getWelchWindowSettings( ...
        analysisSettings.pwelch, samplingFrequencyHz, ...
        processed.co2Alignment.inputNumSamples);

    runStatus.isTooShortForWelch = welchInfo.isTooShort;
    runStatus.numWelchWindows = welchInfo.numWindows;
    runStatus.signalDurationSeconds = welchInfo.signalDurationSeconds;
    runStatus.co2StartupRemovedSeconds = ...
        processed.co2Startup.removedDurationSeconds;
    runStatus.co2DelayCorrectionSeconds = ...
        processed.co2Alignment.appliedDelayCorrectionSeconds;

    startupMadeRecordingTooShort = ...
        originalWelchInfo.isReadyForTFA && ...
        ~beforeAlignmentWelchInfo.isReadyForTFA && ...
        processed.co2Startup.removedDurationSeconds > 0;
    alignmentMadeRecordingTooShort = ...
        beforeAlignmentWelchInfo.isReadyForTFA && ...
        ~welchInfo.isReadyForTFA && ...
        processed.co2Alignment.trimmedSamples > 0;

    if startupMadeRecordingTooShort
        runStatus.runStage = "LateCO2Startup";
        runStatus.statusMessage = ...
            "Skipped: CO2 stabilized too late for the required Welch windows";
    elseif alignmentMadeRecordingTooShort
        runStatus.runStage = "CO2AlignmentTooShort";
        runStatus.statusMessage = ...
            "Skipped: CO2 delay correction left too few Welch windows";
    elseif welchInfo.isTooShort
        runStatus.runStage = "TooShortForWelch";
        runStatus.statusMessage = ...
            "Skipped: signal shorter than Welch window";
    elseif ~welchInfo.isReadyForTFA
        runStatus.runStage = "InsufficientWelchWindows";
        runStatus.statusMessage = ...
            "Skipped: fewer than minimum Welch windows";
    end

    misoResults = [];
    sisoResults = [];
    analysisInput = struct();

    %% Estimate Shared Spectra and Run the Requested Models

    if welchInfo.isReadyForTFA
        try
            spectra = estimateWelchSpectra( ...
                map, co2, cbv, samplingFrequencyHz, ...
                analysisSettings.pwelch);
        catch errorInfo
            error( ...
                "TFA:WelchFailed", ...
                "WelchFailed: %s", errorInfo.message);
        end

        if analysisSettings.runMISO
            try
                fullMisoResults = runMISOTFA( ...
                    spectra, analysisSettings.phase, ...
                    analysisSettings.misoSolver);
                misoResults = limitResultsToFrequencyRange( ...
                    fullMisoResults, "miso", ...
                    analysisSettings.frequencyRangeHz);
            catch errorInfo
                error( ...
                    "TFA:MISOFailed", ...
                    "MISOFailed: %s", errorInfo.message);
            end

            misoResults.welchInfo.cbvBaselineCmPerSec = ...
                processed.cbvBaselineCmPerSec;
            misoResults.welchInfo.cbvUnits = processed.cbvUnits;
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
                    "TFA:SISOFailed", ...
                    "SISOFailed: %s", errorInfo.message);
            end

            sisoResults.welchInfo.cbvBaselineCmPerSec = ...
                processed.cbvBaselineCmPerSec;
            sisoResults.welchInfo.cbvUnits = processed.cbvUnits;
        end

        runStatus.analysisSucceeded = true;
        runStatus.runStage = "Completed";
        runStatus.statusMessage = "Completed";

        if analysisSettings.retainAnalysisInput
            analysisInput.map = map;
            analysisInput.co2 = co2;
            analysisInput.cbv = cbv;
            analysisInput.fs = samplingFrequencyHz;
            analysisInput.spectra = spectra;

            preprocessingMetadata = processed;
            signalFields = intersect( ...
                fieldnames(preprocessingMetadata), ...
                {'map'; 'co2'; 'cbv'});
            preprocessingMetadata = rmfield( ...
                preprocessingMetadata, signalFields);
            analysisInput.preprocessingMetadata = preprocessingMetadata;
        end
    end

    %% Return Numerical Results

    analysisResults.runStatus = runStatus;
    analysisResults.misoResults = misoResults;
    analysisResults.sisoResults = sisoResults;
    analysisResults.physiology = processed.physiology;
    analysisResults.co2Startup = processed.co2Startup;
    analysisResults.co2Alignment = processed.co2Alignment;
    analysisResults.analysisInput = analysisInput;
    analysisResults.analysisSettings = analysisSettings;

end

function runStatus = initializeSubjectRunStatus(analysisSettings)
% initializeSubjectRunStatus Create the default status for one subject.

    runStatus.analysisSucceeded = false;
    runStatus.runStage = "NotRun";
    runStatus.statusMessage = "Not run";
    runStatus.isTooShortForWelch = false;
    runStatus.numWelchWindows = NaN;
    runStatus.minimumWelchWindows = ...
        analysisSettings.pwelch.minimumWindows;
    runStatus.signalDurationSeconds = NaN;
    runStatus.co2StartupRemovedSeconds = NaN;
    runStatus.co2DelayCorrectionSeconds = NaN;
    runStatus.subjectFiguresSaved = false;
    runStatus.figureStatusMessage = "Not requested";

end
