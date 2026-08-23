function summary = summarizeSimulationFrequencyMap( ...
    factorValues, frequencyValues, factorName, ...
    groupingMode, groupingSettings, statisticsSettings)
% summarizeSimulationFrequencyMap Calculate frequency-wise summaries.

    if nargin < 5
        groupingSettings = struct();
    end
    runInference = nargin >= 6 && ~isempty(statisticsSettings);
    factorValues = factorValues(:);
    groups = createSimulationFactorGroups( ...
        factorValues, factorName, groupingMode, groupingSettings);
    numGroups = numel(groups.centers);
    numFrequencies = size(frequencyValues, 1);
    means = NaN(numGroups, numFrequencies);
    standardDeviations = NaN(numGroups, numFrequencies);
    validN = zeros(numGroups, numFrequencies);
    standardError = NaN(numGroups, numFrequencies);
    ciLower = NaN(numGroups, numFrequencies);
    ciUpper = NaN(numGroups, numFrequencies);
    rawP = NaN(numGroups, numFrequencies);
    for groupNumber = 1:numGroups
        columns = groups.index == groupNumber;
        for frequencyIndex = 1:numFrequencies
            values = frequencyValues(frequencyIndex, columns);
            values = values(isfinite(values));
            validN(groupNumber, frequencyIndex) = numel(values);
            if ~isempty(values)
                means(groupNumber, frequencyIndex) = mean(values);
                standardDeviations(groupNumber, frequencyIndex) = ...
                    std(values, 0);
            end
            if runInference
                current = calculateSimulationAdvantageStatistics( ...
                    values, statisticsSettings.alpha, ...
                    statisticsSettings.minimumValidN);
                standardError(groupNumber, frequencyIndex) = ...
                    current.standardError;
                ciLower(groupNumber, frequencyIndex) = ...
                    current.ciLower;
                ciUpper(groupNumber, frequencyIndex) = ...
                    current.ciUpper;
                rawP(groupNumber, frequencyIndex) = current.rawP;
            end
        end
    end

    summary.factorCenters = groups.centers;
    summary.factorLabels = groups.labels;
    summary.factorLower = groups.lowerEdges;
    summary.factorUpper = groups.upperEdges;
    summary.groupN = groups.totalN;
    summary.mean = means;
    summary.sd = standardDeviations;
    summary.validN = validN;
    if runInference
        summary.standardError = standardError;
        summary.ciLower = ciLower;
        summary.ciUpper = ciUpper;
        summary.rawP = rawP;
        summary.bhAdjustedP = ...
            adjustPValuesBenjaminiHochberg(rawP);
        summary.isSignificant = isfinite(summary.bhAdjustedP) & ...
            summary.bhAdjustedP < statisticsSettings.alpha;
        summary.geometricSisoToMisoErrorRatio = 10.^means;
    end

end
