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
    runStatus.subjectFiguresSaved = false;
    runStatus.figureStatusMessage = "Not requested";

end
