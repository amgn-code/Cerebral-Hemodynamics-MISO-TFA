function meanPhase = circularMeanPhase(phaseValues)
% circularMeanPhase Compute the mean direction of phase values in radians.

    phaseValues = phaseValues(:);
    phaseValues = phaseValues(isfinite(phaseValues));

    if isempty(phaseValues)
        meanPhase = NaN;
        return
    end

    meanVector = mean(exp(1i*phaseValues));
    meanPhase = angle(meanVector);

end
