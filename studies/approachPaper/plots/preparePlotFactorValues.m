function [plotValues, tickValues, tickLabels] = ...
    preparePlotFactorValues(factorValues)
% preparePlotFactorValues Replace Inf with a readable final axis position.

    % MATLAB graphics requires numeric, increasing tick positions. Logical
    % factors such as smoothing off/on are converted to 0 and 1 here.
    plotValues = double(factorValues(:));
    finiteValues = plotValues(isfinite(plotValues));
    hasInfiniteValue = any(isinf(plotValues));

    if hasInfiniteValue
        if isempty(finiteValues)
            replacement = 1;
        else
            uniqueFinite = unique(finiteValues, "sorted");
            if numel(uniqueFinite) > 1
                step = median(diff(uniqueFinite));
            else
                step = max(abs(uniqueFinite), 1);
            end
            replacement = max(uniqueFinite) + step;
        end
        plotValues(isinf(plotValues)) = replacement;
    end

    tickValues = unique(plotValues, "sorted");
    tickLabels = compose("%.3g", tickValues);
    if hasInfiniteValue
        tickLabels(tickValues == replacement) = "No noise";
    end

end
