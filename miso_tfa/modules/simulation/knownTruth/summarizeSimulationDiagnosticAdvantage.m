function summary = summarizeSimulationDiagnosticAdvantage( ...
    diagnosticValues, sisoErrors, misoErrors, diagnosticName, ...
    binEdges, diagnosticLabel, bootstrapSettings)
% summarizeSimulationDiagnosticAdvantage Compare errors within diagnostic bins.
%
% Diagnostic values vary with frequency, so each frequency is grouped using
% its own diagnostic values. The paired SISO/MISO observations remain the
% same within each cell.

    if nargin < 7 || isempty(diagnosticLabel)
        diagnosticLabel = diagnosticName;
    end
    if nargin < 7 || isempty(bootstrapSettings)
        bootstrapSettings.enabled = false;
    end

    if ~isequal(size(diagnosticValues), size(sisoErrors)) || ...
            ~isequal(size(sisoErrors), size(misoErrors))
        error( ...
            "TFA:DiagnosticAdvantageSizeMismatch", ...
            "Diagnostic and error matrices must have the same size.");
    end
    binEdges = unique(double(binEdges(:)'), "sorted");
    if numel(binEdges) < 2 || any(~isfinite(binEdges))
        error( ...
            "TFA:InvalidDiagnosticBinEdges", ...
            "Diagnostic bin edges must be finite and increasing.");
    end

    numGroups = numel(binEdges) - 1;
    numFrequencies = size(sisoErrors, 1);
    centers = (binEdges(1:end-1) + binEdges(2:end))/2;
    labels = strings(numGroups, 1);
    for groupNumber = 1:numGroups
        labels(groupNumber) = compose( ...
            "%.3g-%.3g", binEdges(groupNumber), ...
            binEdges(groupNumber + 1));
    end
    sisoMean = NaN(numGroups, numFrequencies);
    misoMean = NaN(numGroups, numFrequencies);
    advantage = NaN(numGroups, numFrequencies);
    sisoSD = NaN(numGroups, numFrequencies);
    misoSD = NaN(numGroups, numFrequencies);
    validN = zeros(numGroups, numFrequencies);
    sisoValidN = zeros(numGroups, numFrequencies);
    misoValidN = zeros(numGroups, numFrequencies);
    groupN = zeros(numGroups, numFrequencies);
    bootstrapSD = NaN(numGroups, numFrequencies);
    ciLower = NaN(numGroups, numFrequencies);
    ciUpper = NaN(numGroups, numFrequencies);

    for frequencyIndex = 1:numFrequencies
        currentDiagnostic = diagnosticValues(frequencyIndex, :);
        currentSiso = sisoErrors(frequencyIndex, :);
        currentMiso = misoErrors(frequencyIndex, :);
        for groupNumber = 1:numGroups
            if groupNumber == numGroups
                inBin = currentDiagnostic >= binEdges(groupNumber) & ...
                    currentDiagnostic <= binEdges(groupNumber + 1);
            else
                inBin = currentDiagnostic >= binEdges(groupNumber) & ...
                    currentDiagnostic < binEdges(groupNumber + 1);
            end
            groupN(groupNumber, frequencyIndex) = nnz(inBin);
            sisoValidN(groupNumber, frequencyIndex) = ...
                nnz(inBin & isfinite(currentSiso));
            misoValidN(groupNumber, frequencyIndex) = ...
                nnz(inBin & isfinite(currentMiso));
            paired = inBin & isfinite(currentSiso) & isfinite(currentMiso);
            pairedSiso = currentSiso(paired);
            pairedMiso = currentMiso(paired);
            validN(groupNumber, frequencyIndex) = numel(pairedSiso);
            if isempty(pairedSiso)
                continue
            end

            sisoMean(groupNumber, frequencyIndex) = mean(pairedSiso);
            misoMean(groupNumber, frequencyIndex) = mean(pairedMiso);
            sisoSD(groupNumber, frequencyIndex) = std(pairedSiso, 0);
            misoSD(groupNumber, frequencyIndex) = std(pairedMiso, 0);
            advantage(groupNumber, frequencyIndex) = ...
                calculateMeanErrorRatio( ...
                    sisoMean(groupNumber, frequencyIndex), ...
                    misoMean(groupNumber, frequencyIndex));

            if isfield(bootstrapSettings, "enabled") && ...
                    bootstrapSettings.enabled
                bootstrapSettings.randomSeed = ...
                    bootstrapSettings.randomSeed + ...
                    1000*frequencyIndex + groupNumber;
                [bootstrapSD(groupNumber, frequencyIndex), ...
                    ciLower(groupNumber, frequencyIndex), ...
                    ciUpper(groupNumber, frequencyIndex)] = ...
                    calculateBootstrapInterval( ...
                        pairedSiso, pairedMiso, bootstrapSettings);
            end
        end
    end

    summary.diagnosticName = string(diagnosticName);
    summary.diagnosticLabel = string(diagnosticLabel);
    summary.factorCenters = centers;
    summary.factorLabels = labels;
    summary.factorLower = binEdges(1:end-1)';
    summary.factorUpper = binEdges(2:end)';
    summary.groupN = groupN;
    summary.sisoMean = sisoMean;
    summary.misoMean = misoMean;
    summary.advantage = advantage;
    summary.sisoSD = sisoSD;
    summary.misoSD = misoSD;
    summary.validN = validN;
    summary.sisoValidN = sisoValidN;
    summary.misoValidN = misoValidN;
    summary.bootstrapSD = bootstrapSD;
    summary.ciLower = ciLower;
    summary.ciUpper = ciUpper;
    summary.scoreVersion = "frequency-ratio-of-mean-errors-v1";

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
    finiteValues = bootstrapAdvantage(isfinite(bootstrapAdvantage));
    if isempty(finiteValues)
        bootstrapSD = NaN;
        ciLower = NaN;
        ciUpper = NaN;
        return
    end

    bootstrapSD = std(finiteValues, 0);
    lowerPercentile = 100*(1 - settings.confidenceLevel)/2;
    upperPercentile = 100 - lowerPercentile;
    ciLower = prctile(finiteValues, lowerPercentile);
    ciUpper = prctile(finiteValues, upperPercentile);
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
