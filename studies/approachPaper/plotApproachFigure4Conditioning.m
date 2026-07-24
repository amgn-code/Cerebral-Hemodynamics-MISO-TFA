function [figureHandle, sourceData] = ...
    plotApproachFigure4Conditioning(simulationResults)
% plotApproachFigure4Conditioning Relate diagnostics and ridge to error.

    trials = simulationResults.trials;
    direct = trials( ...
        trials.Estimator == "MISO unregularized" & ...
        trials.Pathway == "CO2", :);
    ridge = trials( ...
        trials.Estimator == "MISO ridge" & ...
        trials.Pathway == "CO2", :);

    figureHandle = figure( ...
        "Name", "Approach Paper Figure 4", ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 2, ...
        "TileSpacing", "compact", "Padding", "compact");

    axesHandle = nexttile(layout);
    scatter(axesHandle, direct.MedianNormalizedConditionNumber, ...
        direct.NormalizedComplexError, 14, ...
        direct.RealizedInputCoherence, "filled", ...
        "MarkerFaceAlpha", 0.4);
    set(axesHandle, "XScale", "log", "YScale", "log");
    xlabel(axesHandle, "Normalized condition number");
    ylabel(axesHandle, "Normalized complex error");
    title(axesHandle, "A  Scale-invariant diagnostic");
    colorbar(axesHandle);

    axesHandle = nexttile(layout);
    scatter(axesHandle, direct.MedianRawConditionNumber, ...
        direct.NormalizedComplexError, 14, direct.CO2InputSD, ...
        "filled", "MarkerFaceAlpha", 0.4);
    set(axesHandle, "XScale", "log", "YScale", "log");
    xlabel(axesHandle, "Raw condition number");
    ylabel(axesHandle, "Normalized complex error");
    title(axesHandle, "B  Unit-dependent diagnostic");
    colorbar(axesHandle);

    axesHandle = nexttile(layout);
    scatter(axesHandle, ridge.Lambda, ...
        ridge.NormalizedComplexError, 14, ...
        ridge.MedianNormalizedConditionNumber, "filled", ...
        "MarkerFaceAlpha", 0.35);
    set(axesHandle, "XScale", "log", "YScale", "log");
    xlabel(axesHandle, "Standardized ridge lambda");
    ylabel(axesHandle, "Normalized complex error");
    title(axesHandle, "C  Coefficient error");
    colorbar(axesHandle);

    axesHandle = nexttile(layout);
    scatter(axesHandle, ridge.Lambda, ...
        ridge.OutOfSampleNormalizedError, 14, ...
        ridge.MedianNormalizedConditionNumber, "filled", ...
        "MarkerFaceAlpha", 0.35);
    set(axesHandle, "XScale", "log", "YScale", "log");
    xlabel(axesHandle, "Standardized ridge lambda");
    ylabel(axesHandle, "Independent validation error");
    title(axesHandle, "D  Prediction on new data");
    colorbar(axesHandle);

    sourceData = [direct; ridge];

end
