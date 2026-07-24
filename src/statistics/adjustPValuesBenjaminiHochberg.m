function adjustedPValues = adjustPValuesBenjaminiHochberg(pValues)
% adjustPValuesBenjaminiHochberg Apply the BH false-discovery adjustment.

    originalSize = size(pValues);
    pValues = pValues(:);
    adjustedPValues = NaN(size(pValues));

    validMask = isfinite(pValues) & pValues >= 0 & pValues <= 1;
    validPValues = pValues(validMask);

    if isempty(validPValues)
        adjustedPValues = reshape(adjustedPValues, originalSize);
        return
    end

    [sortedPValues, sortOrder] = sort(validPValues);
    numTests = numel(sortedPValues);
    ranks = (1:numTests)';

    adjustedSortedValues = sortedPValues .* numTests ./ ranks;

    for valueIndex = numTests - 1:-1:1
        adjustedSortedValues(valueIndex) = min( ...
            adjustedSortedValues(valueIndex), ...
            adjustedSortedValues(valueIndex + 1));
    end

    adjustedSortedValues = min(adjustedSortedValues, 1);

    adjustedValidValues = NaN(numTests, 1);
    adjustedValidValues(sortOrder) = adjustedSortedValues;
    adjustedPValues(validMask) = adjustedValidValues;
    adjustedPValues = reshape(adjustedPValues, originalSize);

end
