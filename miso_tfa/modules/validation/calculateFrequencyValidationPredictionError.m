function [frequencyHz, normalizedError] = ...
    calculateFrequencyValidationPredictionError( ...
    spectra, mapTransferFunction, co2TransferFunction, frequencyRangeHz)
% calculateFrequencyValidationPredictionError Return held-out error by frequency.
%
% Transfer functions are estimated from one recording segment and evaluated
% against the spectral matrix from a separate segment. The normalized error
% is the nonnegative residual CBFV power divided by held-out CBFV power.

    frequencyMask = spectra.f >= frequencyRangeHz(1) & ...
        spectra.f <= frequencyRangeHz(2);
    selectedIndices = find(frequencyMask);
    frequencyHz = spectra.f(selectedIndices);
    normalizedError = NaN(size(frequencyHz));

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
        normalizedError(selectedIndex) = ...
            max(real(residualPower), 0)/outputPower;
    end

end
