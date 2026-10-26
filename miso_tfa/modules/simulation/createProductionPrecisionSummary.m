function precision = createProductionPrecisionSummary( ...
    primaryMaps, repetitions, productionSettings)
% createProductionPrecisionSummary Audit Monte Carlo precision of primary maps.

    numMaps = numel(primaryMaps);
    mapName = strings(numMaps, 1);
    maximumSE = NaN(numMaps, 1);
    finiteCellCount = zeros(numMaps, 1);
    passingCellCount = zeros(numMaps, 1);
    minimumPairedN = NaN(numMaps, 1);
    maximumPairedN = NaN(numMaps, 1);
    failedEstimateCount = zeros(numMaps, 1);
    targetSE = productionSettings.targetMonteCarloSE;

    for mapIndex = 1:numMaps
        source = primaryMaps(mapIndex).frequencyTable;
        finite = isfinite(source.BootstrapSD);
        mapName(mapIndex) = primaryMaps(mapIndex).name;
        finiteCellCount(mapIndex) = nnz(finite);
        passingCellCount(mapIndex) = nnz( ...
            finite & source.BootstrapSD <= targetSE);
        failedEstimateCount(mapIndex) = sum(max( ...
            source.GroupN - source.PairedValidN, 0));
        if any(finite)
            maximumSE(mapIndex) = max(source.BootstrapSD(finite));
            minimumPairedN(mapIndex) = min(source.PairedValidN(finite));
            maximumPairedN(mapIndex) = max(source.PairedValidN(finite));
        end
    end

    precision.mapTable = table( ...
        mapName, maximumSE, repmat(targetSE, numMaps, 1), ...
        finiteCellCount, passingCellCount, minimumPairedN, ...
        maximumPairedN, failedEstimateCount, ...
        VariableNames=["MapName" "MaximumBootstrapSE" "TargetSE" ...
        "FiniteCellCount" "PassingCellCount" "MinimumPairedN" ...
        "MaximumPairedN" "FailedEstimateCount"]);
    allFiniteSE = vertcat(primaryMaps.frequencyTable);
    allFiniteSE = allFiniteSE.BootstrapSD(isfinite(allFiniteSE.BootstrapSD));
    if isempty(allFiniteSE)
        precision.maximumSE = NaN;
        precision.fractionMeetingTarget = NaN;
        recommended = repetitions;
    else
        precision.maximumSE = max(allFiniteSE);
        precision.fractionMeetingTarget = mean(allFiniteSE <= targetSE);
        estimated = repetitions*(precision.maximumSE/targetSE)^2;
        increment = productionSettings.appendIncrement;
        recommended = ceil(estimated/increment)*increment;
        recommended = max(repetitions, recommended);
        recommended = min( ...
            productionSettings.maximumRepetitionsPerCondition, recommended);
    end
    precision.targetSE = targetSE;
    precision.currentRepetitions = repetitions;
    precision.recommendedRepetitions = recommended;
    precision.appendPermitted = recommended > repetitions;
    precision.appendLimit = ...
        productionSettings.maximumRepetitionsPerCondition;

end
