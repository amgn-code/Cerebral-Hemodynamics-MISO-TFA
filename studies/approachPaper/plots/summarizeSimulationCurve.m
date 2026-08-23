function summary = summarizeSimulationCurve( ...
    data, factorName, metricNames, groupingMode, groupingSettings, ...
    statisticsSettings)
% summarizeSimulationCurve Calculate descriptive and model-comparison data.
%
% groupingMode is "exact" for designed levels such as duration or SNR and
% "binned" for intrinsic family factors such as coherence.

    if nargin < 5
        groupingSettings = struct();
    end
    if nargin < 6 || isempty(statisticsSettings)
        statisticsSettings.alpha = 0.05;
        statisticsSettings.minimumValidN = 3;
    end
    factorName = string(factorName);
    metricNames = string(metricNames);
    metricNames = metricNames(:);

    factorValues = data.(factorName);
    groups = createSimulationFactorGroups( ...
        factorValues, factorName, groupingMode, groupingSettings);
    numGroups = numel(groups.centers);

    summary = table( ...
        groups.centers(:), groups.labels(:), ...
        groups.lowerEdges(:), groups.upperEdges(:), ...
        groups.totalN(:), ...
        'VariableNames', { ...
            'FactorValue', 'FactorGroup', ...
            'FactorLower', 'FactorUpper', 'GroupN'});

    for metricIndex = 1:numel(metricNames)
        metricName = metricNames(metricIndex);
        means = NaN(numGroups, 1);
        standardDeviations = NaN(numGroups, 1);
        validN = zeros(numGroups, 1);
        fractionPositive = NaN(numGroups, 1);
        positiveN = zeros(numGroups, 1);
        standardError = NaN(numGroups, 1);
        ciLower = NaN(numGroups, 1);
        ciUpper = NaN(numGroups, 1);
        rawP = NaN(numGroups, 1);
        calculateInference = endsWith(metricName, "Advantage");

        for groupNumber = 1:numGroups
            rows = groups.index == groupNumber;
            values = data.(metricName)(rows);
            finiteValues = values(isfinite(values));
            validN(groupNumber) = numel(finiteValues);
            if ~isempty(finiteValues)
                means(groupNumber) = mean(finiteValues);
                standardDeviations(groupNumber) = ...
                    std(finiteValues, 0);
                fractionPositive(groupNumber) = ...
                    mean(finiteValues > 0);
                positiveN(groupNumber) = nnz(finiteValues > 0);
            end
            if calculateInference
                current = calculateSimulationAdvantageStatistics( ...
                    finiteValues, statisticsSettings.alpha, ...
                    statisticsSettings.minimumValidN);
                standardError(groupNumber) = current.standardError;
                ciLower(groupNumber) = current.ciLower;
                ciUpper(groupNumber) = current.ciUpper;
                rawP(groupNumber) = current.rawP;
            end
        end

        summary.(metricName + "Mean") = means;
        summary.(metricName + "SD") = standardDeviations;
        summary.(metricName + "ValidN") = validN;
        summary.(metricName + "FractionPositive") = ...
            fractionPositive;
        summary.(metricName + "PositiveN") = positiveN;
        if calculateInference
            adjustedP = adjustPValuesBenjaminiHochberg(rawP);
            summary.(metricName + "StandardError") = standardError;
            summary.(metricName + "CILower") = ciLower;
            summary.(metricName + "CIUpper") = ciUpper;
            summary.(metricName + "RawP") = rawP;
            summary.(metricName + "BHAdjustedP") = adjustedP;
            summary.(metricName + "IsSignificant") = ...
                isfinite(adjustedP) & ...
                adjustedP < statisticsSettings.alpha;
            summary.(metricName + ...
                "GeometricSISOToMISOErrorRatio") = 10.^means;
        end
    end

end
