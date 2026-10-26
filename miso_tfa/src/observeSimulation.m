function recording = observeSimulation(realization, condition, simulation, analysis)
% observeSimulation Apply duration, noise, and measurement misalignment.
%
% CBFV is generated from clean inputs before input recording noise is added.
% Output noise is scaled to the requested total time-domain SNR, exactly as
% in the original implementation. A duration uses the same master prefix.

    fs = realization.fs;
    indices = 1:round(condition.durationSeconds*fs);
    cleanMap = realization.map(indices);
    cleanCo2 = realization.co2(indices);
    cleanCbv = realization.cleanCbv(indices);
    map = addNoise(cleanMap, realization.mapMeasurementNoise(indices), condition.mapInputSnrDb);
    co2 = addNoise(cleanCo2, realization.co2MeasurementNoise(indices), condition.co2InputSnrDb);
    if simulation.noiseSpectrum == "signalShaped"
        outputNoise = realization.outputNoiseSignalShaped(indices);
    else
        outputNoise = realization.outputNoiseWhite(indices);
    end
    cbv = addNoise(cleanCbv, outputNoise, condition.outputSnrDb);
    mapContribution = realization.mapContribution(indices);
    co2Contribution = realization.co2Contribution(indices);
    shift = condition.alignmentErrorSeconds ...
        + analysis.preprocessing.co2DelayCorrectionSeconds;
    [map, co2, cbv] = alignCo2ByDelay(map, co2, cbv, fs, shift);
    [cleanMap, cleanCo2, cleanCbv] = ...
        alignCo2ByDelay(cleanMap, cleanCo2, cleanCbv, fs, shift);
    [~, ~, mapContribution] = alignCo2ByDelay( ...
        realization.map(indices), realization.co2(indices), mapContribution, fs, shift);
    [~, ~, co2Contribution] = alignCo2ByDelay( ...
        realization.map(indices), realization.co2(indices), co2Contribution, fs, shift);

    outputScale = 1;
    units = "simulation units";
    if analysis.preprocessing.normalizeCbv
        outputScale = 100/simulation.cbvNormalizationReference;
        units = "% simulation reference";
    end
    recording.map = map(:);
    recording.co2 = co2(:);
    recording.cbv = cbv(:)*outputScale;
    recording.fs = fs;
    recording.t = (0:numel(map) - 1)'/fs;
    recording.cbvUnits = units;
    recording.inputUnits = "simulation units";
    recording.cleanMap = cleanMap(:);
    recording.cleanCo2 = cleanCo2(:);
    recording.cleanCbv = cleanCbv(:)*outputScale;
    recording.mapContribution = mapContribution(:)*outputScale;
    recording.co2Contribution = co2Contribution(:)*outputScale;
    recording.truth = realization.truth;
    recording.truth.mapImpulseResponse = realization.truth.mapImpulseResponse*outputScale;
    recording.truth.co2ImpulseResponse = realization.truth.co2ImpulseResponse*outputScale;
end

function observed = addNoise(clean, noise, snrDb)
    if isinf(snrDb)
        observed = clean;
        return
    end
    noise = noise(:) - mean(noise);
    noise = noise/sqrt(mean(noise.^2));
    desiredNoisePower = mean(clean.^2)/10^(snrDb/10);
    observed = clean(:) + sqrt(desiredNoisePower)*noise;
end
