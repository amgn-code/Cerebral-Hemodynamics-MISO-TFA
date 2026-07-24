function [figureHandle, sourceData] = ...
    plotApproachFigure2Identifiability(simulationResults)
% plotApproachFigure2Identifiability Show where two-input recovery is hard.

    trials = simulationResults.trials;
    selected = trials.Estimator == "MISO unregularized" & ...
        trials.Pathway == "CO2";
    data = trials(selected, :);

    correlations = unique(data.InputCorrelation, "sorted");
    co2InputSds = unique(data.CO2InputSD, "sorted");
    coherenceMatrix = createMeanMatrix( ...
        data, correlations, co2InputSds, "RealizedInputCoherence");
    errorMatrix = createMeanMatrix( ...
        data, correlations, co2InputSds, "NormalizedComplexError");

    figureHandle = figure( ...
        "Name", "Approach Paper Figure 2", ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 2, ...
        "TileSpacing", "compact", "Padding", "compact");

    axesHandle = nexttile(layout);
    imagesc(axesHandle, correlations, co2InputSds, coherenceMatrix);
    set(axesHandle, "YDir", "normal");
    colorbar(axesHandle);
    xlabel(axesHandle, "Target input correlation");
    ylabel(axesHandle, "CO2 input SD");
    title(axesHandle, "A  Realized input coherence");

    axesHandle = nexttile(layout);
    imagesc(axesHandle, correlations, co2InputSds, ...
        log10(errorMatrix));
    set(axesHandle, "YDir", "normal");
    colorbar(axesHandle);
    xlabel(axesHandle, "Target input correlation");
    ylabel(axesHandle, "CO2 input SD");
    title(axesHandle, "B  log10 CO2 coefficient error");

    axesHandle = nexttile(layout);
    scatter(axesHandle, data.RealizedInputCoherence, ...
        data.MedianNormalizedConditionNumber, 16, ...
        data.CO2InputSD, "filled", "MarkerFaceAlpha", 0.45);
    set(axesHandle, "YScale", "log");
    xlabel(axesHandle, "Realized input coherence");
    ylabel(axesHandle, "Normalized condition number");
    title(axesHandle, "C  Conditioning");
    colorbar(axesHandle);

    axesHandle = nexttile(layout);
    scatter(axesHandle, data.RealizedInputCoherence, ...
        data.MedianNormalizedDeterminant, 16, ...
        data.NormalizedComplexError, "filled", ...
        "MarkerFaceAlpha", 0.45);
    hold(axesHandle, "on");
    referenceX = linspace(0, 1, 100);
    plot(axesHandle, referenceX, 1 - referenceX, "k--", ...
        "LineWidth", 1.2);
    xlabel(axesHandle, "Realized input coherence");
    ylabel(axesHandle, "Normalized determinant");
    title(axesHandle, "D  Remaining independent information");
    colorbar(axesHandle);

    sourceData = data;

end

function outputMatrix = createMeanMatrix( ...
    data, xValues, yValues, variableName)
% createMeanMatrix Average a table variable over two selected factors.

    outputMatrix = NaN(numel(yValues), numel(xValues));
    for yIndex = 1:numel(yValues)
        for xIndex = 1:numel(xValues)
            rowMask = data.InputCorrelation == xValues(xIndex) & ...
                data.CO2InputSD == yValues(yIndex);
            outputMatrix(yIndex, xIndex) = mean( ...
                data.(variableName)(rowMask), "omitnan");
        end
    end

end
