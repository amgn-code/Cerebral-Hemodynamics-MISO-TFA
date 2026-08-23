function savedFiles = saveApproachFigureSourceData( ...
    sourceData, sourceFolder, plotName)
% saveApproachFigureSourceData Save numeric and readable plot source data.

    savedFiles = strings(0, 1);
    if isempty(sourceData)
        return
    end
    if ~exist(sourceFolder, "dir")
        mkdir(sourceFolder);
    end

    if istable(sourceData)
        filename = fullfile( ...
            sourceFolder, plotName + "_source.csv");
        writetable(sourceData, filename);
        workbookFile = fullfile( ...
            sourceFolder, plotName + "_source.xlsx");
        if exist(workbookFile, "file")
            delete(workbookFile);
        end
        writetable(sourceData, workbookFile, "Sheet", "Summary");
        if isFrequencySummaryTable(sourceData)
            writecell( ...
                createFormattedFrequencyGrid(sourceData), ...
                workbookFile, "Sheet", "Readable_grid");
        elseif isSurfaceSummaryTable(sourceData)
            writecell( ...
                createFormattedSurfaceGrid(sourceData), ...
                workbookFile, "Sheet", "Readable_grid");
        end
        savedFiles = [string(filename); string(workbookFile)];
        return
    end

    if ~isstruct(sourceData)
        return
    end

    fieldNames = fieldnames(sourceData);
    workbookFile = fullfile( ...
        sourceFolder, plotName + "_source.xlsx");
    if exist(workbookFile, "file")
        delete(workbookFile);
    end

    savedFiles = strings(2*numel(fieldNames) + 1, 1);
    numSavedFiles = 0;
    wroteWorkbook = false;
    for fieldIndex = 1:numel(fieldNames)
        fieldName = string(fieldNames{fieldIndex});
        currentData = sourceData.(fieldName);
        if ~istable(currentData)
            continue
        end
        filename = fullfile( ...
            sourceFolder, plotName + "_" + ...
            lower(fieldName) + ".csv");
        writetable(currentData, filename);
        numSavedFiles = numSavedFiles + 1;
        savedFiles(numSavedFiles) = string(filename);

        dataSheet = makeSheetName(fieldName + "_data");
        writetable(currentData, workbookFile, "Sheet", dataSheet);
        wroteWorkbook = true;

        if isFrequencySummaryTable(currentData)
            grid = createFormattedFrequencyGrid(currentData);
            gridSheet = makeSheetName(fieldName + "_grid");
            writecell(grid, workbookFile, "Sheet", gridSheet);
        elseif isSurfaceSummaryTable(currentData)
            grid = createFormattedSurfaceGrid(currentData);
            gridSheet = makeSheetName(fieldName + "_grid");
            writecell(grid, workbookFile, "Sheet", gridSheet);
        end
    end
    if wroteWorkbook
        numSavedFiles = numSavedFiles + 1;
        savedFiles(numSavedFiles) = string(workbookFile);
    end
    savedFiles = savedFiles(1:numSavedFiles);

end

function tf = isSurfaceSummaryTable(data)
% isSurfaceSummaryTable Identify tidy two-factor heatmap statistics.

    required = [ ...
        "XGroup", "YGroup", "Mean", "SD", "ValidN", "GroupN"];
    tf = all(ismember( ...
        required, string(data.Properties.VariableNames)));

end

function tf = isFrequencySummaryTable(data)
% isFrequencySummaryTable Identify tidy heatmap statistics.

    required = [ ...
        "FactorGroup", "FrequencyHz", "Mean", "SD", ...
        "ValidN", "GroupN"];
    tf = all(ismember( ...
        required, string(data.Properties.VariableNames)));

end

function grid = createFormattedSurfaceGrid(data)
% createFormattedSurfaceGrid Build mean ± SD cells for a two-factor map.

    xGroups = unique(string(data.XGroup), "stable");
    yGroups = unique(string(data.YGroup), "stable");
    grid = cell(numel(yGroups) + 1, numel(xGroups) + 1);
    grid{1,1} = "Y group / X group";
    grid(1,2:end) = cellstr(xGroups);

    for yIndex = 1:numel(yGroups)
        grid{yIndex + 1,1} = char(yGroups(yIndex));
        for xIndex = 1:numel(xGroups)
            row = string(data.XGroup) == xGroups(xIndex) & ...
                string(data.YGroup) == yGroups(yIndex);
            if ~any(row)
                grid{yIndex + 1,xIndex + 1} = "NA";
                continue
            end
            current = data(find(row, 1), :);
            if isfinite(current.Mean) && isfinite(current.SD)
                cellText = sprintf( ...
                    "%.4g ± %.4g (N=%d)", ...
                    current.Mean, current.SD, current.ValidN);
            else
                cellText = "NA (N=" + ...
                    string(current.ValidN) + ")";
            end
            grid{yIndex + 1,xIndex + 1} = char(cellText);
        end
    end

end

function grid = createFormattedFrequencyGrid(data)
% createFormattedFrequencyGrid Build mean ± SD cells with N information.

    [groupLabels, firstGroupRows] = unique( ...
        string(data.FactorGroup), "stable");
    frequencies = unique(data.FrequencyHz, "sorted");
    numGroups = numel(groupLabels);
    numFrequencies = numel(frequencies);

    grid = cell(numGroups + 1, numFrequencies + 2);
    grid(1,1) = {"Factor group"};
    for frequencyIndex = 1:numFrequencies
        grid{1,frequencyIndex + 1} = sprintf( ...
            "%.4g Hz", frequencies(frequencyIndex));
    end
    grid(1,end) = {"N"};

    for groupIndex = 1:numGroups
        groupRows = string(data.FactorGroup) == ...
            groupLabels(groupIndex);
        grid{groupIndex + 1,1} = char(groupLabels(groupIndex));
        groupN = data.GroupN(firstGroupRows(groupIndex));
        grid{groupIndex + 1,end} = groupN;

        for frequencyIndex = 1:numFrequencies
            row = groupRows & ...
                data.FrequencyHz == frequencies(frequencyIndex);
            if ~any(row)
                grid{groupIndex + 1,frequencyIndex + 1} = "NA";
                continue
            end

            current = data(find(row, 1), :);
            if isfinite(current.Mean) && isfinite(current.SD)
                cellText = sprintf( ...
                    "%.4g ± %.4g", current.Mean, current.SD);
            else
                cellText = "NA";
            end
            if current.ValidN ~= current.GroupN
                cellText = cellText + " (n=" + ...
                    string(current.ValidN) + ")";
            end
            grid{groupIndex + 1,frequencyIndex + 1} = ...
                char(cellText);
        end
    end

end

function sheetName = makeSheetName(rawName)
% makeSheetName Create a valid, compact Excel sheet name.

    sheetName = matlab.lang.makeValidName(string(rawName));
    if strlength(sheetName) > 31
        sheetName = extractBefore(sheetName, 32);
    end

end
