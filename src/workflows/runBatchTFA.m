function batchResults = runBatchTFA( ...
    subjectList, analysisSettings, outputSettings, batchSettings)
% runBatchTFA Run the complete analysis workflow for a subject batch.

    analysisSettings = normalizeAnalysisFrequencyRange(analysisSettings);

    if ~exist(outputSettings.baseOutputFolder, "dir")
        mkdir(outputSettings.baseOutputFolder);
    end

    groupsToRun = upper(string(batchSettings.groupsToRun(:)));
    successfulOutputCounts = table( ...
        groupsToRun, zeros(numel(groupsToRun), 1), ...
        'VariableNames', {'Group', 'SuccessfulOutputs'});
    individualPlotCounts = successfulOutputCounts;

    requestedPlotCount = batchSettings.numSubjectFiguresPerGroup;

    if ~isnumeric(requestedPlotCount)
        requestedPlotCount = lower(string(requestedPlotCount));

        if requestedPlotCount == "all"
            requestedPlotCount = Inf;
        elseif requestedPlotCount == "none"
            requestedPlotCount = 0;
        else
            requestedPlotCount = str2double(requestedPlotCount);
        end
    end

    subjectResults = cell(height(subjectList), 1);
    statusRows = cell(height(subjectList), 1);
    numStatusRows = 0;

    for subjectIndex = 1:height(subjectList)
        subjectInfo.subjectID = string(subjectList.SubjectID(subjectIndex));
        subjectInfo.group = string(subjectList.Group(subjectIndex));
        subjectInfo.session = string(subjectList.Session(subjectIndex));
        subjectInfo.sourceFile = string(subjectList.SourceFile(subjectIndex));

        groupIndex = successfulOutputCounts.Group == ...
            upper(subjectInfo.group);

        if isfield(batchSettings, 'numSubjects') && ...
                isfield(batchSettings.numSubjects, char(upper(subjectInfo.group)))
            requestedSubjectCount = batchSettings.numSubjects.( ...
                char(upper(subjectInfo.group)));
        elseif isfield(batchSettings, 'numSubjectsPerGroup')
            requestedSubjectCount = batchSettings.numSubjectsPerGroup;
        else
            requestedSubjectCount = Inf;
        end

        if successfulOutputCounts.SuccessfulOutputs(groupIndex) >= ...
                requestedSubjectCount
            continue
        end

        subjectOutputSettings = outputSettings;
        subjectOutputSettings.saveSubjectFigures = ...
            individualPlotCounts.SuccessfulOutputs(groupIndex) < ...
            requestedPlotCount;

        try
            subjectResults{subjectIndex} = runSingleSubjectTFA( ...
                subjectInfo, analysisSettings, subjectOutputSettings);
            runStatus = subjectResults{subjectIndex}.runStatus;

            if runStatus.analysisSucceeded
                successfulOutputCounts.SuccessfulOutputs(groupIndex) = ...
                    successfulOutputCounts.SuccessfulOutputs(groupIndex) + 1;

                if subjectOutputSettings.saveSubjectFigures
                    individualPlotCounts.SuccessfulOutputs(groupIndex) = ...
                        individualPlotCounts.SuccessfulOutputs(groupIndex) + 1;
                end
            end

        catch errorInfo
            runStatus.analysisSucceeded = false;
            runStatus.runStage = "UnknownFailed";

            errorIdentifier = string(errorInfo.identifier);

            if errorIdentifier == "TFA:LoadDataFailed"
                runStatus.runStage = "LoadDataFailed";
            elseif errorIdentifier == "TFA:PreprocessingFailed"
                runStatus.runStage = "PreprocessingFailed";
            elseif errorIdentifier == "TFA:MISOFailed"
                runStatus.runStage = "MISOFailed";
            elseif errorIdentifier == "TFA:SISOFailed"
                runStatus.runStage = "SISOFailed";
            elseif errorIdentifier == "TFA:ExcelSaveFailed"
                runStatus.runStage = "ExcelSaveFailed";
            elseif errorIdentifier == "TFA:FigureSaveFailed"
                runStatus.runStage = "FigureSaveFailed";
            end

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

            fprintf("Subject %s failed: %s\n", ...
                subjectInfo.subjectID, string(errorInfo.message));
        end

        numStatusRows = numStatusRows + 1;
        statusRows{numStatusRows} = ...
            createBatchStatusRow(subjectInfo, runStatus);

        close all

        allGroupsComplete = true;

        for groupCountIndex = 1:height(successfulOutputCounts)
            groupName = successfulOutputCounts.Group(groupCountIndex);

            if isfield(batchSettings, 'numSubjects') && ...
                    isfield(batchSettings.numSubjects, char(groupName))
                requestedGroupCount = ...
                    batchSettings.numSubjects.(char(groupName));
            elseif isfield(batchSettings, 'numSubjectsPerGroup')
                requestedGroupCount = batchSettings.numSubjectsPerGroup;
            else
                requestedGroupCount = Inf;
            end

            if successfulOutputCounts.SuccessfulOutputs(groupCountIndex) < ...
                    requestedGroupCount
                allGroupsComplete = false;
            end
        end

        if allGroupsComplete
            break
        end
    end

    if numStatusRows == 0
        statusTable = table();
    else
        statusTable = vertcat(statusRows{1:numStatusRows});
    end

    groupResults = createGroupResults( ...
        subjectResults, batchSettings.groupsToRun, ...
        analysisSettings.runMISO, analysisSettings.runSISO, ...
        analysisSettings.phase);
    batchFigureFiles = strings(0, 1);

    if outputSettings.saveBatchFigures
        batchFigureFiles = saveBatchFullFrequencyFigures( ...
            groupResults, outputSettings.baseOutputFolder, analysisSettings);
    end

    if outputSettings.saveBatchExcel
        batchSummaryFile = fullfile( ...
            outputSettings.baseOutputFolder, ...
            outputSettings.batchSummaryExcelFileName);

        saveBatchResultsToExcel( ...
            batchSummaryFile, statusTable, subjectResults, groupResults, ...
            analysisSettings, outputSettings);
    end

    batchResults.subjectList = subjectList;
    batchResults.subjectResults = subjectResults;
    batchResults.statusTable = statusTable;
    batchResults.groupResults = groupResults;
    batchResults.groupPlotResults = groupResults;
    batchResults.batchFigureFiles = batchFigureFiles;
    batchResults.successfulOutputCounts = successfulOutputCounts;
    batchResults.individualPlotCounts = individualPlotCounts;

end
