function comparison = comparePairedArithmeticValues( ...
    firstValues, secondValues, alpha)
% comparePairedArithmeticValues Compare two values from the same subjects.

    if nargin < 3
        alpha = 0.05;
    end

    firstValues = firstValues(:);
    secondValues = secondValues(:);
    completeMask = isfinite(firstValues) & isfinite(secondValues);
    firstValues = firstValues(completeMask);
    secondValues = secondValues(completeMask);
    differences = firstValues - secondValues;

    comparison.n = numel(differences);
    comparison.meanFirst = mean(firstValues, 'omitnan');
    comparison.meanSecond = mean(secondValues, 'omitnan');
    comparison.difference = mean(differences, 'omitnan');
    comparison.ciLower = NaN;
    comparison.ciUpper = NaN;
    comparison.effectSize = NaN;
    comparison.pValue = NaN;

    if comparison.n >= 2
        [~, comparison.pValue, confidenceInterval] = ttest( ...
            firstValues, secondValues, "Alpha", alpha);
        comparison.ciLower = confidenceInterval(1);
        comparison.ciUpper = confidenceInterval(2);

        differenceSd = std(differences, 0, 'omitnan');
        if differenceSd > 0
            comparison.effectSize = comparison.difference/differenceSd;
        end
    end

    validRatioMask = isfinite(firstValues) & isfinite(secondValues) & ...
        secondValues ~= 0;
    ratios = firstValues(validRatioMask) ./ secondValues(validRatioMask);

    comparison.medianRatio = median(ratios, 'omitnan');
    comparison.ratioQ1 = NaN;
    comparison.ratioQ3 = NaN;

    if ~isempty(ratios)
        ratioQuartiles = prctile(ratios, [25 75]);
        comparison.ratioQ1 = ratioQuartiles(1);
        comparison.ratioQ3 = ratioQuartiles(2);
    end

end
