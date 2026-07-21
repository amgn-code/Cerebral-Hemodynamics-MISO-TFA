function savedSheetNames = saveResultsToExcel( ...
    filename, subjectResults, groupOrder, analysisSettings, outputSettings)
% saveResultsToExcel Write the unified subject or batch results workbook.

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

    maximumSheets = numel(metrics)*numel(orderedGroups);
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

    savedSheetNames = savedSheetNames(1:numSavedSheets);

end
