function observation = createKnownTruthObservation( ...
    realization, planRow)
% createKnownTruthObservation Apply duration, noise, and alignment.

    fs = realization.fs;
    numSamples = round(planRow.DurationSeconds*fs);
    if numSamples > numel(realization.map)
        error( ...
            "TFA:SimulationDurationExceedsFamily", ...
            "An observation duration exceeds its baseline family.");
    end

    keptSamples = 1:numSamples;
    cleanMap = realization.map(keptSamples);
    cleanCo2 = realization.co2(keptSamples);
    map = cleanMap;
    co2 = cleanCo2;
    cleanCbv = realization.cleanCbv(keptSamples);
    mapContribution = realization.mapContribution(keptSamples);
    co2Contribution = realization.co2Contribution(keptSamples);

    map = addMeasurementNoise( ...
        map, realization.mapMeasurementNoise(keptSamples), ...
        planRow.MAPInputSNRdB);
    co2 = addMeasurementNoise( ...
        co2, realization.co2MeasurementNoise(keptSamples), ...
        planRow.CO2InputSNRdB);
    cbv = addMeasurementNoise( ...
        cleanCbv, realization.outputNoise(keptSamples), ...
        planRow.OutputSNRdB);

    if planRow.AlignmentErrorSeconds ~= 0
        originalMap = map;
        originalCo2 = co2;
        [map, co2, cbv] = alignCo2ByDelay( ...
            originalMap, originalCo2, cbv, fs, ...
            planRow.AlignmentErrorSeconds);
        [cleanMap, cleanCo2, cleanCbv] = alignCo2ByDelay( ...
            originalMap, originalCo2, cleanCbv, fs, ...
            planRow.AlignmentErrorSeconds);
        [~, ~, mapContribution] = alignCo2ByDelay( ...
            originalMap, originalCo2, mapContribution, fs, ...
            planRow.AlignmentErrorSeconds);
        [~, ~, co2Contribution] = alignCo2ByDelay( ...
            originalMap, originalCo2, co2Contribution, fs, ...
            planRow.AlignmentErrorSeconds);
    else
        cleanMap = cleanMap(:);
        cleanCo2 = cleanCo2(:);
    end

    observation.map = map(:);
    observation.co2 = co2(:);
    observation.cbv = cbv(:);
    observation.cleanMap = cleanMap(:);
    observation.cleanCo2 = cleanCo2(:);
    observation.cleanCbv = cleanCbv(:);
    observation.mapMeasurementNoise = observation.map - observation.cleanMap;
    observation.co2MeasurementNoise = observation.co2 - observation.cleanCo2;
    observation.outputNoise = observation.cbv - observation.cleanCbv;
    observation.mapContribution = mapContribution(:);
    observation.co2Contribution = co2Contribution(:);
    observation.fs = fs;
    observation.truth = realization.truth;
    observation.plan = planRow;

end

function noisySignal = addMeasurementNoise( ...
    cleanSignal, unitNoise, snrDb)
% addMeasurementNoise Add a fixed noise direction at a selected SNR.

    cleanSignal = cleanSignal(:);
    unitNoise = unitNoise(:);
    if isinf(snrDb)
        noisySignal = cleanSignal;
        return
    end

    unitNoise = unitNoise - mean(unitNoise, "omitnan");
    noisePower = mean(unitNoise.^2, "omitnan");
    if noisePower <= 0 || ~isfinite(noisePower)
        error( ...
            "TFA:InvalidSimulationNoise", ...
            "The stored simulation noise has invalid power.");
    end
    unitNoise = unitNoise/sqrt(noisePower);

    signalPower = mean(cleanSignal.^2, "omitnan");
    requestedNoisePower = signalPower/(10^(snrDb/10));
    noisySignal = cleanSignal + ...
        sqrt(requestedNoisePower)*unitNoise;

end
