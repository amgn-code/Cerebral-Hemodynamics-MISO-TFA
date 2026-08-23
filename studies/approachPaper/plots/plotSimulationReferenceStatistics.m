function [figureHandle, sourceData] = ...
    plotSimulationReferenceStatistics(simulationResults)
% plotSimulationReferenceStatistics Show the six reference comparisons.

    sourceData = createSimulationReferenceStatistics(simulationResults);
    reference = simulationResults.observations( ...
        simulationResults.observations.IsReferenceObservation, :);
    durationSeconds = unique(reference.DurationSeconds);
    outputSnrDb = unique(reference.OutputSNRdB);
    alpha = simulationResults.settings.statistics.alpha;

    figureHandle = figure("Color", "white", "Visible", "off");
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");

    y = (height(sourceData):-1:1)';
    for rowIndex = 1:height(sourceData)
        meanValue = sourceData.MeanAdvantage(rowIndex);
        lower = sourceData.CILower(rowIndex);
        upper = sourceData.CIUpper(rowIndex);
        if ~all(isfinite([meanValue lower upper]))
            continue
        end

        if meanValue >= 0
            pointColor = [0 0.4470 0.7410];
        else
            pointColor = [0.8500 0.3250 0.0980];
        end
        plot(axesHandle, [lower upper], y(rowIndex)*[1 1], ...
            "Color", pointColor, "LineWidth", 2);
        scatter(axesHandle, meanValue, y(rowIndex), ...
            45, pointColor, "filled");
        if sourceData.IsSignificant(rowIndex)
            scatter(axesHandle, meanValue, y(rowIndex), ...
                80, "o", "MarkerEdgeColor", "black", ...
                "MarkerFaceColor", "none", "LineWidth", 1.4);
        end
    end

    xline(axesHandle, 0, "k:");
    axesHandle.YTick = 1:height(sourceData);
    axesHandle.YTickLabel = flipud(sourceData.DisplayLabel);
    ylim(axesHandle, [0.5 height(sourceData) + 0.5]);
    xlabel(axesHandle, ...
        "Mean model advantage: log10(SISO error / MISO error)");
    ylabel(axesHandle, "Transfer-function error outcome");
    title(axesHandle, ...
        "Reference-condition MISO versus SISO statistical summary" + ...
        newline + compose( ...
            "%.3g s, CBFV SNR = %.3g dB | Lines: 95%% CI | Black ring: reported P < %.3g", ...
            durationSeconds(1), outputSnrDb(1), alpha));
    grid(axesHandle, "on");

end
