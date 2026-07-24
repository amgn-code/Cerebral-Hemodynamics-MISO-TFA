function comparison = compareCircularValues( ...
    firstValues, secondValues, comparisonType, numPermutations)
% compareCircularValues Compare paired or independent phase values.
%
% Angles are supplied in radians. The reported difference is the shortest
% wrapped angular difference between the two circular means.

    comparisonType = lower(string(comparisonType));
    firstValues = firstValues(:);
    secondValues = secondValues(:);

    if comparisonType == "paired"
        completeMask = isfinite(firstValues) & isfinite(secondValues);
        firstValues = firstValues(completeMask);
        secondValues = secondValues(completeMask);

        comparison.nFirst = numel(firstValues);
        comparison.nSecond = numel(secondValues);
        comparison.meanFirst = circularMeanPhase(firstValues);
        comparison.meanSecond = circularMeanPhase(secondValues);

        angularDifferences = angle(exp( ...
            1i*(firstValues - secondValues)));
        comparison.difference = circularMeanPhase(angularDifferences);

        if numel(angularDifferences) < 2
            comparison.pValue = NaN;
            return
        end

        observedStatistic = abs(comparison.difference);
        permutationStatistics = NaN(numPermutations, 1);

        for permutationIndex = 1:numPermutations
            randomSigns = 2*(rand(size(angularDifferences)) > 0.5) - 1;
            permutedDifferences = angularDifferences .* randomSigns;
            permutationStatistics(permutationIndex) = abs( ...
                circularMeanPhase(permutedDifferences));
        end

    elseif comparisonType == "independent"
        firstValues = firstValues(isfinite(firstValues));
        secondValues = secondValues(isfinite(secondValues));

        comparison.nFirst = numel(firstValues);
        comparison.nSecond = numel(secondValues);
        comparison.meanFirst = circularMeanPhase(firstValues);
        comparison.meanSecond = circularMeanPhase(secondValues);
        comparison.difference = angle(exp( ...
            1i*(comparison.meanFirst - comparison.meanSecond)));

        if numel(firstValues) < 2 || numel(secondValues) < 2
            comparison.pValue = NaN;
            return
        end

        observedStatistic = abs(comparison.difference);
        pooledValues = [firstValues; secondValues];
        numFirstValues = numel(firstValues);
        permutationStatistics = NaN(numPermutations, 1);

        for permutationIndex = 1:numPermutations
            shuffledOrder = randperm(numel(pooledValues));
            shuffledFirst = pooledValues( ...
                shuffledOrder(1:numFirstValues));
            shuffledSecond = pooledValues( ...
                shuffledOrder(numFirstValues + 1:end));

            permutedDifference = angle(exp(1i*( ...
                circularMeanPhase(shuffledFirst) - ...
                circularMeanPhase(shuffledSecond))));
            permutationStatistics(permutationIndex) = ...
                abs(permutedDifference);
        end

    else
        error( ...
            'TFA:UnknownCircularComparison', ...
            'comparisonType must be "paired" or "independent".');
    end

    comparison.pValue = (1 + sum( ...
        permutationStatistics >= observedStatistic)) / ...
        (numPermutations + 1);

end
