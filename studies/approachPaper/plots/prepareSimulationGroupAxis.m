function [plotValues, tickValues, tickLabels] = ...
    prepareSimulationGroupAxis( ...
        factorCenters, factorLabels, groupingMode)
% prepareSimulationGroupAxis Prepare exact levels or interval groups.

    if lower(string(groupingMode)) == "binned"
        plotValues = (1:numel(factorCenters))';
        tickValues = plotValues;
        tickLabels = factorLabels(:);
    else
        [plotValues, tickValues, tickLabels] = ...
            preparePlotFactorValues(factorCenters);
    end

end
