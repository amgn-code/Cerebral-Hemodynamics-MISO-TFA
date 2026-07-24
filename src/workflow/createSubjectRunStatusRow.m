function statusRow = createSubjectRunStatusRow(subjectInfo, runStatus)
% createSubjectRunStatusRow Convert one subject's run status to a table row.

    statusRow = table( ...
        string(subjectInfo.subjectID), ...
        'VariableNames', {'SubjectID'});

    statusRow.Group = string(subjectInfo.group);
    statusRow.SourceFile = string(subjectInfo.sourceFile);
    statusRow.AnalysisSucceeded = runStatus.analysisSucceeded;
    statusRow.RunStage = string(runStatus.runStage);
    statusRow.StatusMessage = string(runStatus.statusMessage);
    statusRow.IsTooShortForWelch = runStatus.isTooShortForWelch;
    statusRow.NumWelchWindows = runStatus.numWelchWindows;
    statusRow.MinimumWelchWindows = runStatus.minimumWelchWindows;
    statusRow.SignalDurationSeconds = runStatus.signalDurationSeconds;
    statusRow.CO2StartupRemovedSeconds = ...
        runStatus.co2StartupRemovedSeconds;
    statusRow.SubjectFiguresSaved = runStatus.subjectFiguresSaved;
    statusRow.FigureStatusMessage = ...
        string(runStatus.figureStatusMessage);

end
