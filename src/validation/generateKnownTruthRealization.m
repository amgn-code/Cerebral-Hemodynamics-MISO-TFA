function realization = generateKnownTruthRealization( ...
    scenario, settings, randomSeed, durationSeconds)
% generateKnownTruthRealization Generate one long clean random recording.
%
% MAP and PETCO2 are constructed from a shared broadband random component
% and an independent PETCO2 component. The shared proportion controls the
% expected input coherence. Separate spectral filters control overlap.

    validateattributes( ...
        randomSeed, {'numeric'}, ...
        {'scalar', 'integer', 'nonnegative', 'finite'});

    previousRandomState = rng;
    restoreRandomState = onCleanup(@() rng(previousRandomState));
    rng(randomSeed, "twister");

    fs = settings.samplingFrequencyHz;
    burnInSeconds = settings.pathways.burnInSeconds;
    numOutputSamples = round(durationSeconds*fs);
    numBurnInSamples = round(burnInSeconds*fs);
    numSamples = numOutputSamples + numBurnInSamples;

    sharedWhiteNoise = randn(numSamples, 1);
    independentCo2WhiteNoise = randn(numSamples, 1);

    signedFrequencyHz = (0:(numSamples - 1))'*fs/numSamples;
    absoluteFrequencyHz = min( ...
        signedFrequencyHz, fs - signedFrequencyHz);
    inputSpectra = createKnownTruthInputSpectra( ...
        absoluteFrequencyHz, scenario, settings);

    sharedSpectrum = fft(sharedWhiteNoise);
    independentCo2Spectrum = fft(independentCo2WhiteNoise);
    mapSpectrum = sqrt(inputSpectra.mapPower).*sharedSpectrum;

    targetCoherence = inputSpectra.targetCoherence;
    co2SourceSpectrum = ...
        sqrt(targetCoherence).*sharedSpectrum + ...
        sqrt(1 - targetCoherence).*independentCo2Spectrum;
    co2Spectrum = sqrt(inputSpectra.co2Power).*co2SourceSpectrum;

    map = real(ifft(mapSpectrum));
    co2 = real(ifft(co2Spectrum));
    map = standardizeGeneratedSignal(map)* ...
        settings.inputs.mapStandardDeviation;
    co2 = standardizeGeneratedSignal(co2)* ...
        scenario.petco2ToMapFluctuationSdRatio;

    mapKernel = createMapAutoregulationKernel( ...
        settings.pathways.mapHighFrequencyGain, ...
        settings.pathways.mapLowFrequencyGainFraction, ...
        scenario.mapPathwayTimeConstantSeconds, fs, ...
        settings.pathways.filterDurationTimeConstants);
    unscaledCo2Kernel = createPetco2VasoreactivityKernel( ...
        settings.pathways.co2UnscaledGain, ...
        scenario.co2PathwayTimeConstantSeconds, ...
        scenario.co2DelaySeconds, fs, ...
        settings.pathways.filterDurationTimeConstants);
    [co2Kernel, achievedBandGainRatio] = ...
        scalePathwayToBandGainRatio( ...
            unscaledCo2Kernel, mapKernel, ...
            scenario.petco2ToMapBandGainRatio, fs, ...
            settings.frequencyRangeHz);

    mapContribution = filter(mapKernel, 1, map);
    co2Contribution = filter(co2Kernel, 1, co2);
    cleanCbv = mapContribution + co2Contribution;

    interactionStrength = ...
        settings.pathways.nonlinearInteractionStrength;
    if interactionStrength > 0
        interaction = standardizeGeneratedSignal(map.*co2);
        cleanCbv = cleanCbv + ...
            interactionStrength*std(cleanCbv)*interaction;
    end

    outputNoise = standardizeGeneratedSignal(randn(numSamples, 1));
    mapMeasurementNoise = ...
        standardizeGeneratedSignal(randn(numSamples, 1));
    co2MeasurementNoise = ...
        standardizeGeneratedSignal(randn(numSamples, 1));

    keptSamples = (numBurnInSamples + 1):numSamples;
    realization.map = map(keptSamples);
    realization.co2 = co2(keptSamples);
    realization.cleanCbv = cleanCbv(keptSamples);
    realization.mapContribution = mapContribution(keptSamples);
    realization.co2Contribution = co2Contribution(keptSamples);
    realization.outputNoise = outputNoise(keptSamples);
    realization.mapMeasurementNoise = ...
        mapMeasurementNoise(keptSamples);
    realization.co2MeasurementNoise = ...
        co2MeasurementNoise(keptSamples);
    realization.fs = fs;
    realization.truth.mapImpulseResponse = mapKernel(:);
    realization.truth.co2ImpulseResponse = co2Kernel(:);
    realization.truth.assignedPETCO2ToMAPBandGainRatio = ...
        scenario.petco2ToMapBandGainRatio;
    realization.truth.achievedPETCO2ToMAPBandGainRatio = ...
        achievedBandGainRatio;
    realization.truth.petco2ContributionPowerShare = ...
        calculatePetco2ContributionPowerShare( ...
            realization.mapContribution, realization.co2Contribution);
    realization.designedInputSpectra = inputSpectra;
    realization.randomSeed = randomSeed;

    clear restoreRandomState

end

function standardized = standardizeGeneratedSignal(signal)
% standardizeGeneratedSignal Give a signal zero mean and unit SD.

    standardized = signal(:) - mean(signal, "omitnan");
    signalSd = std(standardized, "omitnan");
    if signalSd <= 0 || ~isfinite(signalSd)
        error( ...
            "TFA:InvalidGeneratedSignal", ...
            "A generated simulation signal had zero or invalid variance.");
    end
    standardized = standardized/signalSd;

end
