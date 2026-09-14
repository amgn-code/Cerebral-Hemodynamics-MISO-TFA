function normalizedError = calculateValidationPredictionError( ...
    spectra, mapTransferFunction, co2TransferFunction, ...
    frequencyRangeHz)
% calculateValidationPredictionError Evaluate coefficients on new data.
%
% The transfer functions are estimated from one realization and evaluated
% against the spectral matrix from an independent realization.

    [~, errors] = calculateFrequencyValidationPredictionError( ...
        spectra, mapTransferFunction, co2TransferFunction, ...
        frequencyRangeHz);

    normalizedError = mean(errors, "omitnan");

end
