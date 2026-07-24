function simulation = createKnownTruthMisoSignal( ...
    settings, condition, randomSeed)
% createKnownTruthMisoSignal Generate correlated inputs and known pathways.
%
% The input correlation, CO2 power, pathway size, output noise, and delay
% are controlled separately. This separation is useful because each one
% affects identifiability in a different way.

    validateattributes( ...
        randomSeed, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'integer', 'nonnegative'}, ...
        mfilename, 'randomSeed');

    previousRandomState = rng;
    restoreRandomState = onCleanup(@() rng(previousRandomState));
    rng(randomSeed, "twister");

    fs = settings.samplingFrequencyHz;
    numOutputSamples = round(condition.durationSeconds*fs);
    numBurnInSamples = round(settings.burnInSeconds*fs);
    numSamples = numOutputSamples + numBurnInSamples;

    correlation = condition.inputCorrelation;
    if abs(correlation) >= 1
        error( ...
            "TFA:InvalidSimulationCorrelation", ...
            "The absolute input correlation must be less than one.");
    end

    firstInnovation = randn(numSamples, 1);
    independentInnovation = randn(numSamples, 1);
    secondInnovation = correlation*firstInnovation + ...
        sqrt(1 - correlation^2)*independentInnovation;

    arCoefficient = exp( ...
        -1/(fs*settings.inputTimeConstantSeconds));
    map = filter(1, [1 -arCoefficient], firstInnovation);
    co2 = filter(1, [1 -arCoefficient], secondInnovation);

    map = standardizeSignal(map)*settings.mapInputSd;
    co2 = standardizeSignal(co2)*condition.co2InputSd;

    mapKernel = createExponentialKernel( ...
        settings.mapPathwayGain, ...
        settings.mapPathwayTimeConstantSeconds, ...
        0, settings);
    co2Kernel = createExponentialKernel( ...
        settings.co2PathwayGain*condition.co2PathwayScale, ...
        settings.co2PathwayTimeConstantSeconds, ...
        condition.co2DelaySeconds, settings);

    mapContribution = filter(mapKernel, 1, map);
    co2Contribution = filter(co2Kernel, 1, co2);
    modeledOutput = mapContribution + co2Contribution;

    if condition.misspecificationStrength > 0
        interaction = standardizeSignal(map.*co2);
        modeledOutput = modeledOutput + ...
            condition.misspecificationStrength*std(modeledOutput)* ...
            interaction;
    end

    signalPower = mean(modeledOutput.^2);
    noisePower = signalPower / (10^(condition.outputSnrDb/10));
    cbv = modeledOutput + sqrt(noisePower)*randn(numSamples, 1);

    keptSamples = (numBurnInSamples + 1):numSamples;
    simulation.map = map(keptSamples);
    simulation.co2 = co2(keptSamples);
    simulation.cbv = cbv(keptSamples);
    simulation.modeledCbv = modeledOutput(keptSamples);
    simulation.fs = fs;
    simulation.truth.mapImpulseResponse = mapKernel(:);
    simulation.truth.co2ImpulseResponse = co2Kernel(:);
    simulation.condition = condition;
    simulation.randomSeed = randomSeed;

    clear restoreRandomState

end

function standardized = standardizeSignal(signal)
% standardizeSignal Give a generated signal zero mean and unit SD.

    standardized = signal - mean(signal);
    signalSd = std(standardized);
    if signalSd <= 0 || ~isfinite(signalSd)
        error( ...
            "TFA:InvalidGeneratedSignal", ...
            "A generated simulation signal had zero or invalid variance.");
    end
    standardized = standardized/signalSd;

end

function kernel = createExponentialKernel( ...
    pathwayGain, timeConstantSeconds, delaySeconds, settings)
% createExponentialKernel Create a causal FIR pathway with known response.

    fs = settings.samplingFrequencyHz;
    numKernelSamples = max(2, round( ...
        settings.filterDurationTimeConstants*timeConstantSeconds*fs));
    timeSeconds = (0:(numKernelSamples - 1))'/fs;
    kernel = exp(-timeSeconds/timeConstantSeconds);
    kernel = pathwayGain*kernel/sum(kernel);

    numDelaySamples = round(delaySeconds*fs);
    kernel = [zeros(numDelaySamples, 1); kernel];

end
