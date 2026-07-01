function meanPhase = circularMeanPhase(phaseValues)
% circularMeanPhase
%
% Computes circular mean of phase values in radians.
%
% Uses the Circular Statistics Toolbox circ_mean function when available.
% Falls back to the standard complex-vector circular mean otherwise.

    phaseValues = phaseValues(:);
    phaseValues = phaseValues(~isnan(phaseValues));

    if isempty(phaseValues)
        meanPhase = NaN;
        return
    end

    if exist('circ_mean', 'file') == 2
        meanPhase = circ_mean(phaseValues);
    else
        meanPhase = angle(mean(exp(1i * phaseValues)));
    end

end
