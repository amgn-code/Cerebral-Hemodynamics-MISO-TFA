function outputs = createSimulationOutputs(simulationResults, outputSettings)
% createSimulationOutputs Build the five primary simulation heatmaps.
%
% Three maps use assigned recording or generator factors. Two maps use
% frequency-wise coherence diagnostics. Each map retains the plotted
% advantage and its underlying paired SISO and MISO errors in a table.

    if nargin < 2 || isempty(outputSettings)
        outputSettings = defaultSimulationOutputSettings();
    else
        outputSettings = completeSimulationOutputSettings(outputSettings);
    end
    validateSimulationResults(simulationResults);

    observations = simulationResults.observations;
    referenceDuration = ...
        simulationResults.settings.observations.referenceDurationSeconds;
    referenceOutputSnr = ...
        simulationResults.settings.observations.referenceOutputSnrDb;

    if ismember("IsMainExperiment", ...
            string(observations.Properties.VariableNames))
        mainRows = observations.IsMainExperiment;
    else
        mainRows = true(height(observations), 1);
    end

    outputs = buildOutputs(simulationResults, observations, mainRows, ...
        referenceDuration, referenceOutputSnr, outputSettings);

end

function outputs = buildOutputs(simulationResults, observations, mainRows, ...
    referenceDuration, referenceOutputSnr, outputSettings)
% buildOutputs Create assigned-factor and diagnostic maps.

    factorNames = [ ...
        "TargetInputCoherence"; ...
        "AssignedPETCO2ToMAPBandGainRatio"; ...
        "OutputSNRdB"];
    factorLabels = [ ...
        "MAP-CO2 input coherence"; ...
        "Assigned CO2-to-MAP pathway ratio"; ...
        "CBFV output SNR (dB)"];
    mapNames = ["input_coherence"; "co2_pathway_ratio"; "output_snr"];

    diagnosticNames = [ ...
        "multipleMinusMapCoherence"; ...
        "multipleMinusPartialMapCoherence"];
    diagnosticLabels = [ ...
        "MISO minus MAP pairwise coherence"; ...
        "MISO minus MAP partial coherence given CO2"];
    diagnosticMapNames = [ ...
        "miso_minus_map_pairwise_coherence"; ...
        "miso_minus_map_partial_coherence"];

    numMaps = numel(factorNames) + numel(diagnosticNames);
    maps = repmat(emptyMap(), numMaps, 1);
    plotSettings = outputSettings;
    if ~outputSettings.createFigures
        plotSettings.visible = "off";
    end

    for factorIndex = 1:numel(factorNames)
        factorName = factorNames(factorIndex);
        dataRows = selectFactorRows(observations, mainRows, factorName, ...
            referenceDuration, referenceOutputSnr);
        if ~any(dataRows)
            error("TFA:MissingSimulationOutputRows", ...
                "No reference rows are available for %s.", factorName);
        end

        [figureHandle, sourceData] = plotSimpleSimulationFrequencyMap( ...
            simulationResults, dataRows, factorName, ...
            factorLabels(factorIndex), "exact", "map", ...
            outputSettings.advantageColorLimit, plotSettings);
        maps(factorIndex) = makeMap( ...
            mapNames(factorIndex), "assigned factor", factorName, ...
            factorLabels(factorIndex), figureHandle, sourceData);
    end

    diagnosticRows = mainRows & ...
        observations.DurationSeconds == referenceDuration & ...
        observations.OutputSNRdB == referenceOutputSnr;
    for diagnosticIndex = 1:numel(diagnosticNames)
        diagnosticName = diagnosticNames(diagnosticIndex);
        [figureHandle, sourceData] = plotSimpleSimulationDiagnosticMap( ...
            simulationResults, diagnosticRows, diagnosticName, ...
            diagnosticLabels(diagnosticIndex), "map", ...
            outputSettings.advantageColorLimit, ...
            outputSettings.diagnosticBinEdges, plotSettings);
        mapIndex = numel(factorNames) + diagnosticIndex;
        maps(mapIndex) = makeMap( ...
            diagnosticMapNames(diagnosticIndex), "diagnostic", ...
            diagnosticName, diagnosticLabels(diagnosticIndex), ...
            figureHandle, sourceData);
    end

    if ~outputSettings.createFigures
        for mapIndex = 1:numel(maps)
            close(maps(mapIndex).figureHandle);
            maps(mapIndex).figureHandle = [];
        end
    end

    outputs.maps = maps;
    outputs.manifest = createSimulationRunManifest( ...
        simulationResults, outputSettings, maps);
    outputs.settings = outputSettings;
    outputs.referenceDurationSeconds = referenceDuration;
    outputs.referenceOutputSnrDb = referenceOutputSnr;

end

function dataRows = selectFactorRows(observations, mainRows, factorName, ...
    referenceDuration, referenceOutputSnr)
% selectFactorRows Hold the other displayed conditions fixed.

    if factorName == "OutputSNRdB"
        dataRows = mainRows & ...
            observations.DurationSeconds == referenceDuration;
    else
        dataRows = mainRows & ...
            observations.DurationSeconds == referenceDuration & ...
            observations.OutputSNRdB == referenceOutputSnr;
    end

end

function map = makeMap(name, kind, variableName, label, ...
    figureHandle, sourceData)
% makeMap Store one figure beside the exact cells used to draw it.

    map = emptyMap();
    map.name = string(name);
    map.kind = string(kind);
    map.variableName = string(variableName);
    map.label = string(label);
    map.figureHandle = figureHandle;
    map.frequencyTable = sourceData.frequencyMap;
    map.metadata = sourceData.metadata;

end

function map = emptyMap()
% emptyMap Define one stable map record.

    map.name = "";
    map.kind = "";
    map.variableName = "";
    map.label = "";
    map.figureHandle = [];
    map.frequencyTable = table();
    map.metadata = table();

end

function validateSimulationResults(simulationResults)
% validateSimulationResults Check fields required by the output module.

    requiredFields = ["observations", "frequency", "settings"];
    if ~isstruct(simulationResults) || ...
            ~all(isfield(simulationResults, requiredFields))
        error("TFA:InvalidSimulationResults", ...
            "Provide results from runSimulationInterface.");
    end

    requiredObservationColumns = [ ...
        "ObservationID", "DurationSeconds", "OutputSNRdB", ...
        "TargetInputCoherence", ...
        "AssignedPETCO2ToMAPBandGainRatio"];
    observedColumns = string( ...
        simulationResults.observations.Properties.VariableNames);
    if ~all(ismember(requiredObservationColumns, observedColumns))
        error("TFA:IncompleteSimulationResults", ...
            "The observations table is missing a primary factor.");
    end

    requiredDiagnostics = [ ...
        "multipleMinusMapCoherence", ...
        "multipleMinusPartialMapCoherence"];
    if ~isfield(simulationResults.frequency, "map") || ...
            ~all(isfield(simulationResults.frequency, requiredDiagnostics))
        error("TFA:IncompleteSimulationResults", ...
            "The MAP errors or coherence diagnostics are missing.");
    end

end
