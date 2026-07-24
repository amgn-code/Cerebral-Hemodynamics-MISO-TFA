function metrics = calculateKnownTruthMetrics( ...
    frequencyHz, estimatedTransferFunction, trueTransferFunction, ...
    frequencyRangeHz, extremeCoefficientThreshold)
% calculateKnownTruthMetrics Compare one estimated pathway with truth.

    frequencyMask = frequencyHz >= frequencyRangeHz(1) & ...
        frequencyHz <= frequencyRangeHz(2);

    estimate = estimatedTransferFunction(frequencyMask);
    truth = trueTransferFunction(frequencyMask);
    completeMask = isfinite(estimate) & isfinite(truth);

    metrics.failureRate = 1 - mean(completeMask);
    metrics.extremeCoefficientRate = mean( ...
        abs(estimate) > extremeCoefficientThreshold, "omitnan");

    estimate = estimate(completeMask);
    truth = truth(completeMask);
    if isempty(estimate)
        metrics.gainBias = NaN;
        metrics.meanAbsoluteGainError = NaN;
        metrics.meanAbsolutePhaseErrorRadians = NaN;
        metrics.integratedComplexError = NaN;
        metrics.normalizedComplexError = NaN;
        return
    end

    metrics.gainBias = mean(abs(estimate) - abs(truth));
    metrics.meanAbsoluteGainError = ...
        mean(abs(abs(estimate) - abs(truth)));
    phaseError = angle(exp(1i*(angle(estimate) - angle(truth))));
    metrics.meanAbsolutePhaseErrorRadians = mean(abs(phaseError));
    metrics.integratedComplexError = mean(abs(estimate - truth).^2);

    truthEnergy = mean(abs(truth).^2);
    if truthEnergy > 0
        metrics.normalizedComplexError = ...
            metrics.integratedComplexError/truthEnergy;
    else
        metrics.normalizedComplexError = NaN;
    end

end
