function markSignificantCurvePoints( ...
    axesHandle, x, y, adjustedP, alpha)
% markSignificantCurvePoints Outline means with BH-adjusted P below alpha.

    significant = isfinite(x) & isfinite(y) & ...
        isfinite(adjustedP) & adjustedP < alpha;
    if ~any(significant)
        return
    end

    hold(axesHandle, "on");
    scatter(axesHandle, x(significant), y(significant), ...
        54, "o", "MarkerEdgeColor", "black", ...
        "MarkerFaceColor", "none", "LineWidth", 1.4, ...
        "HandleVisibility", "off");

end
