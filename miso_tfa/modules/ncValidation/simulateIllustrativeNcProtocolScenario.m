function result = simulateIllustrativeNcProtocolScenario( ...
    numSubjects, bootstrapSamples)
% simulateIllustrativeNcProtocolScenario Run one stated NC-protocol scenario.
%
% Each simulated subject uses the frozen NC operating point, three
% consecutive 90-second blocks, two training spectra, and one held-out
% spectrum per fold. This is an illustrative mechanism scenario. Its 10 dB
% output disturbance and fixed pathways were not estimated from NC data.

    if nargin < 1 || isempty(numSubjects)
        numSubjects = 23;
    end
    if nargin < 2 || isempty(bootstrapSamples)
        bootstrapSamples = 2000;
    end
    validateattributes(numSubjects, {'numeric'}, ...
        {'scalar', 'integer', '>=', 3});
    validateattributes(bootstrapSamples, {'numeric'}, ...
        {'scalar', 'integer', '>=', 2});

    simulationSettings = defaultKnownTruthSimulationSettings("simple");
    ncSettings = defaultNcBootstrapSettings();
    ncSettings.bootstrap.numSamples = bootstrapSamples;
    simulationSettings.welch = ncSettings.analysis.pwelch;
    blockSeconds = ncSettings.validation.blockLengthSeconds;
    totalSeconds = blockSeconds*ncSettings.validation.numFolds;
    scenario = createNcScenario();
    plan = createObservationPlan(totalSeconds, ...
        simulationSettings.observations.referenceOutputSnrDb);

    blockSamples = round(blockSeconds*simulationSettings.samplingFrequencyHz);
    fullFrequencyHz = (0:floor(blockSamples/2))'* ...
        simulationSettings.samplingFrequencyHz/blockSamples;
    frequencyMask = fullFrequencyHz >= ncSettings.analysis.frequencyRangeHz(1) & ...
        fullFrequencyHz <= ncSettings.analysis.frequencyRangeHz(2);
    frequencyHz = fullFrequencyHz(frequencyMask);
    subjectSisoError = NaN(numSubjects, numel(frequencyHz));
    subjectMisoError = NaN(numSubjects, numel(frequencyHz));
    for subjectIndex = 1:numSubjects
        realization = generateKnownTruthRealization( ...
            scenario, simulationSettings, 12000 + subjectIndex, ...
            totalSeconds);
        observation = createKnownTruthObservation(realization, plan);
        [currentFrequency, sisoError, misoError] = ...
            validateThreeBlocks(observation, ncSettings);
        if ~isequal(currentFrequency(:), frequencyHz)
            error("TFA:NCSimulationFrequencyGridMismatch", ...
                "The simulated NC frequency grid changed between subjects.");
        end
        subjectSisoError(subjectIndex, :) = sisoError(:).';
        subjectMisoError(subjectIndex, :) = misoError(:).';
    end

    summary = summarizeNcBootstrap( ...
        frequencyHz, subjectSisoError, subjectMisoError, ncSettings);
    result.frequencyTable = table( ...
        summary.frequencyHz, summary.advantage, summary.bootstrapSD, ...
        summary.ciLower, summary.ciUpper, summary.validSubjectN, ...
        'VariableNames', {'FrequencyHz', 'IllustrativeAdvantage', ...
        'BootstrapSD', 'CILower', 'CIUpper', 'ValidSubjectN'});
    result.numSubjects = numSubjects;
    result.numTrainingWindows = 2;
    result.numHeldOutWindows = 1;
    result.blockLengthSeconds = blockSeconds;
    result.targetInputCoherence = scenario.targetInputCoherence;
    result.outputSnrDb = plan.OutputSNRdB;
    result.bootstrapSamples = bootstrapSamples;
    result.interpretation = ...
        "Illustrative simulated advantage under stated assumptions; " + ...
        "this is not a prediction calibrated from NC output noise.";
    result.subjectSisoError = subjectSisoError;
    result.subjectMisoError = subjectMisoError;

end

function [frequencyHz, sisoError, misoError] = ...
    validateThreeBlocks(observation, settings)
