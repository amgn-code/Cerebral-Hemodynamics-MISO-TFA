function levels = createBalancedFamilyLevels(allowedValues, numFamilies)
% createBalancedFamilyLevels Assign fixed values as evenly as possible.
%
% Each allowed value appears either floor(N/K) or ceil(N/K) times. The
% assignments are shuffled using MATLAB's current random-number state.

    allowedValues = allowedValues(:);
    validateattributes( ...
        allowedValues, {'numeric'}, {'nonempty', 'finite'});
    validateattributes( ...
        numFamilies, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'finite'});

    if numFamilies < numel(allowedValues)
        selectedIndices = round(linspace( ...
            1, numel(allowedValues), numFamilies));
        repeatedValues = allowedValues(selectedIndices);
    else
        repeatedValues = repmat( ...
            allowedValues, ceil(numFamilies/numel(allowedValues)), 1);
        repeatedValues = repeatedValues(1:numFamilies);
    end
    levels = repeatedValues(randperm(numFamilies));

end
