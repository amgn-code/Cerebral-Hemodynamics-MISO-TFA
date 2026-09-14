function exportResults = exportSimpleSimulationFrequencyMapSet( ...
    simulationResults, outputFolder, exportSettings)
% exportSimpleSimulationFrequencyMapSet Export the small primary heatmaps.
%
% The default set contains three assigned-factor maps and two MAP coherence
% diagnostic maps. Duration and noise are selected so that each map varies
% one factor while the other primary conditions remain fixed. The existing,
% broader approach-paper export is left unchanged.

    if nargin < 2 || strlength(string(outputFolder)) == 0
        error( ...
            "TFA:MissingSimpleSimulationOutputFolder", ...
            "Choose an output folder for the simple simulation figures.");
    end
    if nargin < 3 || isempty(exportSettings)
        exportSettings = createDefaultSimpleHeatmapExportSettings();
    else
        exportSettings = completeSimpleHeatmapExportSettings( ...
            exportSettings);
    end

    validateSimpleSimulationResults(simulationResults);
    outputFolder = string(outputFolder);
    groupFolder = fullfile( ...
        outputFolder, "Simple_Simulation_Heatmaps", ...
        "Primary_Accuracy_Heatmaps");
    if ~exist(groupFolder, "dir")
        mkdir(groupFolder);
    end

    observations = simulationResults.observations;
    factorNames = [ ...
        "TargetInputCoherence"; ...
        "AssignedPETCO2ToMAPBandGainRatio"; ...
        "OutputSNRdB"];
    factorLabels = [ ...
        "MAP-CO2 input coherence"; ...
        "Assigned CO2-to-MAP pathway ratio"; ...
        "CBFV output SNR (dB)"];
    diagnosticNames = [ ...
        "multipleMinusMapCoherence"; ...
        "multipleMinusPartialMapCoherence"];
    diagnosticLabels = [ ...
        "MISO minus MAP pairwise coherence"; ...
        "MISO minus MAP partial coherence given CO2"];
    referenceDuration = ...
        simulationResults.settings.observations.referenceDurationSeconds;
    referenceOutputSnr = ...
        simulationResults.settings.observations.referenceOutputSnrDb;
    if ismember("IsMainExperiment", string(observations.Properties.VariableNames))
        mainRows = observations.IsMainExperiment;
    else
        mainRows = true(height(observations), 1);
    end

    numPlots = numel(factorNames) + numel(diagnosticNames);
    manifestRows = cell(numPlots, 1);
    savedFileParts = cell(numPlots, 1);
    for factorIndex = 1:numel(factorNames)
        factorName = factorNames(factorIndex);
        dataRows = selectSimpleHeatmapRows( ...
            observations, mainRows, factorName, ...
            referenceDuration, referenceOutputSnr);
        if ~any(dataRows)
            error( ...
                "TFA:MissingSimpleSimulationRows", ...
                "No main-experiment rows are available for factor %s.", ...
                factorName);
        end

        [figureHandle, sourceData] = plotSimpleSimulationFrequencyMap( ...
            simulationResults, dataRows, factorName, ...
            factorLabels(factorIndex), "exact", "map", ...
            exportSettings.advantageColorLimit);
        plotName = "simple_map_" + lower(factorName);
        plotTitle = "MAP pathway accuracy advantage by " + ...
            factorLabels(factorIndex);
        captionDetails = createSimpleHeatmapCaptionDetails( ...
            simulationResults, factorLabels(factorIndex), ...
            referenceDuration, referenceOutputSnr);
        [manifestRows{factorIndex}, savedFileParts{factorIndex}] = ...
            exportApproachPaperPlot( ...
                figureHandle, sourceData, groupFolder, 1, ...
                plotName, plotTitle, exportSettings, captionDetails);
        closeApproachFigure(figureHandle);
    end

    diagnosticRows = mainRows & ...
        observations.DurationSeconds == referenceDuration & ...
        observations.OutputSNRdB == referenceOutputSnr;
    for diagnosticIndex = 1:numel(diagnosticNames)
        diagnosticName = diagnosticNames(diagnosticIndex);
        [figureHandle, sourceData] = plotSimpleSimulationDiagnosticMap( ...
            simulationResults, diagnosticRows, diagnosticName, ...
            diagnosticLabels(diagnosticIndex), "map", ...
            exportSettings.advantageColorLimit, 0:0.1:1);
        plotName = "simple_map_" + lower(diagnosticName);
        plotTitle = "MAP accuracy advantage by " + ...
            diagnosticLabels(diagnosticIndex);
        captionDetails = createSimpleDiagnosticCaptionDetails( ...
            diagnosticLabels(diagnosticIndex), ...
            referenceDuration, referenceOutputSnr);
        rowIndex = numel(factorNames) + diagnosticIndex;
        [manifestRows{rowIndex}, savedFileParts{rowIndex}] = ...
            exportApproachPaperPlot( ...
                figureHandle, sourceData, groupFolder, 1, ...
                plotName, plotTitle, exportSettings, captionDetails);
        closeApproachFigure(figureHandle);
    end

    exportResults = struct();
    exportResults.outputFolder = outputFolder;
    exportResults.groupFolder = string(groupFolder);
    exportResults.manifest = vertcat(manifestRows{:});
    exportResults.savedFiles = vertcat(savedFileParts{:});
    exportResults.factorNames = factorNames;
    exportResults.factorLabels = factorLabels;
    exportResults.diagnosticNames = diagnosticNames;
    exportResults.diagnosticLabels = diagnosticLabels;
    exportResults.referenceDurationSeconds = referenceDuration;
    exportResults.referenceOutputSnrDb = referenceOutputSnr;

