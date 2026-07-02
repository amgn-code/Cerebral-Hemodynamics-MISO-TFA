function stdPhase = circularStdPhase(phaseValues)
% circularStdPhase
%
% Computes circular standard deviation of phase values in radians.

    phaseValues = phaseValues(:);
    phaseValues = phaseValues(~isnan(phaseValues));

    if numel(phaseValues) < 2
        stdPhase = NaN;
        return
    end

    if exist('circ_std', 'file') == 2
        stdPhase = circ_std(phaseValues);
    else
        resultantLength = abs(mean(exp(1i * phaseValues)));
        stdPhase = sqrt(-2 * log(resultantLength));
    end

end
