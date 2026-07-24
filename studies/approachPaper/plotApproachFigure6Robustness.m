function [figureHandle, sourceData] = ...
    plotApproachFigure6Robustness(robustnessResults)
% plotApproachFigure6Robustness Summarize empirical falsification checks.

    figureHandle = figure( ...
        "Name", "Approach Paper Figure 6", ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 2, ...
        "TileSpacing", "compact", "Padding", "compact");

    axesHandle = nexttile(layout);
    surrogate = robustnessResults.surrogateGroupDistribution;
    selectedSurrogate = table();
    if hasVariables(surrogate, ["Pathway"; "Band"])
        selected = surrogate.Pathway == "MAP" & ...
            surrogate.Band == "VVLF";
        selectedSurrogate = surrogate(selected, :);
        nullRows = selectedSurrogate.ResultType == "Surrogate null";
        histogram(axesHandle, ...
            selectedSurrogate.GroupMeanDifference(nullRows), ...
            "FaceColor", [0.70 0.70 0.70]);
        hold(axesHandle, "on");
        observedValue = selectedSurrogate.GroupMeanDifference( ...
            selectedSurrogate.ResultType == "Observed");
        if ~isempty(observedValue)
            xline(axesHandle, observedValue, ...
                "Color", [0 0.4470 0.7410], ...
                "LineWidth", 1.8, "Label", "Observed");
        end
    else
        showNoData(axesHandle);
    end
    xlabel(axesHandle, "Group mean MISO minus SISO MAP gain");
    ylabel(axesHandle, "Surrogate count");
    title(axesHandle, "A  CO2 circular-shift null");

    axesHandle = nexttile(layout);
    delay = robustnessResults.delaySummary;
    selectedDelay = table();
    if hasVariables(delay, ["Pathway"; "Band"])
        selected = delay.Pathway == "MAP" & delay.Band == "VVLF";
        selectedDelay = delay(selected, :);
        boxchart(axesHandle, ...
            categorical(selectedDelay.AssumedCO2DelaySeconds), ...
            selectedDelay.MISOminusSISO);
        yline(axesHandle, 0, "k:");
    else
        showNoData(axesHandle);
    end
    xlabel(axesHandle, "Assumed CO2 delay (s)");
    ylabel(axesHandle, "MISO minus SISO MAP gain");
    title(axesHandle, "B  Delay sensitivity");

    axesHandle = nexttile(layout);
    sensitivity = robustnessResults.sensitivitySummary;
    selectedSensitivity = table();
    if hasVariables(sensitivity, ["Pathway"; "Band"])
        selected = sensitivity.Pathway == "MAP" & ...
            sensitivity.Band == "VVLF";
        selectedSensitivity = sensitivity(selected, :);
        boxchart(axesHandle, categorical(selectedSensitivity.Variant), ...
            selectedSensitivity.MISOminusSISO);
        yline(axesHandle, 0, "k:");
    else
        showNoData(axesHandle);
    end
    ylabel(axesHandle, "MISO minus SISO MAP gain");
    title(axesHandle, "C  Analysis-setting sensitivity");
    axesHandle.XTickLabelRotation = 25;

    axesHandle = nexttile(layout);
    lambda = robustnessResults.lambdaSummary;
    selectedLambda = table();
    if hasVariables(lambda, ["Pathway"; "Band"])
        selected = lambda.Pathway == "MAP" & lambda.Band == "VVLF";
        selectedLambda = lambda(selected, :);
        positiveRows = selectedLambda.Lambda > 0;
        scatter(axesHandle, ...
            selectedLambda.Lambda(positiveRows), ...
            selectedLambda.MISOGain(positiveRows), ...
            16, "filled", "MarkerFaceAlpha", 0.35);
        set(axesHandle, "XScale", "log");
    else
        showNoData(axesHandle);
    end
    xlabel(axesHandle, "Standardized ridge lambda");
    ylabel(axesHandle, "MISO MAP gain");
    title(axesHandle, "D  Regularization path");
    grid(axesHandle, "on");

    sourceData.surrogate = selectedSurrogate;
    sourceData.delay = selectedDelay;
    sourceData.sensitivity = selectedSensitivity;
    sourceData.lambda = selectedLambda;

end

function available = hasVariables(inputTable, requiredNames)
% hasVariables Check whether a table can support one figure panel.

    available = istable(inputTable) && ~isempty(inputTable) && ...
        all(ismember( ...
            requiredNames, ...
            string(inputTable.Properties.VariableNames)));

end

function showNoData(axesHandle)
% showNoData Leave an explicit marker instead of an empty unexplained panel.

    axis(axesHandle, [0 1 0 1]);
    text(axesHandle, 0.5, 0.5, "No completed results", ...
        "HorizontalAlignment", "center", ...
        "Color", [0.4 0.4 0.4]);

end