% validateThreeBlocks Apply the same 2-train/1-test spectral protocol.

    fs = observation.fs;
    blockSamples = round(settings.validation.blockLengthSeconds*fs);
    numFolds = settings.validation.numFolds;
    fullFrequencyHz = (0:floor(blockSamples/2))'*fs/blockSamples;
    frequencyMask = fullFrequencyHz >= settings.analysis.frequencyRangeHz(1) & ...
        fullFrequencyHz <= settings.analysis.frequencyRangeHz(2);
    frequencyHz = fullFrequencyHz(frequencyMask);
    foldSiso = NaN(numel(frequencyHz), numFolds);
    foldMiso = NaN(numel(frequencyHz), numFolds);
    for foldIndex = 1:numFolds
        validationIndices = ((foldIndex - 1)*blockSamples + 1): ...
            (foldIndex*blockSamples);
        trainingBlocks = setdiff(1:numFolds, foldIndex, "stable");
        trainingSpectra = averageTrainingBlocks( ...
            observation, trainingBlocks, blockSamples, settings);
        validationSpectra = estimateWelchSpectra( ...
            observation.map(validationIndices), ...
            observation.co2(validationIndices), ...
            observation.cbv(validationIndices), fs, ...
            settings.analysis.pwelch);
        siso = runSISOTFA(trainingSpectra, settings.analysis.phase);
        miso = runMISOTFA(trainingSpectra, settings.analysis.phase, ...
            settings.analysis.misoSolver);
        [currentFrequency, currentSiso] = ...
            calculateFrequencyValidationPredictionError( ...
                validationSpectra, siso.map.transferFunction, ...
                zeros(size(siso.co2.transferFunction)), ...
                settings.analysis.frequencyRangeHz);
        [~, currentMiso] = calculateFrequencyValidationPredictionError( ...
            validationSpectra, miso.map.transferFunction, ...
            miso.co2.transferFunction, settings.analysis.frequencyRangeHz);
        if ~isequal(currentFrequency(:), frequencyHz)
            error("TFA:NCSimulationFrequencyGridMismatch", ...
                "The simulated NC frequency grid changed between folds.");
        end
        foldSiso(:, foldIndex) = currentSiso;
        foldMiso(:, foldIndex) = currentMiso;
    end
    sisoError = mean(foldSiso, 2, "omitnan");
    misoError = mean(foldMiso, 2, "omitnan");

end

function spectra = averageTrainingBlocks( ...
    observation, blockNumbers, blockSamples, settings)
% averageTrainingBlocks Average disjoint block spectra without joining.

    blockSpectra = cell(numel(blockNumbers), 1);
    for blockIndex = 1:numel(blockNumbers)
        firstSample = (blockNumbers(blockIndex) - 1)*blockSamples + 1;
        indices = firstSample:(firstSample + blockSamples - 1);
        blockSpectra{blockIndex} = estimateWelchSpectra( ...
            observation.map(indices), observation.co2(indices), ...
            observation.cbv(indices), observation.fs, ...
            settings.analysis.pwelch);
    end
    spectra = averageWelchSpectra(blockSpectra);

end

function scenario = createNcScenario()
% createNcScenario Return the frozen central NC simulation condition.

    scenario.targetInputCoherence = 0.15;
    scenario.spectralSimilarityControl = 1;
    scenario.petco2ToMapFluctuationSdRatio = 1;
    scenario.petco2ToMapBandGainRatio = 1;
    scenario.co2DelaySeconds = 3;
    scenario.inputPhaseLagSeconds = 0;
    scenario.mapPathwayTimeConstantSeconds = 3;
    scenario.co2PathwayTimeConstantSeconds = 5;

end

function plan = createObservationPlan(durationSeconds, outputSnrDb)
% createObservationPlan Build one declared signal-shaped observation.

    plan = table(durationSeconds, outputSnrDb, Inf, Inf, 0, ...
        "signalShaped", 'VariableNames', {'DurationSeconds', ...
        'OutputSNRdB', 'MAPInputSNRdB', 'CO2InputSNRdB', ...
        'AlignmentErrorSeconds', 'NoiseSpectrum'});

end
