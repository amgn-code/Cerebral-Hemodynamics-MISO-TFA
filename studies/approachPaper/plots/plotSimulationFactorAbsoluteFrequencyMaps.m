function [figureHandle, sourceData] = ...
    plotSimulationFactorAbsoluteFrequencyMaps( ...
        simulationResults, dataRows, factorName, factorLabel, ...
        groupingMode, modelName, titleContext)
% plotSimulationFactorAbsoluteFrequencyMaps Show mean model error.

    if nargin < 7
        titleContext = "";
    end

    observations = simulationResults.observations(dataRows, :);
    observationColumns = observations.ObservationID;
    factorValues = observations.(factorName);
    frequency = simulationResults.frequency;
    errorFloor = simulationResults.settings.metrics.errorFloor;
    modelName = lower(string(modelName));
    otherModel = getOtherModel(modelName);
    groupingSettings = simulationResults.settings.grouping;
    minimumValidN = groupingSettings.minimumValidN;

    pathways = [ ...
        "map"; "map"; "map"; ...
        "co2"; "co2"; "co2"];
    errorTypes = [ ...
        "complex"; "gain"; "phase"; ...
        "complex"; "gain"; "phase"];
    panelTitles = [ ...
        "A  MAP normalized squared complex error"
        "B  MAP absolute gain error"
        "C  MAP wrapped-phase error (degrees)"
        "D  PETCO2 normalized squared complex error"
        "E  PETCO2 absolute gain error"
        "F  PETCO2 wrapped-phase error (degrees)"];

    figureHandle = figure( ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 3, ...
        "TileSpacing", "compact", "Padding", "compact");
    factorTitle = getSimulationFactorTitle( ...
        factorName, factorLabel);
    figureTitle = ...
        "Mean frequency-resolved " + upper(modelName) + ...
        " error by " + factorTitle;
    if strlength(titleContext) > 0
        figureTitle = figureTitle + newline + titleContext;
    end
    title(layout, figureTitle);

    sourceData = struct();
    metadataRows = cell(numel(pathways), 1);
    for metricIndex = 1:numel(pathways)
        pathway = pathways(metricIndex);
        errorType = errorTypes(metricIndex);

        modelValues = getSimulationFrequencyError( ...
            frequency, pathway, modelName, errorType, errorFloor);
        modelValues = modelValues(:, observationColumns);
        otherValues = getSimulationFrequencyError( ...
            frequency, pathway, otherModel, errorType, errorFloor);
        otherValues = otherValues(:, observationColumns);

        if errorType == "phase"
            modelValues = rad2deg(modelValues);
            otherValues = rad2deg(otherValues);
        end

        summary = summarizeSimulationFrequencyMap( ...
            factorValues, modelValues, factorName, ...
            groupingMode, groupingSettings);
        otherSummary = summarizeSimulationFrequencyMap( ...
            factorValues, otherValues, factorName, ...
            groupingMode, groupingSettings);
        colorLimits = calculateSharedErrorColorLimits( ...
            summary.mean, otherSummary.mean);
        plotValues = summary.mean;
        plotValues(isfinite(plotValues) & plotValues <= 0) = ...
            colorLimits(1);
        displayMask = isfinite(summary.mean) & ...
            summary.validN >= minimumValidN;

        [plotCenters, tickValues, tickLabels] = ...
            prepareSimulationHeatmapAxis(summary.factorLabels);
        axesHandle = nexttile(layout);
        imageHandle = imagesc( ...
            axesHandle, frequency.frequencyHz, ...
            plotCenters, plotValues);
        imageHandle.AlphaData = displayMask;
        axesHandle.Color = [0.92 0.92 0.92];
        axesHandle.ColorScale = "log";
        set(axesHandle, "YDir", "normal");
        xlim( ...
            axesHandle, ...
            simulationResults.settings.frequencyRangeHz);
        clim(axesHandle, colorLimits);
        colormap(axesHandle, modelErrorColormap(modelName));
        colorbarHandle = colorbar(axesHandle);
        colorbarHandle.Label.String = ...
            getColorbarLabel(errorType);
        xlabel(axesHandle, "Frequency (Hz)");
        ylabel(axesHandle, factorLabel);
        axesHandle.YTick = tickValues;
        axesHandle.YTickLabel = tickLabels;
        title( ...
            axesHandle, panelTitles(metricIndex), ...
            "FontSize", 9);

        fieldName = pathway + "_" + errorType;
        sourceData.(fieldName) = createLongSourceTable( ...
            frequency.frequencyHz, summary);
        metadataRows{metricIndex} = table( ...
            metricIndex, upper(modelName), upper(pathway), ...
            errorType, colorLimits(1), colorLimits(2), ...
            string(getColorbarLabel(errorType)), ...
            'VariableNames', { ...
                'Panel', 'Model', 'Pathway', 'ErrorType', ...
                'ColorLimitLower', 'ColorLimitUpper', 'ColorbarLabel'});
    end
    sourceData.metadata = vertcat(metadataRows{:});

end

function otherModel = getOtherModel(modelName)
% getOtherModel Return the model used to match color limits.

    if modelName == "miso"
        otherModel = "siso";
    elseif modelName == "siso"
        otherModel = "miso";
    else
        error( ...
            "TFA:UnknownSimulationModel", ...
            "modelName must be MISO or SISO.");
    end

end

function colorLimits = calculateSharedErrorColorLimits( ...
    firstValues, secondValues)
% calculateSharedErrorColorLimits Match paired MISO and SISO panels.

    combined = [firstValues(:); secondValues(:)];
    positive = combined(isfinite(combined) & combined > 0);
    if isempty(positive)
        colorLimits = [1e-12 1];
        return
    end

    lowerLimit = min(positive);
    upperLimit = max(positive);
    if lowerLimit == upperLimit
        lowerLimit = lowerLimit/10;
        upperLimit = upperLimit*10;
    end
    colorLimits = [lowerLimit upperLimit];

end

function labelText = getColorbarLabel(errorType)
% getColorbarLabel Describe the mean value represented by color.

    switch errorType
        case "complex"
            labelText = "Mean normalized squared complex error";
        case "gain"
            labelText = "Mean absolute gain error";
        case "phase"
            labelText = "Mean wrapped-phase error (degrees)";
    end

end

function sourceTable = createLongSourceTable( ...
    frequencyHz, summary)
% createLongSourceTable Store one heatmap in tidy source-data form.

    factorValues = summary.factorCenters;
    numFactors = numel(factorValues);
    numFrequencies = numel(frequencyHz);
    factorColumn = repelem(factorValues(:), numFrequencies);
    factorColumn = factorColumn(:);
    sourceTable = table( ...
        factorColumn, ...
        reshape(repelem( ...
            summary.factorLabels(:), numFrequencies), [], 1), ...
        reshape(repelem( ...
            summary.factorLower(:), numFrequencies), [], 1), ...
        reshape(repelem( ...
            summary.factorUpper(:), numFrequencies), [], 1), ...
        repmat(frequencyHz(:), numFactors, 1), ...
        reshape(summary.mean.', [], 1), ...
        reshape(summary.sd.', [], 1), ...
        reshape(summary.validN.', [], 1), ...
        reshape(repelem( ...
            summary.groupN(:), numFrequencies), [], 1), ...
        'VariableNames', { ...
            'FactorValue', 'FactorGroup', ...
            'FactorLower', 'FactorUpper', 'FrequencyHz', ...
            'Mean', 'SD', 'ValidN', 'GroupN'});

end
