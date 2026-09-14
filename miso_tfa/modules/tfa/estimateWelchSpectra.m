function spectra = estimateWelchSpectra( ...
    map, co2, cbv, samplingFrequencyHz, welchSettings)
% estimateWelchSpectra Estimate and smooth the spectra shared by all models.

    [window, welchInfo] = getWelchWindowSettings( ...
        welchSettings, samplingFrequencyHz, length(map));

    if welchInfo.isTooShort
        error([ ...
            'Signal is shorter than the Welch window. ' ...
            'Use a longer signal or reduce windowLengthSeconds.']);
    end

    overlapSamples = welchInfo.windowOverlapSamples;
    fftLengthSamples = welchInfo.fftLengthSamples;

    [mapPower, f] = cpsd( ...
        map, map, window, overlapSamples, fftLengthSamples, ...
        samplingFrequencyHz);
    [co2Power, ~] = cpsd( ...
        co2, co2, window, overlapSamples, fftLengthSamples, ...
        samplingFrequencyHz);
    [cbvPower, ~] = cpsd( ...
        cbv, cbv, window, overlapSamples, fftLengthSamples, ...
        samplingFrequencyHz);

    [mapCo2Conjugate, ~] = cpsd( ...
        map, co2, window, overlapSamples, fftLengthSamples, ...
        samplingFrequencyHz);
    [mapCbvConjugate, ~] = cpsd( ...
        map, cbv, window, overlapSamples, fftLengthSamples, ...
        samplingFrequencyHz);
    [co2CbvConjugate, ~] = cpsd( ...
        co2, cbv, window, overlapSamples, fftLengthSamples, ...
        samplingFrequencyHz);

    % MATLAB defines CPSD as X(Y*), while the model equations use (X*)Y.
    mapCo2 = conj(mapCo2Conjugate);
    mapCbv = conj(mapCbvConjugate);
    co2Cbv = conj(co2CbvConjugate);

    if welchSettings.smoothingEnabled
        smoothingKernel = welchSettings.smoothingKernel;
    else
        smoothingKernel = 1;
    end

    spectra.f = f;
    spectra.map.power = conv(mapPower, smoothingKernel, "same");
    spectra.co2.power = conv(co2Power, smoothingKernel, "same");
    spectra.cbv.power = conv(cbvPower, smoothingKernel, "same");
    spectra.cross.mapCo2 = conv(mapCo2, smoothingKernel, "same");
    spectra.cross.co2Map = conj(spectra.cross.mapCo2);
    spectra.cross.mapCbv = conv(mapCbv, smoothingKernel, "same");
    spectra.cross.co2Cbv = conv(co2Cbv, smoothingKernel, "same");

    spectra.welchInfo = welchInfo;
    spectra.welchInfo.smoothingEnabled = ...
        welchSettings.smoothingEnabled;
    spectra.welchInfo.smoothingKernel = ...
        welchSettings.smoothingKernel;

end
