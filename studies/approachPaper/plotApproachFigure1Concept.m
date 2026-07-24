function figureHandle = plotApproachFigure1Concept()
% plotApproachFigure1Concept Draw the SISO and MISO conceptual comparison.

    figureHandle = figure( ...
        "Name", "Approach Paper Figure 1", ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 1, 2, ...
        "TileSpacing", "compact", "Padding", "compact");

    firstAxes = nexttile(layout);
    drawModelPanel(firstAxes, false);
    title(firstAxes, "SISO: one input at a time");

    secondAxes = nexttile(layout);
    drawModelPanel(secondAxes, true);
    title(secondAxes, "MISO: both inputs estimated together");

end

function drawModelPanel(axesHandle, isMiso)
% drawModelPanel Draw one simple model diagram.

    cla(axesHandle);
    axis(axesHandle, [0 1 0 1]);
    axis(axesHandle, "off");
    hold(axesHandle, "on");

    rectangle(axesHandle, ...
        "Position", [0.08 0.62 0.22 0.13], ...
        "Curvature", 0.08, "FaceColor", [0.85 0.93 1]);
    text(axesHandle, 0.19, 0.685, "MAP", ...
        "HorizontalAlignment", "center");
    rectangle(axesHandle, ...
        "Position", [0.08 0.25 0.22 0.13], ...
        "Curvature", 0.08, "FaceColor", [1 0.90 0.82]);
    text(axesHandle, 0.19, 0.315, "CO2", ...
        "HorizontalAlignment", "center");
    rectangle(axesHandle, ...
        "Position", [0.70 0.43 0.22 0.13], ...
        "Curvature", 0.08, "FaceColor", [0.88 0.96 0.86]);
    text(axesHandle, 0.81, 0.495, "CBFV", ...
        "HorizontalAlignment", "center");

    if isMiso
        drawArrow(axesHandle, [0.30 0.685], [0.70 0.52], "k");
        drawArrow(axesHandle, [0.30 0.315], [0.70 0.48], "k");
        text(axesHandle, 0.49, 0.66, "HMAP|CO2");
        text(axesHandle, 0.49, 0.34, "HCO2|MAP");
    else
        drawArrow(axesHandle, [0.30 0.685], [0.70 0.52], "k");
        plot(axesHandle, [0.30 0.70], [0.315 0.48], ...
            "Color", [0.65 0.65 0.65], "LineStyle", "--");
        text(axesHandle, 0.49, 0.66, "HMAP");
        text(axesHandle, 0.49, 0.34, ...
            "CO2 not modeled", "Color", [0.45 0.45 0.45]);
    end

end

function drawArrow(axesHandle, startPoint, endPoint, color)
% drawArrow Draw one directed pathway in axes coordinates.

    quiver(axesHandle, startPoint(1), startPoint(2), ...
        endPoint(1) - startPoint(1), ...
        endPoint(2) - startPoint(2), 0, ...
        "Color", color, "LineWidth", 1.4, ...
        "MaxHeadSize", 0.15);

end
