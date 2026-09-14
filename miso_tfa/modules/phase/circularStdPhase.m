function stdPhase = circularStdPhase(phaseValues)
% circularStdPhase Compute sqrt(-2*log(R)) circular SD in radians.

    phaseValues = phaseValues(:);
    phaseValues = phaseValues(isfinite(phaseValues));

    if numel(phaseValues) < 2
        stdPhase = NaN;
        return
    end

    resultantLength = abs(mean(exp(1i*phaseValues)));
    resultantLength = min(resultantLength, 1);
    stdPhase = sqrt(-2*log(resultantLength));

end
