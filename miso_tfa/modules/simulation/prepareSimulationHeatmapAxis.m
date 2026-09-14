function [plotValues, tickValues, tickLabels] = ...
    prepareSimulationHeatmapAxis(factorLabels)
% prepareSimulationHeatmapAxis Place each heatmap group at one cell center.
%
% The true factor values remain visible as labels. Equal cell spacing keeps
% nonuniform values such as 256, 300, 320, and 896 aligned with image rows.

    numGroups = numel(factorLabels);
    plotValues = (1:numGroups)';
    tickValues = plotValues;
    tickLabels = string(factorLabels(:));

end
