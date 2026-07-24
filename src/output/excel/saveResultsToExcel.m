function savedSheetNames = saveResultsToExcel( ...
    filename, subjectResults, groupOrder, analysisSettings, ...
    outputSettings, statisticalResults)
% saveResultsToExcel Write the unified subject or batch results workbook.

    if nargin < 6
        statisticalResults = struct();
    end

    metrics = getExcelMetricDefinitions( ...
        outputSettings.excelMetrics, ...
        analysisSettings.runMISO, analysisSettings.runSISO);

    if isempty(metrics)
        error( ...
            'TFA:NoExcelMetricsEnabled', ...
            'Enable at least one outputSettings.excelMetrics option.');
    end

    if exist(filename, "file")
        delete(filename);
    end

    %% Use the Group Order Selected by the User

    orderedGroups = upper(string(groupOrder));
    orderedGroups = unique(orderedGroups(:), "stable");

    %% Write Every Group for One Metric Before the Next Metric

    maximumSheets = numel(metrics)*numel(orderedGroups) + 6;
    savedSheetNames = strings(maximumSheets, 1);
    numSavedSheets = 0;

    for metricIndex = 1:numel(metrics)
        metric = metrics(metricIndex);

        for groupIndex = 1:numel(orderedGroups)
            groupName = orderedGroups(groupIndex);
            sheetCells = createExcelMetricSheet( ...
                subjectResults, groupName, metric, analysisSettings);

            if isempty(sheetCells)
                continue
            end

            sheetName = groupName + "_" + metric.sheetName;

            if strlength(sheetName) > 31
                error( ...
                    'TFA:ExcelSheetNameTooLong', ...
                    'Excel sheet name "%s" exceeds 31 characters.', ...
                    sheetName);
            end

            writecell( ...
                sheetCells, filename, ...
                "Sheet", sheetName, "Range", "A1");

            numSavedSheets = numSavedSheets + 1;
            savedSheetNames(numSavedSheets) = sheetName;
        end
    end

    %% Add the Paper-Oriented Statistical Tables

    saveStatistics = isfield(outputSettings, "excelStatistics") && ...
        outputSettings.excelStatistics && ...
        ~isempty(fieldnames(statisticalResults));

    if saveStatistics
        participantSheet = "Participant_Characteristics";
        participantSummary = ...
            statisticalResults.participantCharacteristics;
        participantValues = statisticalResults.participantValues;

        writecell( ...
            {"Group summaries for subjects included in TFA"}, ...
            filename, "Sheet", participantSheet, "Range", "A1");
        writetable( ...
            participantSummary, filename, ...
            "Sheet", participantSheet, "Range", "A2");

        subjectTitleRow = height(participantSummary) + 4;
        subjectTableRow = subjectTitleRow + 1;
        writecell( ...
            {"Subject values and inclusion status"}, filename, ...
            "Sheet", participantSheet, ...
            "Range", "A" + string(subjectTitleRow));
        writetable( ...
            participantValues, filename, ...
            "Sheet", participantSheet, ...
            "Range", "A" + string(subjectTableRow));

        numSavedSheets = numSavedSheets + 1;
        savedSheetNames(numSavedSheets) = participantSheet;

        if ~isempty(statisticalResults.modelComparisons)
            sheetName = "Model_Comparisons";
            writetable( ...
                statisticalResults.modelComparisons, filename, ...
                "Sheet", sheetName, "Range", "A1");
            numSavedSheets = numSavedSheets + 1;
            savedSheetNames(numSavedSheets) = sheetName;
        end

        if ~isempty(statisticalResults.groupComparisons)
            sheetName = "Group_Comparisons";
            writetable( ...
                statisticalResults.groupComparisons, filename, ...
                "Sheet", sheetName, "Range", "A1");
            numSavedSheets = numSavedSheets + 1;
            savedSheetNames(numSavedSheets) = sheetName;
        end

        if ~isempty(statisticalResults.inputAssociations)
            sheetName = "Input_Associations";
            writetable( ...
                statisticalResults.inputAssociations, filename, ...
                "Sheet", sheetName, "Range", "A1");
            numSavedSheets = numSavedSheets + 1;
            savedSheetNames(numSavedSheets) = sheetName;
        end

        if isfield(statisticalResults, "frequencyGroupComparisons") && ...
                ~isempty(statisticalResults.frequencyGroupComparisons)
            sheetName = "Frequency_Group_Tests";
            writecell( ...
                {['Exploratory frequency-wise tests. BH adjustment is ' ...
                  'applied across the bins in each metric/pathway curve.']}, ...
                filename, "Sheet", sheetName, "Range", "A1");
            writetable( ...
                statisticalResults.frequencyGroupComparisons, filename, ...
                "Sheet", sheetName, "Range", "A2");
            numSavedSheets = numSavedSheets + 1;
            savedSheetNames(numSavedSheets) = sheetName;
        end

        if isfield(statisticalResults, "frequencyModelComparisons") && ...
                ~isempty(statisticalResults.frequencyModelComparisons)
            sheetName = "Frequency_Model_Tests";
            writecell( ...
                {['Exploratory frequency-wise tests. BH adjustment is ' ...
                  'applied across the bins in each group/metric/pathway ' ...
                  'curve.']}, filename, "Sheet", sheetName, "Range", "A1");
            writetable( ...
                statisticalResults.frequencyModelComparisons, filename, ...
                "Sheet", sheetName, "Range", "A2");
            numSavedSheets = numSavedSheets + 1;
            savedSheetNames(numSavedSheets) = sheetName;
        end
    end

    savedSheetNames = savedSheetNames(1:numSavedSheets);

end
