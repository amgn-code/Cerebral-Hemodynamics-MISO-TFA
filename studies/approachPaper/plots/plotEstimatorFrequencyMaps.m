function [figureHandle, sourceData] = plotEstimatorFrequencyMaps( ...
    data, factorName, factorLabel, displayMode, ...
    minimumValidN, colorLimit, ~, frequencyRangeHz, ...
    statisticsSettings)
% plotEstimatorFrequencyMaps Plot native Welch frequency grids.
%
% Each square is an estimated frequency bin. Window-length results are not
% interpolated onto an artificial common frequency grid.

    if nargin < 8
        frequencyRangeHz = [ ...
            min(data.FrequencyHz, [], "omitnan"), ...
            max(data.FrequencyHz, [], "omitnan")];
    end
    if nargin < 9 || isempty(statisticsSettings)
        statisticsSettings.alpha = 0.05;
        statisticsSettings.minimumValidN = 3;
    end
    displayMode = lower(string(displayMode));
    factorName = string(factorName);

    [metricNames, panelTitles, figureTitle] = ...
        getDisplayDefinition(displayMode);
    factorValues = unique(data.(factorName), "sorted");
    [plotFactorValues, tickValues, tickLabels] = ...
        preparePlotFactorValues(factorValues);

    if ismember("MeetsMinimumWelchWindows", ...
            string(data.Properties.VariableNames))
        for factorIndex = 1:numel(factorValues)
            rows = data.(factorName) == factorValues(factorIndex);
            if any(rows) && ~all(data.MeetsMinimumWelchWindows(rows))
                tickLabels(plotFactorValues == ...
                    prepareOneValue(factorValues(factorIndex))) = ...
                    tickLabels(plotFactorValues == ...
                    prepareOneValue(factorValues(factorIndex))) + "*";
            end
        end
    end

    figureHandle = figure("Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 3, ...
        "TileSpacing", "compact", "Padding", "compact");
    title(layout, figureTitle + " by " + factorLabel, ...
        "FontSize", 12);
    sourceData = struct();
    lastAxes = gobjects(1);

    for metricIndex = 1:numel(metricNames)
        metricName = metricNames(metricIndex);
        runInference = displayMode == "advantage";
        summary = summarizeNativeGrid( ...
            data, factorName, metricName, ...
            runInference, statisticsSettings);
        if contains(metricName, "PhaseErrorRadians")
            summary.Mean = rad2deg(summary.Mean);
            summary.SD = rad2deg(summary.SD);
        end

        [rowFound, factorLocation] = ismember( ...
            summary.FactorValue, factorValues);
        yValues = NaN(height(summary), 1);
        yValues(rowFound) = plotFactorValues(factorLocation(rowFound));
        valid = summary.ValidN >= minimumValidN & ...
            isfinite(summary.Mean);

        axesHandle = nexttile(layout);
        lastAxes = axesHandle;
        scatter(axesHandle, summary.FrequencyHz(valid), ...
            yValues(valid), 60, summary.Mean(valid), ...
            "s", "filled", "MarkerEdgeColor", "none");
        if runInference
            significant = valid & summary.IsSignificant;
            hold(axesHandle, "on");
            scatter(axesHandle, ...
                summary.FrequencyHz(significant), ...
                yValues(significant), 10, "black", "filled", ...
                "HandleVisibility", "off");
        end
        axesHandle.YTick = tickValues;
        axesHandle.YTickLabel = tickLabels;
        applyFactorAxisPadding(axesHandle, plotFactorValues);
        if ismember(metricIndex, [1 4])
            ylabel(axesHandle, factorLabel);
        else
            axesHandle.YTickLabel = strings(size(tickLabels));
        end
        xlabel(axesHandle, "Frequency (Hz)");
        xlim(axesHandle, frequencyRangeHz);
        title(axesHandle, panelTitles(metricIndex), "FontSize", 9);
        grid(axesHandle, "on");

        if displayMode == "advantage"
            colormap(axesHandle, misoAdvantageColormap());
            clim(axesHandle, [-colorLimit colorLimit]);
        else
            colormap(axesHandle, modelErrorColormap(displayMode));
            finiteMean = summary.Mean(isfinite(summary.Mean));
            if ~isempty(finiteMean)
                upperLimit = max(finiteMean);
                if upperLimit > 0
                    clim(axesHandle, [0 upperLimit]);
                end
            end
            colorbar(axesHandle);
        end

        fieldName = matlab.lang.makeValidName(metricName);
        summary.FactorGroup = compose("%.3g", summary.FactorValue);
        sourceData.(fieldName) = movevars( ...
            summary, "FactorGroup", "After", "FactorValue");
    end

    if displayMode == "advantage"
        colorbarHandle = colorbar(lastAxes);
        colorbarHandle.Layout.Tile = "east";
        colorbarHandle.Label.String = ...
            "Mean log10(SISO error / MISO error)";
    end

end

function value = prepareOneValue(rawValue)
% prepareOneValue Use the same Inf replacement as the complete axis.

    [value, ~, ~] = preparePlotFactorValues(rawValue);

end

