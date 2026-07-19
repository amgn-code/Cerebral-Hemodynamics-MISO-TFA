function phaseSummary = summarizeGroupPhase( ...
    wrappedValues, unwrappedValues, f, coherenceMean, phaseSettings)
% summarizeGroupPhase Compute circular group phase summaries.

    numFrequencies = size(wrappedValues, 1);
    wrappedMean = NaN(numFrequencies, 1);
    circularSd = NaN(numFrequencies, 1);

    for frequencyIndex = 1:numFrequencies
        phaseValues = wrappedValues(frequencyIndex,:);
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
        wrappedMean, f, coherenceMean, phaseSettings);

    phaseSummary.wrapped.values = wrappedValues;
    phaseSummary.wrapped.mean = wrappedMean;
    phaseSummary.wrapped.sd = circularSd;
    phaseSummary.unwrapped.values = unwrappedValues;
    phaseSummary.unwrapped.mean = unwrappedMean;
    phaseSummary.unwrapped.sd = circularSd;

end
