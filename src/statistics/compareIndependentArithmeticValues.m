function comparison = compareIndependentArithmeticValues( ...
    firstValues, secondValues, alpha)
% compareIndependentArithmeticValues Compare two independent groups.

    if nargin < 3
        alpha = 0.05;
    end

    firstValues = firstValues(:);
    secondValues = secondValues(:);
    firstValues = firstValues(isfinite(firstValues));
    secondValues = secondValues(isfinite(secondValues));

    comparison.nFirst = numel(firstValues);
    comparison.nSecond = numel(secondValues);
    comparison.meanFirst = mean(firstValues, 'omitnan');
    comparison.meanSecond = mean(secondValues, 'omitnan');
    comparison.difference = ...
        comparison.meanFirst - comparison.meanSecond;
    comparison.ciLower = NaN;
    comparison.ciUpper = NaN;
    comparison.effectSize = NaN;
    comparison.pValue = NaN;

    if comparison.nFirst < 2 || comparison.nSecond < 2
        return
    end

    [~, comparison.pValue, confidenceInterval] = ttest2( ...
        firstValues, secondValues, "Vartype", "unequal", ...
        "Alpha", alpha);
    comparison.ciLower = confidenceInterval(1);
    comparison.ciUpper = confidenceInterval(2);

    firstVariance = var(firstValues, 0, 'omitnan');
    secondVariance = var(secondValues, 0, 'omitnan');
    degreesOfFreedom = comparison.nFirst + comparison.nSecond - 2;
    pooledVariance = ( ...
        (comparison.nFirst - 1)*firstVariance + ...
        (comparison.nSecond - 1)*secondVariance) / degreesOfFreedom;

    if pooledVariance > 0
        correction = 1 - 3/(4*(comparison.nFirst + ...
            comparison.nSecond) - 9);
        comparison.effectSize = correction * ...
            comparison.difference / sqrt(pooledVariance);
    end

end
