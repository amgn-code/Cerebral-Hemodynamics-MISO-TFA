function plotMeanSdCurve( ...
    axesHandle, x, meanValues, sdValues, color, displayName, logScale)
% plotMeanSdCurve Plot a mean line with a one-SD shaded band.

    if nargin < 7
        logScale = false;
    end

    x = x(:);
    meanValues = meanValues(:);
    sdValues = sdValues(:);
    complete = isfinite(x) & isfinite(meanValues) & isfinite(sdValues);
    if ~any(complete)
        return
    end

    lower = meanValues - sdValues;
    upper = meanValues + sdValues;
    if logScale
        positiveValues = meanValues(meanValues > 0);
        if isempty(positiveValues)
            lower(:) = eps;
        else
            displayFloor = max( ...
                min(positiveValues)*1e-3, realmin("double"));
            lower = max(lower, displayFloor);
        end
        upper = max(upper, lower);
    end

    hold(axesHandle, "on");
    segmentStarts = find(complete & [true; ~complete(1:end-1)]);
    segmentEnds = find(complete & [~complete(2:end); true]);
    for segmentIndex = 1:numel(segmentStarts)
        indices = segmentStarts(segmentIndex):segmentEnds(segmentIndex);
        fill(axesHandle, ...
            [x(indices); flipud(x(indices))], ...
            [lower(indices); flipud(upper(indices))], color, ...
            "FaceAlpha", 0.20, "EdgeColor", "none", ...
            "HandleVisibility", "off");
    end
    plot(axesHandle, x, meanValues, ...
        "Color", color, "LineWidth", 2, ...
        "Marker", "o", "MarkerSize", 4, ...
        "DisplayName", displayName);

end
