function [figureHandle, sourceData] = plotApproachFigure3KnownTruth( ...
    simulationResults, selectedRidgeLambda)
% plotApproachFigure3KnownTruth Compare estimator accuracy against truth.

    trials = simulationResults.trials;
    selectedRows = trials.Estimator ~= "MISO ridge" | ...
        trials.Lambda == selectedRidgeLambda;
    data = trials(selectedRows, :);

    estimatorOrder = [ ...
        "SISO"; "MISO unregularized"; "MISO ridge"];
    metricNames = [ ...
        "MeanAbsoluteGainError"
        "MeanAbsolutePhaseErrorRadians"
        "NormalizedComplexError"];
    metricLabels = [ ...
        "Mean absolute gain error"
        "Mean absolute phase error (rad)"
        "Normalized complex error"];
    pathways = ["MAP"; "CO2"];

    figureHandle = figure( ...
        "Name", "Approach Paper Figure 3", ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 3, ...
        "TileSpacing", "compact", "Padding", "compact");

    for pathwayIndex = 1:2
        for metricIndex = 1:3
            axesHandle = nexttile(layout);
            rowMask = data.Pathway == pathways(pathwayIndex);
            estimatorCategory = categorical( ...
                data.Estimator(rowMask), estimatorOrder, ...
                estimatorOrder);
            boxchart(axesHandle, estimatorCategory, ...
                data.(metricNames(metricIndex))(rowMask));
            ylabel(axesHandle, metricLabels(metricIndex));
            title(axesHandle, ...
                char('A' + (pathwayIndex - 1)*3 + metricIndex - 1) + ...
                "  " + pathways(pathwayIndex));
            grid(axesHandle, "on");
            axesHandle.XTickLabelRotation = 20;
        end
    end

    sourceData = data;

end
