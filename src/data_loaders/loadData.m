function signalData = loadData(filePath)

    % Define Possible Sheet Names
    sheetNames = ["sheet_1", "cleaned", "Sheet1", "sheet1"];

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
    for i = 1:size(headerNames,1)
        standardName = headerNames{i,1};
        possibleNames = headerNames{i,2};

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

            signalData.(standardName) = reshape( ...
                excelData{:,matchedHeader}, 1, []);
        end

    end



end
