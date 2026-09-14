function subjectResults = analyzeSubjectTFA( ...
    signalData, subjectInfo, analysisSettings, outputSettings)
% analyzeSubjectTFA Analyze one subject's loaded time-series data.
%
% The numerical work is delegated to analyzeTfaSignals. This wrapper keeps
% the legacy batch workflow's subject metadata and optional figure output.

    coreResults = analyzeTfaSignals(signalData, analysisSettings);
    runStatus = coreResults.runStatus;
    misoResults = coreResults.misoResults;
    sisoResults = coreResults.sisoResults;
    physiology = coreResults.physiology;
    co2Startup = coreResults.co2Startup;
    analysisInput = coreResults.analysisInput;

    subjectFolderName = upper(string(subjectInfo.group)) + "_" + ...
        string(subjectInfo.subjectID);
    outputFolder = fullfile( ...
        outputSettings.baseOutputFolder, subjectFolderName);

    subjectFigureNames = strings(0, 1);
    subjectFigureFiles = strings(0, 1);

    fprintf("Subject %s: %.1f seconds, %d Welch windows.\n", ...
        string(subjectInfo.subjectID), ...
        runStatus.signalDurationSeconds, ...
        runStatus.numWelchWindows);

    if ~runStatus.analysisSucceeded
        warning("Skipping TFA: %s", runStatus.statusMessage);
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
    subjectResults.physiology = physiology;
    subjectResults.co2Startup = co2Startup;
    subjectResults.analysisInput = analysisInput;
    subjectResults.outputFolder = outputFolder;
    subjectResults.subjectFigureNames = subjectFigureNames;
    subjectResults.subjectFigureFiles = subjectFigureFiles;

end