function [metricNames, panelTitles, figureTitle] = ...
    getDisplayDefinition(displayMode)
% getDisplayDefinition Select the six pathway metrics for one figure.

    switch displayMode
        case {"miso", "siso"}
            modelName = upper(displayMode);
            metricNames = [ ...
                "MAP" + modelName + "ComplexError"
                "MAP" + modelName + "GainError"
                "MAP" + modelName + "PhaseErrorRadians"
                "CO2" + modelName + "ComplexError"
                "CO2" + modelName + "GainError"
                "CO2" + modelName + "PhaseErrorRadians"];
            panelTitles = [ ...
                "A  MAP normalized squared" + newline + "complex error"
                "B  MAP absolute" + newline + "gain error"
                "C  MAP absolute phase" + newline + "error (degrees)"
                "D  PETCO2 normalized squared" + newline + "complex error"
                "E  PETCO2 absolute" + newline + "gain error"
                "F  PETCO2 absolute phase" + newline + "error (degrees)"];
            figureTitle = ...
                modelName + " frequency-resolved pathway error";
        case "advantage"
            metricNames = [ ...
                "MAPComplexAdvantage"
                "MAPGainAdvantage"
                "MAPPhaseAdvantage"
                "CO2ComplexAdvantage"
                "CO2GainAdvantage"
                "CO2PhaseAdvantage"];
            panelTitles = [ ...
                "A  MAP complex" + newline + "model advantage"
                "B  MAP gain" + newline + "model advantage"
                "C  MAP phase" + newline + "model advantage"
                "D  PETCO2 complex" + newline + "model advantage"
                "E  PETCO2 gain" + newline + "model advantage"
                "F  PETCO2 phase" + newline + "model advantage"];
            figureTitle = "Frequency-resolved model advantage";
        otherwise
            error( ...
                "TFA:UnknownEstimatorMapMode", ...
                "displayMode must be ""miso"", ""siso"", or ""advantage"".");
    end

end

function applyFactorAxisPadding(axesHandle, factorValues)
% applyFactorAxisPadding Keep markers clear of panel titles and x labels.

    factorValues = factorValues(isfinite(factorValues));
    if isempty(factorValues)
        return
    end
    lowerValue = min(factorValues);
    upperValue = max(factorValues);
    valueRange = upperValue - lowerValue;
    if valueRange == 0
        padding = max(abs(lowerValue)*0.10, 0.5);
    else
        padding = 0.08*valueRange;
    end
    ylim(axesHandle, [lowerValue - padding, upperValue + padding]);

end

function summary = summarizeNativeGrid( ...
    data, factorName, metricName, runInference, statisticsSettings)
% summarizeNativeGrid Calculate descriptive and inferential bin summaries.

    pairTable = unique(data(:, [factorName "FrequencyHz"]), "rows");
    numPairs = height(pairTable);
    meanValue = NaN(numPairs, 1);
    sdValue = NaN(numPairs, 1);
    validN = zeros(numPairs, 1);
    groupN = zeros(numPairs, 1);
    standardError = NaN(numPairs, 1);
    ciLower = NaN(numPairs, 1);
    ciUpper = NaN(numPairs, 1);
    rawP = NaN(numPairs, 1);

    for pairIndex = 1:numPairs
        rows = data.(factorName) == pairTable.(factorName)(pairIndex) & ...
            data.FrequencyHz == pairTable.FrequencyHz(pairIndex);
        values = data.(metricName)(rows);
        meanValue(pairIndex) = mean(values, "omitnan");
        sdValue(pairIndex) = std(values, "omitnan");
        validN(pairIndex) = nnz(isfinite(values));
        groupRows = data.(factorName) == ...
            pairTable.(factorName)(pairIndex);
        if ismember("FamilyID", string(data.Properties.VariableNames))
            groupN(pairIndex) = numel(unique(data.FamilyID(groupRows)));
        else
            groupN(pairIndex) = nnz(groupRows);
        end
        if runInference
            current = calculateSimulationAdvantageStatistics( ...
                values, statisticsSettings.alpha, ...
                statisticsSettings.minimumValidN);
            standardError(pairIndex) = current.standardError;
            ciLower(pairIndex) = current.ciLower;
            ciUpper(pairIndex) = current.ciUpper;
            rawP(pairIndex) = current.rawP;
        end
    end

    summary = table( ...
        pairTable.(factorName), pairTable.FrequencyHz, ...
        meanValue, sdValue, validN, groupN, ...
        'VariableNames', { ...
            'FactorValue', 'FrequencyHz', ...
            'Mean', 'SD', 'ValidN', 'GroupN'});
    if runInference
        summary.StandardError = standardError;
        summary.CILower = ciLower;
        summary.CIUpper = ciUpper;
        summary.RawP = rawP;
        summary.BHAdjustedP = ...
            adjustPValuesBenjaminiHochberg(rawP);
        summary.IsSignificant = isfinite(summary.BHAdjustedP) & ...
            summary.BHAdjustedP < statisticsSettings.alpha;
        summary.GeometricSISOToMISOErrorRatio = 10.^meanValue;
    end

end
