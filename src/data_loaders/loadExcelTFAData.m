function signalData = loadExcelTFAData(inputData, sheetName, varargin)
% loadExcelTFAData
%
% Loads BP/MAP, CO2, and CBF/CBFV data from an Excel sheet or table, resamples
% the signals to 4 Hz, and returns the same struct format used by
% createShoMisoSignal().
%
% Expected Excel columns:
%   Time   BP   CO2   CBF
%
% Acceptable alternative column names:
%   Time: time, t, seconds, sec, BeatTime
%   BP:   bp, map, abp, MAP
%   CO2:  co2, petco2, etco2, ETCO2_Interpolated
%   CBF:  cbf, cbv, cbfv, Vmean, TCD
%
% Output:
%   signalData.bp
%   signalData.co2
%   signalData.cbf
%   signalData.fs
%   signalData.t
    if nargin < 2 || isempty(sheetName)
        sheetName = "";
    end

    parameterNames = ["TimeColumn", "BPColumn", "CO2Column", "CBFColumn"];

    if any(strcmpi(string(sheetName), parameterNames))
        varargin = [{sheetName}, varargin];
        sheetName = "";
    end

    p = inputParser;
    addParameter(p, "TimeColumn", "auto", @(x) ischar(x) || isstring(x));
    addParameter(p, "BPColumn", "auto", @(x) ischar(x) || isstring(x));
    addParameter(p, "CO2Column", "auto", @(x) ischar(x) || isstring(x));
    addParameter(p, "CBFColumn", "auto", @(x) ischar(x) || isstring(x));
    parse(p, varargin{:});

    opts = p.Results;

    %% Read Excel file as a table
    if istable(inputData)
        dataTable = inputData;
    else
        if strlength(string(sheetName)) == 0
            dataTable = readtable(inputData, "VariableNamingRule", "preserve");
        else
            dataTable = readtable(inputData, ...
                "Sheet", sheetName, ...
                "VariableNamingRule", "preserve");
        end
    end

    timeCol = resolveColumn(dataTable, opts.TimeColumn, ...
        ["Time", "BeatTime", "time", "t", "seconds", "sec"]);
    bpCol = resolveColumn(dataTable, opts.BPColumn, ...
        ["MAP", "BP", "bp", "map", "abp"]);
    co2Col = resolveColumn(dataTable, opts.CO2Column, ...
        ["ETCO2_Interpolated", "ETCO2", "CO2", "co2", "petco2", "etco2"]);
    cbfCol = resolveColumn(dataTable, opts.CBFColumn, ...
        ["TCD", "Vmean", "CBF", "CBV", "CBFV", "cbf", "cbv", "cbfv"]);

    %% Extract signals
    t   = dataTable{:, timeCol};
    bp  = dataTable{:, bpCol};
    co2 = dataTable{:, co2Col};
    cbf = dataTable{:, cbfCol};
 
    %% Force column vectors
    t   = t(:);
    bp  = bp(:);
    co2 = co2(:);
    cbf = cbf(:);
 
    %% Remove rows with missing values
    validRows = ~isnan(t) & ~isnan(bp) & ~isnan(co2) & ~isnan(cbf);
 
    t   = t(validRows);
    bp  = bp(validRows);
    co2 = co2(validRows);
    cbf = cbf(validRows);
 
    %% Sort by time
    [t, sortIdx] = sort(t);
    bp  = bp(sortIdx);
    co2 = co2(sortIdx);
    cbf = cbf(sortIdx);
 
    %% Remove duplicate time points
    [t, uniqueIdx] = unique(t, "stable");
    bp  = bp(uniqueIdx);
    co2 = co2(uniqueIdx);
    cbf = cbf(uniqueIdx);
 
    %% Resample to 4 Hz
    fsTarget = 4;
    dtTarget = 1 / fsTarget;
 
    tResampled = (t(1):dtTarget:t(end))';
 
    bpResampled  = interp1(t, bp,  tResampled, "linear");
    co2Resampled = interp1(t, co2, tResampled, "linear");
    cbfResampled = interp1(t, cbf, tResampled, "linear");
 
    bpResampled = detrend(bpResampled,3);
    co2Resampled = detrend(co2Resampled,3);
    cbfResampled = detrend(cbfResampled,3);
 
    %% Package output in same format as simulated signal generators
    signalData = struct();
 
    signalData.bp  = bpResampled;
    signalData.co2 = co2Resampled;
    signalData.cbf = cbfResampled;
    signalData.fs  = fsTarget;
    signalData.t   = tResampled;
 
end


function colName = resolveColumn(dataTable, requestedName, possibleNames)

    requestedName = string(requestedName);

    if lower(requestedName) == "auto"
        colName = findColumn(dataTable, possibleNames);
    else
        colName = findColumn(dataTable, requestedName);
    end

end


function colName = findColumn(dataTable, possibleNames)

    variableNames = string(dataTable.Properties.VariableNames);

    for k = 1:numel(possibleNames)
        match = find(variableNames == possibleNames(k), 1);

        if isempty(match)
            match = find(lower(variableNames) == lower(possibleNames(k)), 1);
        end

        if ~isempty(match)
            colName = variableNames(match);
            return
        end
    end

    error("Could not find required column. Tried: %s", ...
        strjoin(string(possibleNames), ", "));

end