end

function settings = createDefaultSimpleHeatmapExportSettings()
% createDefaultSimpleHeatmapExportSettings Set compact publication defaults.

    settings.widthInches = 7.2;
    settings.heightInches = 4.8;
    settings.pngResolution = 600;
    settings.savePdf = true;
    settings.savePng = true;
    settings.saveFigureSourceData = true;
    settings.saveCaptionFiles = true;
    settings.advantageColorLimit = 1.5;
    settings.captionContext.profileName = "simple";
    settings.captionContext.numFamilies = NaN;
    settings.captionContext.minimumValidN = 1;
    settings.captionContext.alpha = 0.05;
    settings.captionContext.multipleTestingMethod = ...
        "not used for this descriptive heatmap";
    settings.captionContext.errorFloor = NaN;

end

function settings = completeSimpleHeatmapExportSettings(settings)
% completeSimpleHeatmapExportSettings Fill only presentation defaults.

    defaults = createDefaultSimpleHeatmapExportSettings();
    fields = fieldnames(defaults);
    for fieldIndex = 1:numel(fields)
        fieldName = fields{fieldIndex};
        if ~isfield(settings, fieldName)
            settings.(fieldName) = defaults.(fieldName);
        end
    end
    if ~isfield(settings, "captionContext")
        settings.captionContext = defaults.captionContext;
    else
        contextFields = fieldnames(defaults.captionContext);
        for fieldIndex = 1:numel(contextFields)
            fieldName = contextFields{fieldIndex};
            if ~isfield(settings.captionContext, fieldName)
                settings.captionContext.(fieldName) = ...
                    defaults.captionContext.(fieldName);
            end
        end
    end

end

function validateSimpleSimulationResults(simulationResults)
% validateSimpleSimulationResults Catch an incompatible result structure.

    requiredTopLevel = ["observations" "frequency" "settings"];
    if ~isstruct(simulationResults) || ...
            ~all(isfield(simulationResults, requiredTopLevel))
        error( ...
            "TFA:InvalidSimpleSimulationResults", ...
            "The input must be a known-truth simulation result structure.");
    end
    requiredObservationFields = [ ...
        "ObservationID", "IsMainExperiment", ...
        "TargetInputCoherence", ...
        "AssignedPETCO2ToMAPBandGainRatio", "OutputSNRdB"];
    observationNames = string( ...
        simulationResults.observations.Properties.VariableNames);
    if ~all(ismember(requiredObservationFields, observationNames))
        error( ...
            "TFA:InvalidSimpleSimulationResults", ...
            "The observations table is missing a simple-study factor.");
    end
    if ~isfield(simulationResults.frequency, "map") || ...
            ~isfield(simulationResults.frequency.map, "sisoComplexError") || ...
            ~isfield(simulationResults.frequency.map, "misoComplexError")
        error( ...
            "TFA:InvalidSimpleSimulationResults", ...
            "MAP SISO and MISO frequency errors are required.");
    end
    requiredDiagnostics = [ ...
        "multipleMinusMapCoherence", ...
        "multipleMinusPartialMapCoherence"];
    if ~all(isfield(simulationResults.frequency, requiredDiagnostics))
        error( ...
            "TFA:InvalidSimpleSimulationResults", ...
            "The frequency-wise MISO coherence diagnostics are required.");
    end

end

function dataRows = selectSimpleHeatmapRows( ...
    observations, mainRows, factorName, referenceDuration, referenceOutputSnr)
% selectSimpleHeatmapRows Hold the other primary conditions fixed.

    if factorName == "OutputSNRdB"
        dataRows = mainRows & ...
            observations.DurationSeconds == referenceDuration;
    else
        dataRows = mainRows & ...
            observations.DurationSeconds == referenceDuration & ...
            observations.OutputSNRdB == referenceOutputSnr;
    end

end

function details = createSimpleHeatmapCaptionDetails( ...
    simulationResults, factorLabel, referenceDuration, referenceOutputSnr)
% createSimpleHeatmapCaptionDetails Describe the fixed comparison context.

    details = struct();
    details.referenceContext = compose( ...
        "Reference duration: %.3g s | reference CBFV SNR: %.3g dB", ...
        referenceDuration, referenceOutputSnr);
    details.groupingDescription = ...
        "The factor axis uses exact configured simple-study values";
    details.displayType = "heatmap";
    details.includesModelAdvantage = true;
    details.adjustmentFamily = ...
        "descriptive frequency-by-factor cells; no significance markers";
    details.factorLabel = factorLabel;
    if isfield(simulationResults, "numFamilies")
        details.numFamilies = simulationResults.numFamilies;
    end

end

function details = createSimpleDiagnosticCaptionDetails( ...
    diagnosticLabel, referenceDuration, referenceOutputSnr)
% createSimpleDiagnosticCaptionDetails Describe a diagnostic heatmap.

    details = struct();
    details.referenceContext = compose( ...
        "Reference duration: %.3g s | reference CBFV SNR: %.3g dB", ...
        referenceDuration, referenceOutputSnr);
    details.groupingDescription = ...
        "The vertical axis uses fixed 0.1-wide bins for the frequency-wise diagnostic";
    details.displayType = "heatmap";
    details.includesModelAdvantage = true;
    details.adjustmentFamily = ...
        "descriptive diagnostic-by-frequency cells; no significance markers";
    details.factorLabel = diagnosticLabel;

end
