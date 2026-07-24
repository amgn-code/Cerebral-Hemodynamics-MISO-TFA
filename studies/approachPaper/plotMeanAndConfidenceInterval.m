function summary = plotMeanAndConfidenceInterval( ...
    axesHandle, xValues, subjectValues, color, displayName)
% plotMeanAndConfidenceInterval Plot a mean and pointwise 95% t interval.
%
% subjectValues must contain frequencies in rows and subjects in columns.

    numSubjects = sum(isfinite(subjectValues), 2);
    meanValues = mean(subjectValues, 2, "omitnan");
    sdValues = std(subjectValues, 0, 2, "omitnan");
    standardError = sdValues ./ sqrt(numSubjects);
    criticalValue = NaN(size(numSubjects));
    validRows = numSubjects >= 2;
    criticalValue(validRows) = tinv(0.975, numSubjects(validRows) - 1);
    margin = criticalValue .* standardError;
    lower = meanValues - margin;
    upper = meanValues + margin;

    xValues = xValues(:);
    hold(axesHandle, "on");
    fill( ...
        axesHandle, [xValues; flipud(xValues)], ...
        [lower; flipud(upper)], color, ...
        "FaceAlpha", 0.18, "EdgeColor", "none", ...
        "HandleVisibility", "off");
    plot( ...
        axesHandle, xValues, meanValues, ...
        "Color", color, "LineWidth", 1.6, ...
        "DisplayName", displayName);

    summary.mean = meanValues;
    summary.lower95 = lower;
    summary.upper95 = upper;
    summary.n = numSubjects;

end
