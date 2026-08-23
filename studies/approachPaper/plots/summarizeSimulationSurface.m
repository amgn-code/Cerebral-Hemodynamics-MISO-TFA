function summary = summarizeSimulationSurface( ...
    xValues, yValues, metricValues, ...
    xName, xMode, yName, yMode, groupingSettings, ...
    statisticsSettings)
% summarizeSimulationSurface Summarize one outcome over two factors.

    if nargin < 8
        groupingSettings = struct();
    end
    runInference = nargin >= 9 && ~isempty(statisticsSettings);

    xGroups = createSimulationFactorGroups( ...
        xValues, xName, xMode, groupingSettings);
    yGroups = createSimulationFactorGroups( ...
        yValues, yName, yMode, groupingSettings);

    surfaceSize = [numel(yGroups.centers), numel(xGroups.centers)];
    meanSurface = NaN(surfaceSize);
    sdSurface = NaN(surfaceSize);
    fractionSurface = NaN(surfaceSize);
    validN = zeros(surfaceSize);
    positiveN = zeros(surfaceSize);
    groupN = zeros(surfaceSize);
    standardError = NaN(surfaceSize);
    ciLower = NaN(surfaceSize);
    ciUpper = NaN(surfaceSize);
    rawP = NaN(surfaceSize);

    for yIndex = 1:numel(yGroups.centers)
        for xIndex = 1:numel(xGroups.centers)
            rows = xGroups.index == xIndex & ...
                yGroups.index == yIndex;
            groupN(yIndex, xIndex) = nnz(rows);
            values = metricValues(rows);
            values = values(isfinite(values));
            validN(yIndex, xIndex) = numel(values);
            if ~isempty(values)
                meanSurface(yIndex, xIndex) = mean(values);
                sdSurface(yIndex, xIndex) = std(values, 0);
                positiveN(yIndex, xIndex) = nnz(values > 0);
                fractionSurface(yIndex, xIndex) = ...
                    mean(values > 0);
            end
            if runInference
                current = calculateSimulationAdvantageStatistics( ...
                    values, statisticsSettings.alpha, ...
                    statisticsSettings.minimumValidN);
                standardError(yIndex, xIndex) = ...
                    current.standardError;
                ciLower(yIndex, xIndex) = current.ciLower;
                ciUpper(yIndex, xIndex) = current.ciUpper;
                rawP(yIndex, xIndex) = current.rawP;
            end
        end
    end

    summary.x = xGroups;
    summary.y = yGroups;
    summary.mean = meanSurface;
    summary.sd = sdSurface;
    summary.validN = validN;
    summary.groupN = groupN;
    summary.fractionPositive = fractionSurface;
    summary.positiveN = positiveN;
    if runInference
        summary.standardError = standardError;
        summary.ciLower = ciLower;
        summary.ciUpper = ciUpper;
        summary.rawP = rawP;
        summary.bhAdjustedP = ...
            adjustPValuesBenjaminiHochberg(rawP);
        summary.isSignificant = isfinite(summary.bhAdjustedP) & ...
            summary.bhAdjustedP < statisticsSettings.alpha;
        summary.geometricSisoToMisoErrorRatio = 10.^meanSurface;
    end

end
