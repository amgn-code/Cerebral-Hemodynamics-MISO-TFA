function map = createNamedSimulationMap( ...
    simulationResults, dataRows, factorName, factorLabel, ...
    pathway, mapName, colorLimit, outputSettings)
% createNamedSimulationMap Build one explicitly selected simulation map.

    if ~islogical(dataRows) || numel(dataRows) ~= ...
            height(simulationResults.observations) || ~any(dataRows)
        error("TFA:InvalidNamedSimulationRows", ...
            "A named map requires a nonempty logical observation mask.");
    end
    if nargin < 7 || isempty(colorLimit) || ~isfinite(colorLimit)
        colorLimit = 1.5;
    end
    if nargin < 8 || isempty(outputSettings)
        outputSettings = defaultSimulationOutputSettings("off");
    else
        outputSettings = completeSimulationOutputSettings(outputSettings);
    end

    [figureHandle, sourceData] = plotSimpleSimulationFrequencyMap( ...
        simulationResults, dataRows, factorName, factorLabel, ...
        "exact", pathway, colorLimit, outputSettings);
    if ~outputSettings.createFigures
        close(figureHandle);
        figureHandle = [];
    end

    map.name = string(mapName);
    map.kind = "named experiment";
    map.variableName = string(factorName);
    map.label = string(factorLabel);
    map.pathway = lower(string(pathway));
    map.figureHandle = figureHandle;
    map.frequencyTable = sourceData.frequencyMap;
    map.metadata = sourceData.metadata;
    map.companions = createSimulationCompanionTables( ...
        simulationResults, dataRows, factorName, "exact", pathway);
    map.selectedObservationCount = nnz(dataRows);
    map.selectedExperiments = unique( ...
        simulationResults.observations.Experiment(dataRows));

end
