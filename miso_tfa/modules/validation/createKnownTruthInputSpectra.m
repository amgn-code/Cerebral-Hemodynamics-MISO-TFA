function spectra = createKnownTruthInputSpectra( ...
    frequencyHz, scenario, settings)
% createKnownTruthInputSpectra Define expected MAP and PETCO2 spectra.
%
% Spectral similarity moves the PETCO2 center toward or away from the MAP
% center. Coherence is controlled separately, so two signals can occupy
% similar frequencies without being strongly coherent.

    frequencyHz = abs(frequencyHz(:));
    mapCenterHz = settings.inputs.mapSpectrumCenterHz;
    bandwidthHz = settings.inputs.spectrumBandwidthHz;
    separationHz = ...
        (1 - scenario.spectralSimilarityControl)* ...
        settings.inputs.maximumCenterSeparationHz;
    co2CenterHz = mapCenterHz + separationHz;

    mapPower = gaussianSpectrum( ...
        frequencyHz, mapCenterHz, bandwidthHz);
    co2Power = gaussianSpectrum( ...
        frequencyHz, co2CenterHz, bandwidthHz);

    floorFraction = settings.inputs.spectrumFloorFraction;
    mapPower = mapPower + floorFraction;
    co2Power = co2Power + floorFraction;

    if settings.inputs.coherenceProfile == "flat"
        targetCoherence = repmat( ...
            scenario.targetInputCoherence, size(frequencyHz));
    else
        error( ...
            "TFA:UnknownCoherenceProfile", ...
            "Supported coherenceProfile values currently include ""flat"".");
    end

    spectra.frequencyHz = frequencyHz;
    spectra.mapPower = mapPower;
    spectra.co2Power = co2Power;
    spectra.targetCoherence = min(1, max(0, targetCoherence));
    spectra.mapCenterHz = mapCenterHz;
    spectra.co2CenterHz = co2CenterHz;

end

function power = gaussianSpectrum(frequencyHz, centerHz, bandwidthHz)
% gaussianSpectrum Create one smooth broadband spectral shape.

    power = exp(-0.5*((frequencyHz - centerHz)/bandwidthHz).^2);

end
