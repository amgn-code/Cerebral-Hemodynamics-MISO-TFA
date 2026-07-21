function phaseSummary = summarizeGroupPhase( ...
    wrappedValues, unwrappedValues, frequencyHz, ...
    meanCoherence, phaseSettings)
% summarizeGroupPhase Compute circular group phase summaries.
%
% The group mean and SD are calculated from wrapped subject phases using
% circular statistics. The circular group mean is then unwrapped across
% frequency for display. Its uncertainty remains the circular SD.

    numFrequencies = size(wrappedValues, 1);
    wrappedMean = NaN(numFrequencies, 1);
    circularSd = NaN(numFrequencies, 1);

    for frequencyIndex = 1:numFrequencies
        phaseValues = wrappedValues(frequencyIndex, :);
        phaseValues = phaseValues(isfinite(phaseValues));

        if isempty(phaseValues)
            continue
        end

        wrappedMean(frequencyIndex) = circularMeanPhase(phaseValues);

        if numel(phaseValues) >= 2
            circularSd(frequencyIndex) = circularStdPhase(phaseValues);
        end
    end

    unwrappedMean = unwrapTfaPhase( ...
        wrappedMean, frequencyHz, meanCoherence, phaseSettings);

    phaseSummary.wrapped.values = wrappedValues;
    phaseSummary.wrapped.mean = wrappedMean;
    phaseSummary.wrapped.sd = circularSd;
    phaseSummary.unwrapped.values = unwrappedValues;
    phaseSummary.unwrapped.mean = unwrappedMean;
    % Adding phase cycles changes display branches, not circular spread.
    phaseSummary.unwrapped.sd = circularSd;

end
