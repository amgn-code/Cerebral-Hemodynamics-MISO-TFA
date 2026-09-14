function signalData = loadSubjectData(filePath)
% loadSubjectData Read time, MAP, CO2, and CBV from one Excel file.

    % Define Possible Sheet Names
    sheetNames = ["sheet_1", "cleaned", "Cleaned", "Sheet1", "sheet1"];

    % Define Possible Header Names
    headerNames = {
        't', ["Time", "time", "Seconds", "seconds", "Sec", "sec"];
        'map', ["MAP", "map", "MAP", "map", "Portapres", "portapres", "Mean (CH 2, Finapress)"];
        'co2', ["ETCO2", "CO2", "Peak_ETCO2", "PETCO2", "Mean (CH 5, Peak maximum)", "Mean (CH 5, Peak EtCO2)"];
        'cbv', ["CBV", "cbv", "CBVV", "cbvv", "TCD", "tcd", "Vmean", "Mean (CH 3, TCD)"]
        };

    % Find Sheet w/ a Defined Sheet Name Above
    fileSheets = sheetnames(filePath);
    matchedSheets = intersect(fileSheets, sheetNames, 'stable');

    % Error Message If No Sheet Name Is Found
    if isempty(matchedSheets)
        error( ...
            'TFA:MissingDataSheet', ...
            'No matching data sheet found. Expected one of: %s. Found: %s.', ...
            strjoin(sheetNames, ', '), strjoin(string(fileSheets), ', '));
    end

    % Extract Excel Data At Found Sheet
    excelData = readtable(filePath, 'Sheet', matchedSheets(1), ...
                                    'VariableNamingRule', 'preserve');

    % Extract Headers From The Data
    headers = string(excelData.Properties.VariableNames);

    % Initialze Struct for containing Signal Data
    signalData = struct();

    % Iterate Through Header Names Above to Find Matching Header
    for signalIndex = 1:size(headerNames, 1)
        standardName = headerNames{signalIndex,1};
        possibleNames = headerNames{signalIndex,2};

        % Find Column with respective header name
        columnIndex = find(ismember(headers, possibleNames));

        % Error message if no such column is found
        if isempty(columnIndex)
            error( ...
                'TFA:MissingDataColumn', ...
                'Missing required %s column. Expected one of: %s. Found: %s.', ...
                string(standardName), strjoin(possibleNames, ', '), ...
                strjoin(headers, ', '));

        elseif numel(columnIndex) > 1
            error( ...
                'TFA:AmbiguousDataColumn', ...
                'Multiple columns matched %s aliases: %s.', ...
                string(standardName), strjoin(headers(columnIndex), ', '));

        else
            % If a header is found then assign its column as an horizontal
            % array in the signalData struct
            matchedHeader = headers(columnIndex);

            signalValues = excelData{:,matchedHeader};

            if ~isnumeric(signalValues)
                error( ...
                    'TFA:NonNumericDataColumn', ...
                    'The required %s column must contain numeric values.', ...
                    string(standardName));
            end

            signalData.(standardName) = reshape(signalValues, 1, []);
        end

    end
end
