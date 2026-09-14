function signalData = loadSubjectData(filePath, importSettings)
% loadSubjectData Read canonical time, MAP, CO2, and CBV columns.
%
% Excel and CSV files are supported. Header matching is case-insensitive and
% ignores spaces and punctuation. Optional columnMap overrides are useful for
% device-specific exports without editing this function.

if nargin < 2 || isempty(importSettings)
    importSettings = struct();
end

filePath = string(filePath);
[~, ~, extension] = fileparts(lower(filePath));
if ~ismember(extension, [".xlsx" ".xls" ".csv"])
    error("TFA:UnsupportedDataFile", ...
        "Use an Excel (.xlsx/.xls) or CSV (.csv) recording file.");
end

sheetNames = ["sheet_1", "cleaned", "Cleaned", "Sheet1", "sheet1"];
headerNames = { ...
    't', ["Time", "Seconds", "Sec"]; ...
    'map', ["MAP", "Portapres", "Mean (CH 2, Finapress)"]; ...
    'co2', ["ETCO2", "CO2", "Peak_ETCO2", "PETCO2", ...
        "Mean (CH 5, Peak maximum)", ...
        "Mean (CH 5, Peak EtCO2)"]; ...
    'cbv', ["CBV", "CBVV", "TCD", "Vmean", ...
        "Mean (CH 3, TCD)"]};

if extension == ".csv"
    importedTable = readtable(filePath, ...
        'VariableNamingRule', 'preserve');
else
    fileSheets = string(sheetnames(filePath));
    selectedSheet = selectSheet(fileSheets, sheetNames);
    if strlength(selectedSheet) == 0
        error( ...
            'TFA:MissingDataSheet', ...
            'No matching data sheet found. Expected one of: %s. Found: %s.', ...
            strjoin(sheetNames, ', '), strjoin(fileSheets, ', '));
    end
    importedTable = readtable(filePath, 'Sheet', selectedSheet, ...
        'VariableNamingRule', 'preserve');
end

headers = string(importedTable.Properties.VariableNames);
normalizedHeaders = normalizeHeader(headers);
signalData = struct();

for signalIndex = 1:size(headerNames, 1)
    standardName = string(headerNames{signalIndex, 1});
    possibleNames = string(headerNames{signalIndex, 2});
    requestedHeader = getMappedHeader(importSettings, standardName);

    if strlength(requestedHeader) > 0
        columnIndex = find( ...
            normalizedHeaders == normalizeHeader(requestedHeader));
    else
        columnIndex = find(ismember( ...
            normalizedHeaders, normalizeHeader(possibleNames)));
    end

    if isempty(columnIndex)
        error( ...
            'TFA:MissingDataColumn', ...
            ['Missing required %s column. Expected one of: %s. ' ...
             'Found: %s.'], ...
            standardName, strjoin(possibleNames, ', '), ...
            strjoin(headers, ', '));
    elseif numel(columnIndex) > 1
        error( ...
            'TFA:AmbiguousDataColumn', ...
            'Multiple columns matched %s aliases: %s.', ...
            standardName, strjoin(headers(columnIndex), ', '));
    end

    signalValues = importedTable{:, columnIndex};
    if ~isnumeric(signalValues)
        error( ...
            'TFA:NonNumericDataColumn', ...
            'The required %s column must contain numeric values.', ...
            standardName);
    end
    signalData.(standardName) = reshape(signalValues, 1, []);
end

end

function selectedSheet = selectSheet(fileSheets, preferredSheets)
% selectSheet Honor the declared alias priority rather than tab order.

selectedSheet = "";
normalizedFileSheets = normalizeHeader(fileSheets);
for sheetIndex = 1:numel(preferredSheets)
    match = find(normalizedFileSheets == ...
        normalizeHeader(preferredSheets(sheetIndex)), 1);
    if ~isempty(match)
        selectedSheet = fileSheets(match);
        return
    end
end

end

function normalized = normalizeHeader(headers)
% normalizeHeader Make matching tolerant to case, spaces, and punctuation.

normalized = lower(regexprep(string(headers), '[^a-zA-Z0-9]', ''));

end

function mappedHeader = getMappedHeader(importSettings, signalName)
% getMappedHeader Read an optional explicit column map.

mappedHeader = "";
if isfield(importSettings, "columnMap") && ...
        isstruct(importSettings.columnMap) && ...
        isfield(importSettings.columnMap, signalName)
    mappedHeader = string(importSettings.columnMap.(signalName));
    if ~isscalar(mappedHeader)
        error("TFA:InvalidColumnMap", ...
            "Each column map entry must contain one header name.");
    end
end

end
