function previewTable = previewBatchReadiness(subjectList, analysisSettings)
% previewBatchReadiness Preview data readiness for a subject batch.
%
% Loads and preprocesses each discovered subject, then reports whether the
% subject is long enough for the configured Welch analysis.

    numSubjects = height(subjectList);

    subjectIds = string(subjectList.SubjectID);
    subjectGroups = string(subjectList.Group);
    sourceFiles = string(subjectList.SourceFile);

    isReadyForTFA = false(numSubjects, 1);
    readinessStage = repmat("NotChecked", numSubjects, 1);
    statusMessage = repmat("Not checked", numSubjects, 1);
    signalDurationSeconds = NaN(numSubjects, 1);
    numWelchWindows = NaN(numSubjects, 1);
    cbvBaselineCmPerSec = NaN(numSubjects, 1);
    cbvUnits = strings(numSubjects, 1);

    minimumWelchWindows = repmat( ...
        analysisSettings.pwelch.minimumWindows, numSubjects, 1);
    windowLengthSeconds = repmat( ...
        analysisSettings.pwelch.windowLengthSeconds, numSubjects, 1);
    windowOverlap = repmat( ...
        analysisSettings.pwelch.windowOverlap, numSubjects, 1);

    for subjectIndex = 1:numSubjects
        failureStage = "LoadDataFailed";

        try
            signalData = loadSubjectData(sourceFiles(subjectIndex));

            failureStage = "PreprocessingFailed";
            preprocessedSignalData = preprocessTfaSignals( ...
                signalData, ...
                analysisSettings.fsTarget, ...
                analysisSettings.preprocessing);

            cbvBaselineCmPerSec(subjectIndex) = ...
                preprocessedSignalData.cbvBaselineCmPerSec;
            cbvUnits(subjectIndex) = preprocessedSignalData.cbvUnits;

            failureStage = "WelchCheckFailed";
            [~, welchInfo] = getWelchWindowSettings( ...
                analysisSettings.pwelch, ...
                preprocessedSignalData.fs, ...
                length(preprocessedSignalData.map));

            signalDurationSeconds(subjectIndex) = ...
                welchInfo.signalDurationSeconds;
            numWelchWindows(subjectIndex) = welchInfo.numWindows;

            if welchInfo.isTooShort
                readinessStage(subjectIndex) = "TooShortForWelch";
                statusMessage(subjectIndex) = ...
                    "Not ready: signal is shorter than the Welch window";
            elseif ~welchInfo.isReadyForTFA
                readinessStage(subjectIndex) = ...
                    "InsufficientWelchWindows";
                statusMessage(subjectIndex) = ...
                    "Not ready: fewer than the minimum Welch windows";
            else
                isReadyForTFA(subjectIndex) = true;
                readinessStage(subjectIndex) = "Ready";
                statusMessage(subjectIndex) = ...
                    "Ready: load, preprocessing, and Welch checks passed";
            end

        catch errorInfo
            readinessStage(subjectIndex) = failureStage;
            statusMessage(subjectIndex) = ...
                "Failed: " + string(errorInfo.message);
        end
    end

    previewTable = table(subjectIds, 'VariableNames', {'SubjectID'});
    previewTable.Group = subjectGroups;
    previewTable.SourceFile = sourceFiles;
    previewTable.IsReadyForTFA = isReadyForTFA;
    previewTable.ReadinessStage = readinessStage;
    previewTable.StatusMessage = statusMessage;
    previewTable.SignalDurationSeconds = signalDurationSeconds;
    previewTable.NumWelchWindows = numWelchWindows;
    previewTable.MinimumWelchWindows = minimumWelchWindows;
    previewTable.WindowLengthSeconds = windowLengthSeconds;
    previewTable.WindowOverlap = windowOverlap;
    previewTable.CBVBaseline_cm_per_s = cbvBaselineCmPerSec;
    previewTable.CBVUnits = cbvUnits;

end
