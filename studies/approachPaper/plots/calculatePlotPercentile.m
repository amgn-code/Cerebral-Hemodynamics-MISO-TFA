function value = calculatePlotPercentile(values, percentile)
% calculatePlotPercentile Calculate one percentile without extra toolboxes.

    values = sort(values(isfinite(values)));
    if isempty(values)
        value = NaN;
        return
    end
    if isscalar(values)
        value = values;
        return
    end

    position = 1 + (numel(values) - 1)*(percentile/100);
    lowerIndex = floor(position);
    upperIndex = ceil(position);
    fraction = position - lowerIndex;
    value = ...
        (1 - fraction)*values(lowerIndex) + ...
        fraction*values(upperIndex);

end
