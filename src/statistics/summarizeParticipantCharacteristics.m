function participantResults = summarizeParticipantCharacteristics( ...
    subjectResults, statisticsSettings)
% summarizeParticipantCharacteristics Create subject and group summaries.
%
% An optional standardized participant file may add demographic variables.
% It must contain one row per person and variables named SubjectID and Group.

    %% Collect the Physiological Values Produced by This Pipeline

    numSubjects = numel(subjectResults);
    subjectId = strings(numSubjects, 1);
    group = strings(numSubjects, 1);
    includedInTfa = false(numSubjects, 1);
    statusMessage = strings(numSubjects, 1);
    meanMapMmHg = NaN(numSubjects, 1);
    mapWithinRecordingSdMmHg = NaN(numSubjects, 1);
    meanPetco2MmHg = NaN(numSubjects, 1);
    petco2WithinRecordingSdMmHg = NaN(numSubjects, 1);
    meanCbvCmPerSec = NaN(numSubjects, 1);
    cbvWithinRecordingSdCmPerSec = NaN(numSubjects, 1);
    cvri = NaN(numSubjects, 1);
    usableDurationSeconds = NaN(numSubjects, 1);
    numWelchWindows = NaN(numSubjects, 1);

    for subjectIndex = 1:numSubjects
        currentSubject = subjectResults{subjectIndex};

        if isempty(currentSubject)
            continue
        end

        subjectId(subjectIndex) = string( ...
            currentSubject.subjectInfo.subjectID);
        group(subjectIndex) = upper(string( ...
            currentSubject.subjectInfo.group));
        includedInTfa(subjectIndex) = ...
            currentSubject.runStatus.analysisSucceeded;
        statusMessage(subjectIndex) = string( ...
            currentSubject.runStatus.statusMessage);
        usableDurationSeconds(subjectIndex) = ...
            currentSubject.runStatus.signalDurationSeconds;
        numWelchWindows(subjectIndex) = ...
            currentSubject.runStatus.numWelchWindows;

        if ~isfield(currentSubject, "physiology") || ...
                isempty(fieldnames(currentSubject.physiology))
            continue
        end

        physiology = currentSubject.physiology;
        meanMapMmHg(subjectIndex) = physiology.meanMapMmHg;
        mapWithinRecordingSdMmHg(subjectIndex) = physiology.mapSdMmHg;
        meanPetco2MmHg(subjectIndex) = physiology.meanPetco2MmHg;
        petco2WithinRecordingSdMmHg(subjectIndex) = ...
            physiology.petco2SdMmHg;
        meanCbvCmPerSec(subjectIndex) = physiology.meanCbvCmPerSec;
        cbvWithinRecordingSdCmPerSec(subjectIndex) = ...
            physiology.cbvSdCmPerSec;
        cvri(subjectIndex) = physiology.cvri;
    end

    subjectTable = table( ...
        subjectId, group, includedInTfa, statusMessage, ...
        meanMapMmHg, mapWithinRecordingSdMmHg, ...
        meanPetco2MmHg, petco2WithinRecordingSdMmHg, ...
        meanCbvCmPerSec, cbvWithinRecordingSdCmPerSec, cvri, ...
        usableDurationSeconds, numWelchWindows, ...
        'VariableNames', { ...
            'SubjectID', 'Group', 'IncludedInTFA', 'StatusMessage', ...
            'MeanMAP_mmHg', 'MAP_WithinRecordingSD_mmHg', ...
            'MeanPETCO2_mmHg', 'PETCO2_WithinRecordingSD_mmHg', ...
            'MeanCBFV_cm_per_s', 'CBFV_WithinRecordingSD_cm_per_s', ...
            'CVRi', 'UsableDuration_s', 'WelchWindows'});

    subjectTable = subjectTable(subjectTable.SubjectID ~= "", :);

    %% Add an Optional Standardized Participant Table

    participantDataFile = string(statisticsSettings.participantDataFile);

    if strlength(participantDataFile) > 0
        participantData = readtable( ...
            participantDataFile, "VariableNamingRule", "preserve");
        variableNames = string(participantData.Properties.VariableNames);

        if ~all(ismember(["SubjectID", "Group"], variableNames))
            error( ...
                'TFA:ParticipantFileMissingKeys', ...
                ['The participant file must contain SubjectID and Group ' ...
                 'variables.']);
        end

        participantData.SubjectID = string(participantData.SubjectID);
        participantData.Group = upper(string(participantData.Group));

        participantKeys = participantData(:, ["SubjectID", "Group"]);
        if height(unique(participantKeys, "rows")) ~= height(participantKeys)
            error( ...
                'TFA:DuplicateParticipantRows', ...
                ['The participant file must contain only one row for ' ...
                 'each SubjectID and Group.']);
        end

        subjectTable = outerjoin( ...
            subjectTable, participantData, ...
            "Keys", ["SubjectID", "Group"], ...
            "MergeKeys", true, "Type", "left");
    end

    %% Calculate Group Descriptions for Each Participant Variable

    includedTable = subjectTable(subjectTable.IncludedInTFA, :);
    excludedVariables = [ ...
        "SubjectID", "Group", "IncludedInTFA", "StatusMessage"];
    variablesToSummarize = setdiff( ...
        string(includedTable.Properties.VariableNames), ...
        excludedVariables, "stable");
    groupNames = upper(string(statisticsSettings.groupsToCompare(:)));

    summaryGroup = strings(0, 1);
    characteristic = strings(0, 1);
    level = strings(0, 1);
    n = zeros(0, 1);
    meanValue = zeros(0, 1);
    sdValue = zeros(0, 1);
    minimumValue = zeros(0, 1);
    maximumValue = zeros(0, 1);
    count = zeros(0, 1);
    percent = zeros(0, 1);
    testName = strings(0, 1);
    rawP = zeros(0, 1);

    for variableIndex = 1:numel(variablesToSummarize)
        variableName = variablesToSummarize(variableIndex);
        variableValues = includedTable.(variableName);
        isNumericVariable = isnumeric(variableValues);

        variableP = NaN;
        variableTestName = "Descriptive only";

        if isNumericVariable
            firstValues = variableValues( ...
                includedTable.Group == groupNames(1));
            firstValues = firstValues(isfinite(firstValues));

            if numel(groupNames) == 2
                secondValues = variableValues( ...
                    includedTable.Group == groupNames(2));
                secondValues = secondValues(isfinite(secondValues));

                if numel(firstValues) >= 2 && ...
                        numel(secondValues) >= 2
                    [~, variableP] = ttest2( ...
                        firstValues, secondValues, ...
                        "Vartype", "unequal");
                    variableTestName = "Welch two-sample t-test";
                end
            end

            for groupIndex = 1:numel(groupNames)
                currentValues = variableValues( ...
                    includedTable.Group == groupNames(groupIndex));
                currentValues = currentValues(isfinite(currentValues));

                summaryGroup(end + 1,1) = groupNames(groupIndex);
                characteristic(end + 1,1) = variableName;
                level(end + 1,1) = "";
                n(end + 1,1) = numel(currentValues);
                if isempty(currentValues)
                    meanValue(end + 1,1) = NaN;
                    sdValue(end + 1,1) = NaN;
                    minimumValue(end + 1,1) = NaN;
                    maximumValue(end + 1,1) = NaN;
                else
                    meanValue(end + 1,1) = ...
                        mean(currentValues, 'omitnan');
                    sdValue(end + 1,1) = ...
                        std(currentValues, 0, 'omitnan');
                    minimumValue(end + 1,1) = ...
                        min(currentValues, [], 'omitnan');
                    maximumValue(end + 1,1) = ...
                        max(currentValues, [], 'omitnan');
                end
                count(end + 1,1) = NaN;
                percent(end + 1,1) = NaN;
                testName(end + 1,1) = variableTestName;
                rawP(end + 1,1) = variableP;
            end
        else
            stringValues = string(variableValues);
            availableMask = ~ismissing(stringValues) & stringValues ~= "";
            availableLevels = unique(stringValues(availableMask), "stable");

            if ~isempty(availableLevels)
                comparisonMask = availableMask & ismember( ...
                    includedTable.Group, groupNames);
                comparisonGroups = includedTable.Group(comparisonMask);
                comparisonValues = stringValues(comparisonMask);

                if numel(unique(comparisonGroups)) == 2
                    [countTable, ~, variableP] = crosstab( ...
                        comparisonGroups, comparisonValues);
                    variableTestName = "Chi-square test";

                    if isequal(size(countTable), [2 2]) && ...
                            any(countTable < 5, "all")
                        [~, variableP] = fishertest(countTable);
                        variableTestName = "Fisher exact test";
                    end
                end
            end

            for groupIndex = 1:numel(groupNames)
                currentGroupMask = includedTable.Group == ...
                    groupNames(groupIndex) & availableMask;
                currentGroupTotal = sum(currentGroupMask);

                for levelIndex = 1:numel(availableLevels)
                    currentCount = sum( ...
                        currentGroupMask & ...
                        stringValues == availableLevels(levelIndex));

                    summaryGroup(end + 1,1) = groupNames(groupIndex);
                    characteristic(end + 1,1) = variableName;
                    level(end + 1,1) = availableLevels(levelIndex);
                    n(end + 1,1) = currentGroupTotal;
                    meanValue(end + 1,1) = NaN;
                    sdValue(end + 1,1) = NaN;
                    minimumValue(end + 1,1) = NaN;
                    maximumValue(end + 1,1) = NaN;
                    count(end + 1,1) = currentCount;
                    percent(end + 1,1) = ...
                        100*currentCount/currentGroupTotal;
                    testName(end + 1,1) = variableTestName;
                    rawP(end + 1,1) = variableP;
                end
            end
        end
    end

    summaryTable = table( ...
        summaryGroup, characteristic, level, n, meanValue, sdValue, ...
        minimumValue, maximumValue, count, percent, testName, rawP, ...
        'VariableNames', { ...
            'Group', 'Characteristic', 'Level', 'N', 'Mean', 'SD', ...
            'Minimum', 'Maximum', 'Count', 'Percent', 'Test', 'RawP'});

    summaryTable.BHAdjustedP = NaN(height(summaryTable), 1);
    testedCharacteristics = unique( ...
        summaryTable.Characteristic(isfinite(summaryTable.RawP)), ...
        "stable");
    characteristicPValues = NaN(numel(testedCharacteristics), 1);

    for characteristicIndex = 1:numel(testedCharacteristics)
        characteristicMask = summaryTable.Characteristic == ...
            testedCharacteristics(characteristicIndex);
        firstRow = find(characteristicMask, 1);
        characteristicPValues(characteristicIndex) = ...
            summaryTable.RawP(firstRow);
    end

    adjustedCharacteristicPValues = ...
        adjustPValuesBenjaminiHochberg(characteristicPValues);

    for characteristicIndex = 1:numel(testedCharacteristics)
        characteristicMask = summaryTable.Characteristic == ...
            testedCharacteristics(characteristicIndex);
        summaryTable.BHAdjustedP(characteristicMask) = ...
            adjustedCharacteristicPValues(characteristicIndex);
    end

    summaryTable.IsSignificant = ...
        summaryTable.BHAdjustedP < statisticsSettings.alpha;

    participantResults.subjectValues = subjectTable;
    participantResults.summary = summaryTable;

end
