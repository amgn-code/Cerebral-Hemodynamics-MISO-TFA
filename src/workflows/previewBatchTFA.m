function previewTable = previewBatchTFA(subjectList, analysisSettings)
% previewBatchTFA Preview data readiness for a subject batch.
%
% Loads and preprocesses each discovered subject, then reports whether the
% subject is long enough for the configured Welch analysis.

numSubjects = height(subjectList);
previewRows = cell(numSubjects, 1);

for subjectIndex = 1:numSubjects
    subjectInfo.subjectID = string(subjectList.SubjectID(subjectIndex));
    subjectInfo.group = string(subjectList.Group(subjectIndex));
    subjectInfo.session = string(subjectList.Session(subjectIndex));
    subjectInfo.sourceFile = string(subjectList.SourceFile(subjectIndex));

    failureStage = "LoadDataFailed";

    try
        signalData = loadData(subjectInfo.sourceFile);

        failureStage = "PreprocessingFailed";
        preprocessedSignalData = btbPreProcessing( ...
            signalData, ...
            analysisSettings.fsTarget, ...
            analysisSettings.preprocessing);

        failureStage = "WelchCheckFailed";
        [~, preflightWelchInfo] = windowSettings( ...
            analysisSettings.pwelch.windowLengthSeconds, ...
            analysisSettings.pwelch.windowOverlap, ...
            preprocessedSignalData.fs, ...
            length(preprocessedSignalData.map));

        runStatus = initializeSubjectRunStatus( ...
            preflightWelchInfo, ...
            analysisSettings.runMISO, ...
            analysisSettings.runSISO, ...
            analysisSettings.pwelch.minimumWindows);

        runStatus.cbvBaselineCmPerSec = ...
            preprocessedSignalData.cbvBaselineCmPerSec;
        runStatus.cbvUnits = preprocessedSignalData.cbvUnits;

        canRunTFA = ~preflightWelchInfo.isTooShort && ...
            preflightWelchInfo.numWindows >= ...
            analysisSettings.pwelch.minimumWindows;

        if canRunTFA
            runStatus.analysisSucceeded = true;
            runStatus.runStage = "PreviewPassed";
            runStatus.statusMessage = ...
                "Preview passed: load, preprocessing, and Welch checks passed";
        end

    catch errorInfo
        runStatus.analysisSucceeded = false;
        runStatus.runStage = failureStage;
        runStatus.statusMessage = "Failed: " + string(errorInfo.message);
        runStatus.isTooShortForWelch = "";
        runStatus.numWelchWindows = NaN;
        runStatus.minimumWelchWindows = ...
            analysisSettings.pwelch.minimumWindows;
        runStatus.signalDurationSeconds = NaN;
        runStatus.windowLengthSeconds = ...
            analysisSettings.pwelch.windowLengthSeconds;
        runStatus.windowOverlap = analysisSettings.pwelch.windowOverlap;
        runStatus.runMISO = analysisSettings.runMISO;
        runStatus.runSISO = analysisSettings.runSISO;
        runStatus.cbvBaselineCmPerSec = NaN;
        runStatus.cbvUnits = "";
        runStatus.misoUsedDefaultCoherenceThreshold = "";
        runStatus.sisoUsedDefaultCoherenceThreshold = "";
        runStatus.misoCoherenceThreshold = NaN;
        runStatus.sisoCoherenceThreshold = NaN;
        runStatus.misoCoherenceThresholdSource = "";
        runStatus.sisoCoherenceThresholdSource = "";
    end

    previewRows{subjectIndex} = createBatchStatusRow(subjectInfo, runStatus);
    previewRows{subjectIndex}.Properties.VariableNames{5} = ...
        'ProcessingPassed';
end

previewTable = vertcat(previewRows{:});

end
