function delayResults = runCo2DelaySensitivity( ...
    analysisInput, analysisSettings, delaySeconds)
% runCo2DelaySensitivity Refit models over assumed CO2 delays.

    if nargin < 3
        delaySeconds = [0 3 6];
    end

    allRows = table();
    for delayIndex = 1:numel(delaySeconds)
        currentDelaySeconds = delaySeconds(delayIndex);
        [map, co2, cbv] = alignCo2ByDelay( ...
            analysisInput.map, analysisInput.co2, analysisInput.cbv, ...
            analysisInput.fs, currentDelaySeconds);
        comparison = runModelComparisonForSignals( ...
            map, co2, cbv, analysisInput.fs, analysisSettings);
        currentRows = summarizeGainModelComparisonByBand( ...
            comparison, analysisSettings);
        currentRows.AssumedCO2DelaySeconds = repmat( ...
            currentDelaySeconds, height(currentRows), 1);
        allRows = [allRows; currentRows];
    end

    delayResults.summary = allRows;
    delayResults.delaySeconds = delaySeconds(:);
    delayResults.signConvention = ...
        "Positive delay advances measured CO2 before refitting";

end
