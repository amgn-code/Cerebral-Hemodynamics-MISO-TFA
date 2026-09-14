function summary = summarizeNcBootstrap( ...
    frequencyHz, sisoErrors, misoErrors, settings)
% summarizeNcBootstrap Summarize subject-level NC validation errors.

    if ~isequal(size(sisoErrors), size(misoErrors))
        error( ...
            "TFA:NCErrorSizeMismatch", ...
            "SISO and MISO subject error matrices must have the same size.");
    end

    frequencyHz = frequencyHz(:);
    if size(sisoErrors, 2) ~= numel(frequencyHz)
        error( ...
            "TFA:NCErrorFrequencyMismatch", ...
            "Subject error matrices must have one column per frequency.");
    end

    paired = isfinite(sisoErrors) & isfinite(misoErrors);
    validN = sum(paired, 1);
    sisoMean = NaN(1, numel(frequencyHz));
    misoMean = NaN(1, numel(frequencyHz));
    sisoSD = NaN(1, numel(frequencyHz));
    misoSD = NaN(1, numel(frequencyHz));

    for frequencyIndex = 1:numel(frequencyHz)
        currentSiso = sisoErrors(paired(:, frequencyIndex), ...
            frequencyIndex);
        currentMiso = misoErrors(paired(:, frequencyIndex), ...
            frequencyIndex);
        if isempty(currentSiso)
            continue
        end

        sisoMean(frequencyIndex) = mean(currentSiso);
        misoMean(frequencyIndex) = mean(currentMiso);
        sisoSD(frequencyIndex) = std(currentSiso, 0);
        misoSD(frequencyIndex) = std(currentMiso, 0);
    end

    advantage = calculateErrorAdvantage( ...
        sisoMean, misoMean, settings.errorFloor);
    [bootstrapSD, ciLower, ciUpper] = calculateBootstrapIntervals( ...
        sisoErrors, misoErrors, settings);

    summary.frequencyHz = frequencyHz;
    summary.sisoMean = sisoMean(:);
    summary.misoMean = misoMean(:);
    summary.advantage = advantage(:);
    summary.sisoSD = sisoSD(:);
    summary.misoSD = misoSD(:);
    summary.validSubjectN = validN(:);
    summary.bootstrapSD = bootstrapSD(:);
    summary.ciLower = ciLower(:);
    summary.ciUpper = ciUpper(:);
    summary.scoreVersion = ...
        "frequency-ratio-of-mean-held-out-errors-v1";
    summary.bootstrapSamples = settings.bootstrap.numSamples;
    summary.bootstrapSeed = settings.bootstrap.randomSeed;
    summary.confidenceLevel = settings.bootstrap.confidenceLevel;

end

function [bootstrapSD, ciLower, ciUpper] = ...
    calculateBootstrapIntervals(sisoErrors, misoErrors, settings)
% calculateBootstrapIntervals Bootstrap subjects with replacement.

    numSubjects = size(sisoErrors, 1);
    numFrequencies = size(sisoErrors, 2);
    bootstrapSD = NaN(1, numFrequencies);
    ciLower = NaN(1, numFrequencies);
    ciUpper = NaN(1, numFrequencies);

    if numSubjects < 2 || settings.bootstrap.numSamples < 2
        return
    end

    previousRandomState = rng;
    restoreRandomState = onCleanup(@() rng(previousRandomState));
    rng(settings.bootstrap.randomSeed, "twister");

    bootstrapAdvantage = NaN( ...
        settings.bootstrap.numSamples, numFrequencies);
    lowerPercentile = 100*(1 - settings.bootstrap.confidenceLevel)/2;
    upperPercentile = 100 - lowerPercentile;

    for sampleIndex = 1:settings.bootstrap.numSamples
        bootstrapIndices = randi(numSubjects, numSubjects, 1);
        for frequencyIndex = 1:numFrequencies
            currentSiso = sisoErrors(bootstrapIndices, frequencyIndex);
            currentMiso = misoErrors(bootstrapIndices, frequencyIndex);
            paired = isfinite(currentSiso) & isfinite(currentMiso);
            if any(paired)
                bootstrapAdvantage(sampleIndex, frequencyIndex) = ...
                    calculateErrorAdvantage( ...
                    mean(currentSiso(paired)), ...
                    mean(currentMiso(paired)), ...
                    settings.errorFloor);
            end
        end
    end

    for frequencyIndex = 1:numFrequencies
        finiteValues = bootstrapAdvantage( ...
            isfinite(bootstrapAdvantage(:, frequencyIndex)), ...
            frequencyIndex);
        if isempty(finiteValues)
            continue
        end

        bootstrapSD(frequencyIndex) = std(finiteValues, 0);
        ciLower(frequencyIndex) = ...
            prctile(finiteValues, lowerPercentile);
        ciUpper(frequencyIndex) = ...
            prctile(finiteValues, upperPercentile);
    end

    clear restoreRandomState

end
