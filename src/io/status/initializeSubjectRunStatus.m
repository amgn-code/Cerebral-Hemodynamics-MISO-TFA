function runStatus = initializeSubjectRunStatus( ...
    welchInfo, runSISO, minimumWelchWindows)
% initializeSubjectRunStatus
%
% Creates the first-pass run status for one subject.
%
% At this point the script has only checked whether the recording is long
% enough for the Welch window and minimum number of Welch windows. The MISO
% and SISO fields are filled in later if those models actually run.

    if nargin < 3
        minimumWelchWindows = 1;
    end

    runStatus.analysisSucceeded = false;
    runStatus.runStage = "NotRun";
    runStatus.statusMessage = "Not run";
    runStatus.isTooShortForWelch = welchInfo.isTooShort;
    runStatus.numWelchWindows = welchInfo.numWindows;
    runStatus.minimumWelchWindows = minimumWelchWindows;
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
    elseif welchInfo.numWindows < minimumWelchWindows
        runStatus.runStage = "InsufficientWelchWindows";
        runStatus.statusMessage = "Skipped: fewer than minimum Welch windows";
    end

end
