function markSignificantHeatmapCells( ...
    axesHandle, xValues, yValues, adjustedP, alpha)
% markSignificantHeatmapCells Mark BH-significant heatmap cells.

    [xGrid, yGrid] = meshgrid(xValues, yValues);
    significant = isfinite(adjustedP) & adjustedP < alpha;
    if ~any(significant, "all")
        return
    end

    hold(axesHandle, "on");
    scatter(axesHandle, xGrid(significant), yGrid(significant), ...
        8, "black", "filled", ...
        "MarkerFaceAlpha", 0.80, ...
        "HandleVisibility", "off");

end
