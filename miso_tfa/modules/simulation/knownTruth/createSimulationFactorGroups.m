function groups = createSimulationFactorGroups( ...
    factorValues, factorName, groupingMode, groupingSettings)
% createSimulationFactorGroups Define exact levels or fixed factor ranges.

    if nargin < 4
        groupingSettings = struct();
    end

    factorValues = factorValues(:);
    factorName = string(factorName);
    groupingMode = lower(string(groupingMode));

    if groupingMode == "exact"
        [centers, ~, groupIndex] = unique( ...
            factorValues, "sorted");
        groups.index = groupIndex;
        groups.centers = centers;
        groups.lowerEdges = centers;
        groups.upperEdges = centers;
        groups.labels = formatExactLabels(centers);
        groups.totalN = countGroups(groupIndex, numel(centers));
        return
    end

    edges = getFactorEdges( ...
        factorValues, factorName, groupingSettings);
    groupIndex = discretize(factorValues, edges);
    centers = edges(1:end-1)' + diff(edges(:))/2;

    groups.index = groupIndex;
    groups.centers = centers;
    groups.lowerEdges = edges(1:end-1)';
    groups.upperEdges = edges(2:end)';
    groups.labels = composeIntervalLabels( ...
        groups.lowerEdges, groups.upperEdges);
    groups.totalN = countGroups(groupIndex, numel(centers));

end

function edges = getFactorEdges(values, factorName, settings)
% getFactorEdges Return the user-editable edges for intrinsic factors.

    switch factorName
        case {"FamilyInputCoherence", "RealizedInputCoherence"}
            fieldName = "inputCoherenceEdges";
        case {"FamilyPSDShapeOverlap", "RealizedPSDShapeOverlap"}
            fieldName = "psdShapeOverlapEdges";
        case { ...
                "FamilyPETCO2ContributionPowerShare", ...
                "RealizedPETCO2ContributionPowerShare"}
            fieldName = "petco2ContributionPowerShareEdges";
        case "CO2DelaySeconds"
            fieldName = "";
        otherwise
            fieldName = "";
    end

    if strlength(fieldName) > 0 && isfield(settings, fieldName)
        edges = settings.(fieldName);
    else
        finiteValues = values(isfinite(values));
        if isempty(finiteValues)
            edges = [0 1];
        elseif min(finiteValues) == max(finiteValues)
            center = finiteValues(1);
            width = max(abs(center)*0.1, 0.5);
            edges = [center - width center + width];
        else
            edges = linspace( ...
                min(finiteValues), max(finiteValues), 11);
        end
    end

    edges = unique(double(edges(:)'), "sorted");
    if numel(edges) < 2 || any(~isfinite(edges))
        error( ...
            "TFA:InvalidSimulationGroupingEdges", ...
            "Simulation grouping edges must be finite and increasing.");
    end

end

function labels = composeIntervalLabels(lowerEdges, upperEdges)
% composeIntervalLabels Make readable labels such as 0.2-0.3.

    labels = strings(numel(lowerEdges), 1);
    for index = 1:numel(lowerEdges)
        labels(index) = compose("%.3g-%.3g", ...
            lowerEdges(index), upperEdges(index));
    end

end

function labels = formatExactLabels(values)
% formatExactLabels Format controlled levels without changing their values.

    labels = compose("%.3g", double(values));
    labels(isinf(values)) = "No noise";

end

function counts = countGroups(groupIndex, numGroups)
% countGroups Count all observations assigned to each factor group.

    counts = zeros(numGroups, 1);
    for groupNumber = 1:numGroups
        counts(groupNumber) = nnz(groupIndex == groupNumber);
    end

end
