function signalData = loadData(filePath)

    sheetNames = ["sheet_1", "cleaned"];
    
    headerNames = {
        't', ["Time", "time", "Seconds", "seconds", "Sec", "sec"];
        'map', ["MAP", "map", "BP", "bp", "Portapres", "portapres"];
        'co2', ["ETCO2", "CO2", "Peak_ETCO2"];
        'cbv', ["CBV", "cbv", "CBFV", "cbfv", "TCD", "tcd", "Vmean"];
        'vmin', ["Vmin"];
        'vmax', ["Vmax"]
        };

    fileSheets = sheetnames(filePath);
    matchedSheets = intersect(fileSheets, sheetNames, 'stable');
    excelData = readtable(filePath, 'Sheet', matchedSheets(1), ...
                                    'VariableNamingRule', 'preserve');

    headers = string(excelData.Properties.VariableNames);

    signalData = struct();


    for i = 1:size(headerNames,1)
        standardName = headerNames{i,1};
        possibleNames = headerNames{i,2};

        columnIndex = find(ismember(headers, possibleNames));
        matchedHeader = headers(columnIndex);

        signalData.(standardName) = excelData{:,matchedHeader};

    end



end