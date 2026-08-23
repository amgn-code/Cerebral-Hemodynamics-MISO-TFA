function [figureHandle, sourceData] = ...
    plotSimulationRidgeConditioning(ridgeTable, titleContext)
% plotSimulationRidgeConditioning Show conditioning after ridge is added.

    if nargin < 2
        titleContext = "";
    end
    sourceData = summarizeSimulationCurve( ...
        ridgeTable, "Lambda", ...
        "MedianRegularizedConditionNumber", "exact", struct());

    figureHandle = figure("Color", "white", "Visible", "off");
    axesHandle = axes(figureHandle);
    plotMeanSdCurve( ...
        axesHandle, sourceData.FactorValue, ...
        sourceData.MedianRegularizedConditionNumberMean, ...
        sourceData.MedianRegularizedConditionNumberSD, ...
        [0.12 0.22 0.36], "Across-family mean", true);
    set(axesHandle, "XScale", "log", "YScale", "log");
    xlabel(axesHandle, "Standardized ridge lambda");
    ylabel(axesHandle, ...
        "Effective condition number of normalized matrix plus lambda I");
    titleText = "Ridge directly improves the solved system's conditioning";
    if strlength(titleContext) > 0
        titleText = titleText + newline + titleContext;
    end
    title(axesHandle, titleText);
    grid(axesHandle, "on");

end
