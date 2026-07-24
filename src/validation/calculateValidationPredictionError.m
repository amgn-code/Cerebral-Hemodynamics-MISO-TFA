function normalizedError = calculateValidationPredictionError( ...
    spectra, mapTransferFunction, co2TransferFunction, ...
    frequencyRangeHz)
% calculateValidationPredictionError Evaluate coefficients on new data.
%
% The transfer functions are estimated from one realization and evaluated
% against the spectral matrix from an independent realization.

    frequencyMask = spectra.f >= frequencyRangeHz(1) & ...
        spectra.f <= frequencyRangeHz(2);
    selectedIndices = find(frequencyMask);
    errors = NaN(numel(selectedIndices), 1);

    for selectedIndex = 1:numel(selectedIndices)
        frequencyIndex = selectedIndices(selectedIndex);
        spectralMatrix = [ ...
            spectra.map.power(frequencyIndex), ...
            spectra.cross.mapCo2(frequencyIndex)
            spectra.cross.co2Map(frequencyIndex), ...
            spectra.co2.power(frequencyIndex)];
        crossSpectrum = [ ...
            spectra.cross.mapCbv(frequencyIndex)
            spectra.cross.co2Cbv(frequencyIndex)];
        coefficients = [ ...
            mapTransferFunction(frequencyIndex)
            co2TransferFunction(frequencyIndex)];
        outputPower = real(spectra.cbv.power(frequencyIndex));

        if outputPower <= 0 || any(~isfinite(coefficients))
            continue
        end

        residualPower = outputPower - ...
            2*real(coefficients'*crossSpectrum) + ...
            real(coefficients'*spectralMatrix*coefficients);
        errors(selectedIndex) = max(residualPower, 0)/outputPower;
    end

    normalizedError = mean(errors, "omitnan");

end
