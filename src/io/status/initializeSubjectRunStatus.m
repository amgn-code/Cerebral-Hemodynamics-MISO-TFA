function runStatus = initializeSubjectRunStatus(welchInfo, runSISO)
% initializeSubjectRunStatus
%
% Creates the first-pass run status for one subject.
%
% At this point the script has only checked whether the recording is long
% enough for the Welch window. The MISO and SISO fields are filled in later
% if those models actually run.

    runStatus.analysisSucceeded = false;
    runStatus.runStage = "NotRun";
    runStatus.statusMessage = "Not run";
    runStatus.isTooShortForWelch = welchInfo.isTooShort;
    runStatus.numWelchWindows = welchInfo.numWindows;
    runStatus.signalDurationSeconds = welchInfo.signalDurationSeconds;
    runStatus.windowLengthSeconds = welchInfo.windowLengthSeconds;
    runStatus.windowOverlap = welchInfo.windowOverlap;
    runStatus.runSISO = runSISO;

    runStatus.misoUsedDefaultCoherenceThreshold = NaN;
    runStatus.sisoUsedDefaultCoherenceThreshold = NaN;
    runStatus.misoCoherenceThreshold = NaN;
    runStatus.sisoCoherenceThreshold = NaN;

    if welchInfo.isTooShort
        runStatus.runStage = "TooShortForWelch";
        runStatus.statusMessage = "Skipped: signal shorter than Welch window";
    end

end
