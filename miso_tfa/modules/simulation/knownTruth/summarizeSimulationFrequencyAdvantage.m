function summary = summarizeSimulationFrequencyAdvantage( ...
    factorValues, sisoErrors, misoErrors, factorName, ...
    groupingMode, groupingSettings, bootstrapSettings)
% summarizeSimulationFrequencyAdvantage Compare mean errors by frequency.
%
% The returned advantage is log10(mean SISO error / mean MISO error).
% SISO and MISO means use the same finite paired observations at each
% frequency. This is the primary frequency-resolved score for the simple
% simulation; it is intentionally separate from the historical mean of
% per-observation log advantages.

    if nargin < 5 || isempty(groupingMode)
        groupingMode = "exact";
    end
    if nargin < 6 || isempty(groupingSettings)
        groupingSettings = struct();
    end
    if nargin < 7 || isempty(bootstrapSettings)
        bootstrapSettings.enabled = false;
    end

    factorValues = factorValues(:);
    if size(sisoErrors, 2) ~= numel(factorValues) || ...
            size(misoErrors, 2) ~= numel(factorValues)
        error( ...
            "TFA:FrequencyAdvantageSizeMismatch", ...
            "The error matrices must have one column per factor value.");
    end
    if ~isequal(size(sisoErrors), size(misoErrors))
        error( ...
            "TFA:FrequencyAdvantageSizeMismatch", ...
            "SISO and MISO error matrices must have the same size.");
    end

    groups = createSimulationFactorGroups( ...
        factorValues, factorName, groupingMode, groupingSettings);
    numGroups = numel(groups.centers);
    numFrequencies = size(sisoErrors, 1);

    sisoMean = NaN(numGroups, numFrequencies);
    misoMean = NaN(numGroups, numFrequencies);
    advantage = NaN(numGroups, numFrequencies);
    sisoStandardDeviation = NaN(numGroups, numFrequencies);
    misoStandardDeviation = NaN(numGroups, numFrequencies);
    validN = zeros(numGroups, numFrequencies);
    sisoValidN = zeros(numGroups, numFrequencies);
    misoValidN = zeros(numGroups, numFrequencies);
    bootstrapStandardDeviation = NaN(numGroups, numFrequencies);
    ciLower = NaN(numGroups, numFrequencies);
    ciUpper = NaN(numGroups, numFrequencies);

    for groupNumber = 1:numGroups
        groupColumns = groups.index == groupNumber;
        for frequencyIndex = 1:numFrequencies
            currentSiso = sisoErrors(frequencyIndex, groupColumns);
            currentMiso = misoErrors(frequencyIndex, groupColumns);
            paired = isfinite(currentSiso) & isfinite(currentMiso);
            currentSiso = currentSiso(paired);
            currentMiso = currentMiso(paired);

            sisoValidN(groupNumber, frequencyIndex) = ...
                nnz(isfinite(sisoErrors(frequencyIndex, groupColumns)));
            misoValidN(groupNumber, frequencyIndex) = ...
                nnz(isfinite(misoErrors(frequencyIndex, groupColumns)));
            validN(groupNumber, frequencyIndex) = numel(currentSiso);

            if isempty(currentSiso)
                continue
            end

            sisoMean(groupNumber, frequencyIndex) = mean(currentSiso);
            misoMean(groupNumber, frequencyIndex) = mean(currentMiso);
            sisoStandardDeviation(groupNumber, frequencyIndex) = ...
                std(currentSiso, 0);
            misoStandardDeviation(groupNumber, frequencyIndex) = ...
                std(currentMiso, 0);
            advantage(groupNumber, frequencyIndex) = ...
                calculateMeanErrorRatio(sisoMean(groupNumber, frequencyIndex), ...
                misoMean(groupNumber, frequencyIndex));

            if isfield(bootstrapSettings, "enabled") && ...
                    bootstrapSettings.enabled
                [bootstrapStandardDeviation(groupNumber, frequencyIndex), ...
                    ciLower(groupNumber, frequencyIndex), ...
                    ciUpper(groupNumber, frequencyIndex)] = ...
                    calculateBootstrapInterval( ...
                        currentSiso, currentMiso, bootstrapSettings);
            end
        end
    end

    summary.factorCenters = groups.centers;
    summary.factorLabels = groups.labels;
    summary.factorLower = groups.lowerEdges;
    summary.factorUpper = groups.upperEdges;
    summary.groupN = groups.totalN;
    summary.sisoMean = sisoMean;
    summary.misoMean = misoMean;
    summary.advantage = advantage;
    summary.sisoSD = sisoStandardDeviation;
    summary.misoSD = misoStandardDeviation;
    summary.validN = validN;
    summary.sisoValidN = sisoValidN;
    summary.misoValidN = misoValidN;
    summary.scoreVersion = "frequency-ratio-of-mean-errors-v1";
    summary.bootstrapSD = bootstrapStandardDeviation;
    summary.ciLower = ciLower;
    summary.ciUpper = ciUpper;
    if isfield(bootstrapSettings, "enabled") && bootstrapSettings.enabled
        summary.bootstrapSamples = bootstrapSettings.numSamples;
        summary.bootstrapSeed = bootstrapSettings.randomSeed;
        summary.confidenceLevel = bootstrapSettings.confidenceLevel;
    end

end

function [bootstrapSD, ciLower, ciUpper] = ...
    calculateBootstrapInterval(sisoErrors, misoErrors, settings)
% calculateBootstrapInterval Estimate uncertainty from paired records.

    numPairs = numel(sisoErrors);
    if numPairs < 2
        bootstrapSD = NaN;
        ciLower = NaN;
        ciUpper = NaN;
        return
    end

    previousRandomState = rng;
    restoreRandomState = onCleanup(@() rng(previousRandomState));
    rng(settings.randomSeed, "twister");

    bootstrapIndices = randi( ...
        numPairs, numPairs, settings.numSamples);
    bootstrapSiso = mean(sisoErrors(bootstrapIndices), 1);
    bootstrapMiso = mean(misoErrors(bootstrapIndices), 1);
    bootstrapAdvantage = NaN(1, settings.numSamples);
    for sampleIndex = 1:settings.numSamples
        bootstrapAdvantage(sampleIndex) = calculateMeanErrorRatio( ...
            bootstrapSiso(sampleIndex), bootstrapMiso(sampleIndex));
    end

    finiteBootstrapAdvantage = bootstrapAdvantage(isfinite(bootstrapAdvantage));
    if isempty(finiteBootstrapAdvantage)
        bootstrapSD = NaN;
        ciLower = NaN;
        ciUpper = NaN;
        return
    end

    bootstrapSD = std(finiteBootstrapAdvantage, 0);
    lowerPercentile = 100*(1 - settings.confidenceLevel)/2;
    upperPercentile = 100 - lowerPercentile;
    ciLower = prctile(finiteBootstrapAdvantage, lowerPercentile);
    ciUpper = prctile(finiteBootstrapAdvantage, upperPercentile);

    clear restoreRandomState

end

function advantage = calculateMeanErrorRatio(sisoMean, misoMean)
% calculateMeanErrorRatio Return a signed log ratio, preserving zero cases.

    if sisoMean == 0 && misoMean == 0
        advantage = 0;
    elseif misoMean == 0
        advantage = Inf;
    elseif sisoMean == 0
        advantage = -Inf;
    else
        advantage = log10(sisoMean/misoMean);
    end

end
